// Canonical constants for RevenueCat integration.
//
// These values must match exactly what is configured in:
// - RevenueCat Dashboard (entitlement ID)
// - App Store Connect / Google Play Console (product IDs)

/// Entitlement ID (must match RevenueCat dashboard exactly)
const kNeurostackProEntitlementId = 'Neurostack Pro';

/// Product IDs (must match App Store Connect / Google Play Console)
/// Trial duration configured in RevenueCat dashboard per product (P7D).
/// See fn-81-paywall-apple-compliance.1 for dashboard configuration.
const kProductMonthly = 'neurostack_monthly'; // $7.99/mo, 7-day trial (P7D)
const kProductYearly = 'neurostack_yearly'; // $59.99/yr, 7-day trial (P7D)
