// =============================================================================
// RevenueCat Webhook Edge Function
// =============================================================================
// The ONLY writer of subscription status to the Supabase DB.
// Receives RevenueCat webhook events and calls apply_revenuecat_event() RPC.
//
// Security:
//   - Authorization header verification (shared secret from RevenueCat dashboard)
//   - UUID validation for all user IDs before DB calls
//   - Service role key for RPC access (SECURITY DEFINER function)
//
// Design:
//   - Returns 200 for all recognized events (RevenueCat retries on non-2xx)
//   - Idempotency handled by the RPC (monotonic timestamp + event ID dedup)
//   - CANCELLATION and UNCANCELLATION = no DB change (user still active)
// =============================================================================

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Product IDs must match App Store Connect / Google Play Console exactly. */
const PRODUCT_MONTHLY = "neurostack_monthly";
const PRODUCT_YEARLY = "neurostack_yearly";

/** Subscription status values (must match chk_subscription_status CHECK). */
type SubscriptionStatus =
  | "free"
  | "trial"
  | "premiumMonthly"
  | "premiumAnnual"
  | "premiumLifetime"
  | "expired"
  | "grace";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function ok(body: Record<string, unknown> = { status: "ok" }): Response {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

function okIgnored(reason: string): Response {
  return ok({ status: "ignored", reason });
}

function unauthorized(reason: string): Response {
  return new Response(JSON.stringify({ error: reason }), {
    status: 401,
    headers: { "Content-Type": "application/json" },
  });
}

function badRequest(reason: string): Response {
  return new Response(JSON.stringify({ error: reason }), {
    status: 400,
    headers: { "Content-Type": "application/json" },
  });
}

function isValidUuid(value: unknown): value is string {
  return typeof value === "string" && UUID_REGEX.test(value);
}

// ---------------------------------------------------------------------------
// Status mapping
// ---------------------------------------------------------------------------

/**
 * Determine subscription status from a product ID and period type.
 *
 * Period type values from RevenueCat:
 *   TRIAL | INTRO | NORMAL | PROMOTIONAL | PREPAID
 */
function determineStatusFromProduct(
  productId: string | null | undefined,
  periodType: string | null | undefined,
): SubscriptionStatus {
  // Trial period always maps to 'trial' regardless of product
  if (periodType === "TRIAL") {
    return "trial";
  }

  // Map product ID to premium tier
  if (productId === PRODUCT_MONTHLY) return "premiumMonthly";
  if (productId === PRODUCT_YEARLY) return "premiumAnnual";

  // Fallback: unknown product but active subscription -> premiumMonthly
  // This is a safe default since we know there IS an active entitlement
  console.warn(
    `Unknown product_id "${productId}" with period_type "${periodType}", defaulting to premiumMonthly`,
  );
  return "premiumMonthly";
}

/**
 * Determine status for EXPIRATION events.
 *
 * When period_type is present:
 *   TRIAL -> 'free' (never converted, show "upgrade" UX)
 *   any other -> 'expired' (lapsed subscriber, show "resubscribe" UX)
 *
 * When period_type is missing (schema drift), falls back to querying the
 * user's current DB status:
 *   was 'trial' -> 'free'
 *   was premium/grace -> 'expired'
 *   was free/null/unknown -> 'free' (never paid or safe default)
 */
async function determineExpiredStatus(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  periodType: string | null | undefined,
): Promise<SubscriptionStatus> {
  if (periodType === "TRIAL") return "free";
  if (periodType) return "expired";

  // Fallback: period_type missing -> check last known DB status
  const { data, error } = await supabase
    .from("users")
    .select("subscription_status")
    .eq("id", userId)
    .maybeSingle();

  if (error) {
    console.error(
      `EXPIRATION fallback lookup failed user=${userId}: ${error.message}`,
    );
    return "expired"; // safe default for unknown
  }

  // Deterministic mapping based on last known status:
  //   trial -> 'free' (never converted)
  //   premium*/grace -> 'expired' (was paying, show "resubscribe" UX)
  //   free/null/unknown -> 'free' (never paid or safe default)
  const last = data?.subscription_status;
  if (last === "trial") return "free";
  const wasPaying = [
    "premiumMonthly",
    "premiumAnnual",
    "premiumLifetime",
    "grace",
  ].includes(last);
  return wasPaying ? "expired" : "free";
}

// ---------------------------------------------------------------------------
// RevenueCat event type definitions (subset we handle)
// ---------------------------------------------------------------------------

interface RevenueCatWebhookPayload {
  api_version: string;
  event: RevenueCatEvent;
}

interface RevenueCatEvent {
  type: string;
  id: string;
  app_user_id: string;
  original_app_user_id?: string;
  aliases?: string[];
  product_id?: string;
  new_product_id?: string;
  period_type?: string;
  event_timestamp_ms: number | string;
  expiration_at_ms?: number;
  environment?: string;
  store?: string;
  // TRANSFER-specific (arrays of app user IDs + aliases)
  transferred_from?: string[];
  transferred_to?: string[];
}

// ---------------------------------------------------------------------------
// Supabase client (lazy singleton)
// ---------------------------------------------------------------------------

function getSupabaseClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!url || !serviceRoleKey) {
    throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  }

  return createClient(url, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

// ---------------------------------------------------------------------------
// RPC wrapper
// ---------------------------------------------------------------------------

async function callApplyEvent(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  eventId: string,
  occurredAt: string,
  status: SubscriptionStatus,
): Promise<void> {
  const { error } = await supabase.rpc("apply_revenuecat_event", {
    p_user_id: userId,
    p_event_id: eventId,
    p_occurred_at: occurredAt,
    p_subscription_status: status,
  });

  if (error) {
    console.error(
      `RPC apply_revenuecat_event failed for user=${userId} event=${eventId}: ${error.message}`,
    );
    throw error;
  }
}

// ---------------------------------------------------------------------------
// TRANSFER handler
// ---------------------------------------------------------------------------

async function handleTransfer(
  supabase: ReturnType<typeof createClient>,
  event: RevenueCatEvent,
  occurredAt: string,
): Promise<Response> {
  // transferred_from and transferred_to are arrays of app user IDs + aliases.
  // We look for the first valid UUID in each array (our app_user_id is always a UUID).
  const fromIds = event.transferred_from ?? [];
  const toIds = event.transferred_to ?? [];

  const fromUuid = fromIds.find((id) => isValidUuid(id)) ?? null;
  const toUuid = toIds.find((id) => isValidUuid(id)) ?? null;

  if (fromIds.length > 0 && !fromUuid) {
    console.warn(
      `TRANSFER: no valid UUID in transferred_from: ${JSON.stringify(fromIds)}`,
    );
  }
  if (toIds.length > 0 && !toUuid) {
    console.warn(
      `TRANSFER: no valid UUID in transferred_to: ${JSON.stringify(toIds)}`,
    );
  }

  // Guard: both invalid/missing -> nothing to do
  if (!fromUuid && !toUuid) {
    return okIgnored("no_valid_transfer_ids");
  }

  // Guard: self-transfer
  if (fromUuid && toUuid && fromUuid === toUuid) {
    return okIgnored("self_transfer");
  }

  // 1. Revoke from old user
  if (fromUuid) {
    // Query current status to determine correct revoke status:
    //   premium*/grace -> 'expired' (was paying, show "resubscribe" UX)
    //   trial/free/unknown -> 'free' (never paid or safe default)
    const { data: fromUser, error: fromError } = await supabase
      .from("users")
      .select("subscription_status")
      .eq("id", fromUuid)
      .maybeSingle();

    if (fromError) {
      console.error(
        `TRANSFER: failed to query from-user=${fromUuid}: ${fromError.message}`,
      );
      // Default to 'free' on lookup failure (safe: doesn't grant unearned "expired" UX)
    }

    const wasPaying = [
      "premiumMonthly",
      "premiumAnnual",
      "premiumLifetime",
      "grace",
    ].includes(fromUser?.subscription_status);
    const revokeStatus: SubscriptionStatus = wasPaying ? "expired" : "free";

    await callApplyEvent(
      supabase,
      fromUuid,
      `${event.id}_from`,
      occurredAt,
      revokeStatus,
    );
  }

  // 2. Grant to new user
  //    TRANSFER events do NOT include product_id/period_type per RevenueCat docs.
  //    We default to premiumMonthly as a safe grant. The next RENEWAL or
  //    INITIAL_PURCHASE event will correct the tier if needed.
  if (toUuid) {
    const grantStatus: SubscriptionStatus = event.product_id
      ? determineStatusFromProduct(event.product_id, event.period_type)
      : "premiumMonthly";

    await callApplyEvent(
      supabase,
      toUuid,
      `${event.id}_to`,
      occurredAt,
      grantStatus,
    );
  }

  return ok();
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request) => {
  // Only accept POST
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // -------------------------------------------------------------------------
  // 1. Authorization verification
  // -------------------------------------------------------------------------
  // NOTE: The plan spec references HMAC signature verification, but RevenueCat
  // does NOT support HMAC body signing. RevenueCat sends a configurable
  // Authorization header (set in the RC dashboard). This is the standard and
  // only supported verification mechanism per RevenueCat docs:
  // https://www.revenuecat.com/docs/integrations/webhooks
  const webhookSecret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
  if (!webhookSecret) {
    console.error("REVENUECAT_WEBHOOK_SECRET not configured");
    return new Response("Server misconfigured", { status: 500 });
  }

  const authHeader = req.headers.get("authorization");
  // Accept either "Bearer <secret>" or raw "<secret>" (common RevenueCat misconfig)
  const expectedBearer = `Bearer ${webhookSecret}`;
  if (!authHeader || (authHeader !== expectedBearer && authHeader !== webhookSecret)) {
    return unauthorized("invalid_authorization");
  }

  // -------------------------------------------------------------------------
  // 2. Parse body
  // -------------------------------------------------------------------------
  let rawBody: string;
  try {
    rawBody = await req.text();
  } catch {
    return badRequest("failed_to_read_body");
  }

  let payload: RevenueCatWebhookPayload;
  try {
    payload = JSON.parse(rawBody);
  } catch {
    return badRequest("invalid_json");
  }

  const event = payload?.event;
  if (!event || !event.type || !event.id) {
    return badRequest("missing_event_fields");
  }

  // Validate and convert event_timestamp_ms to ISO string for the RPC
  const rawTimestamp = event.event_timestamp_ms;
  const eventTimestampMs =
    typeof rawTimestamp === "number"
      ? rawTimestamp
      : typeof rawTimestamp === "string"
        ? Number(rawTimestamp)
        : NaN;
  if (!Number.isFinite(eventTimestampMs)) {
    console.warn(
      `Invalid event_timestamp_ms for event=${event.id} type=${event.type}`,
    );
    return okIgnored("invalid_event_timestamp_ms");
  }
  const occurredDate = new Date(eventTimestampMs);
  if (Number.isNaN(occurredDate.getTime())) {
    console.warn(
      `Out-of-range event_timestamp_ms=${eventTimestampMs} for event=${event.id}`,
    );
    return okIgnored("invalid_event_timestamp_ms");
  }
  const occurredAt = occurredDate.toISOString();

  console.log(
    `Processing ${event.type} event=${event.id} user=${event.app_user_id ?? "N/A"} env=${event.environment ?? "unknown"}`,
  );

  // -------------------------------------------------------------------------
  // 3. Handle TEST events (RevenueCat dashboard sends these)
  // -------------------------------------------------------------------------
  if (event.type === "TEST") {
    console.log("TEST event received, responding OK");
    return ok({ status: "ok", event_type: "TEST" });
  }

  // -------------------------------------------------------------------------
  // 4. TRANSFER events (special: no app_user_id, has transferred_from/to)
  // -------------------------------------------------------------------------
  if (event.type === "TRANSFER") {
    const supabase = getSupabaseClient();
    return handleTransfer(supabase, event, occurredAt);
  }

  // -------------------------------------------------------------------------
  // 5. All other events require valid app_user_id (UUID)
  // -------------------------------------------------------------------------
  if (!isValidUuid(event.app_user_id)) {
    console.warn(
      `Invalid app_user_id format: "${event.app_user_id}" for event ${event.type}`,
    );
    return okIgnored("invalid_user_id");
  }

  const userId = event.app_user_id;
  const supabase = getSupabaseClient();

  // -------------------------------------------------------------------------
  // 6. Route by event type
  // -------------------------------------------------------------------------
  switch (event.type) {
    // -- Events that change subscription status --

    case "INITIAL_PURCHASE": {
      const status = determineStatusFromProduct(
        event.product_id,
        event.period_type,
      );
      await callApplyEvent(supabase, userId, event.id, occurredAt, status);
      return ok();
    }

    case "RENEWAL": {
      // Renewals are always paid (TRIAL -> INITIAL_PURCHASE, not RENEWAL)
      const status = determineStatusFromProduct(
        event.product_id,
        "NORMAL", // Renewals are never trial
      );
      await callApplyEvent(supabase, userId, event.id, occurredAt, status);
      return ok();
    }

    case "BILLING_ISSUE": {
      await callApplyEvent(
        supabase,
        userId,
        event.id,
        occurredAt,
        "grace",
      );
      return ok();
    }

    case "BILLING_ISSUE_RESOLVED": {
      // Recovery from grace -> back to premium tier
      const status = determineStatusFromProduct(
        event.product_id,
        "NORMAL", // Was billing issue, now resolved -> paid tier
      );
      await callApplyEvent(supabase, userId, event.id, occurredAt, status);
      return ok();
    }

    case "EXPIRATION": {
      const status = await determineExpiredStatus(
        supabase,
        userId,
        event.period_type,
      );
      await callApplyEvent(supabase, userId, event.id, occurredAt, status);
      return ok();
    }

    case "PRODUCT_CHANGE": {
      // new_product_id contains the target product after upgrade/downgrade
      const productId = event.new_product_id ?? event.product_id;
      const status = determineStatusFromProduct(productId, event.period_type);
      await callApplyEvent(supabase, userId, event.id, occurredAt, status);
      return ok();
    }

    // -- Events that do NOT change subscription status --

    case "CANCELLATION": {
      // CRITICAL: Cancellation does NOT end the entitlement.
      // User is still premium until EXPIRATION.
      console.log(
        `CANCELLATION for user=${userId}: no status change (active until expiration)`,
      );
      return okIgnored("cancellation_no_change");
    }

    case "UNCANCELLATION": {
      // User re-enabled auto-renew; no DB change needed.
      console.log(`UNCANCELLATION for user=${userId}: no status change`);
      return okIgnored("uncancellation_no_change");
    }

    // -- Events we acknowledge but don't act on --

    case "NON_RENEWING_PURCHASE":
    case "SUBSCRIPTION_PAUSED":
    case "SUBSCRIPTION_EXTENDED":
    case "TEMPORARY_ENTITLEMENT_GRANT":
    case "REFUND_REVERSED":
    case "INVOICE_ISSUANCE":
    case "EXPERIMENT_ENROLLMENT": {
      console.log(`Acknowledged ${event.type} for user=${userId}: no action`);
      return okIgnored("unhandled_event_type");
    }

    default: {
      console.warn(`Unknown event type: ${event.type}`);
      return okIgnored("unknown_event_type");
    }
  }
});
