# fn-43-plx.1 Update StartupViewModel to inject RevenueCatService and AppLifecycleService

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Updated StartupViewModel to initialize RevenueCatService before AuthService to prevent race condition where auth rehydration may call identify() before SDK is configured. Made RevenueCatService.identify() fully non-fatal so RC failures don't break auth/startup flows.
## Evidence
- Commits: 200795c, 6ac29b2, c5a39ae431399ef9d70b12a9e98509d2cf39f625
- Tests: flutter test
- PRs: