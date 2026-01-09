# Home Screen Change Log

This document tracks the Home/Stack screen implementation. Keep it current as the app evolves.

## What changed

### New state and view model
- Added `HomeViewState` plus banner/card models and enums to drive screen state.
- Replaced the placeholder counter MVVM with Home-specific loading, banner, and card logic.
- Added connectivity-aware offline banner handling.
- Added trial-expired, grace, and deactivation modal triggers (logic only).

### New UI and widgets
- Implemented the Home screen layout with AppGridBackground, header, banners, cards, empty state, and bottom nav.
- Added staggered fade/slide-in animation for banner, header, and cards.
- Added protocol cards with spotlight hover effect and status-dot ping animation.
- Added empty-state presentation with "Browse Library" CTA.
- Added session-only dismissible status banner, with tap actions for trial/expired/grace.

### Navigation stubs
- Added placeholder Library and Paywall screens so required navigation does not break.
- Added routes for `/library` and `/paywall`.

## What did not change (intentionally)

### Not implemented yet
- Realtime updates (Supabase subscriptions) for stack/protocol/session changes.
- Deactivation modal selection flow (only a placeholder dialog exists).
- Trial expired flow that deactivates protocols (logic only stubbed).
- Progress tab navigation (still a no-op).
- Paywall UI and subscription purchase flow (placeholder screen).
- Library browsing UI and add-to-stack flow (placeholder screen).
- Localization updates for Home copy (strings are inline per spec).
- Repository batch-fetch for protocol IDs (still N+1 lookups).

### Existing system behavior unchanged
- Auth/session bootstrap and routing behavior.
- Domain invariants and failure types.

## Files added or replaced

### Added
- `app/lib/home/home_state.dart`
- `app/lib/home/widgets/home_status_banner.dart`
- `app/lib/home/widgets/home_header.dart`
- `app/lib/home/widgets/home_status_dot.dart`
- `app/lib/home/widgets/home_protocol_card.dart`
- `app/lib/home/widgets/home_empty_state.dart`
- `app/lib/home/widgets/home_bottom_nav.dart`
- `app/lib/library/library_view.dart`
- `app/lib/library/library_view_model.dart`
- `app/lib/paywall/paywall_view.dart`
- `app/lib/paywall/paywall_view_model.dart`

### Replaced
- `app/lib/home/home_view.dart`
- `app/lib/home/home_view_model.dart`

### Updated
- `app/lib/config/route_config.dart`

## Auto updates and external changes
- `flutter analyze` resolved and downloaded packages. This did not modify tracked source files.
- No dependency versions were updated and no lockfiles were edited by this change set.

## Testing
- `flutter analyze` ran successfully with only pre-existing info-level lints unrelated to this change.
