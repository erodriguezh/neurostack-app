> **Prerequisite:** This guide extends the Flutter MVVM + DDD Supabase Integration Supplement 1. Read that first for a data layer implementation. This supplement covers Supabase-specific magic link implementation.

---
## 1. Send Magic Link

```yaml
dependencies:
  supabase_auth_ui: ^0.5.5
```

```dart
SupaMagicAuth(
  redirectUrl: kIsWeb ? null : 'com.example.myapp://auth-callback/',
  onSuccess: (session) => Navigator.pushReplacementNamed(context, '/home'),
  onError: (error) => showSnackBar(error.message),
)
```


`emailRedirectTo`: `null` for web (uses Site URL), custom scheme for mobile.

---

## 2. Listen for Callback

```dart
late final StreamSubscription<AuthState> _authSub;
bool _redirecting = false;

@override
void initState() {
  super.initState();
  _authSub = supabase.auth.onAuthStateChange.listen((data) {
    if (_redirecting) return;
    if (data.session != null) {
      _redirecting = true;
      Navigator.of(context).pushReplacementNamed('/home');
    }
  });
}

@override
void dispose() {
  _authSub.cancel();
  super.dispose();
}
```

---

## 3. Configure Deep Links

### Dashboard

Authentication → URL Configuration → Add: `com.example.myapp://auth-callback/`

Include trailing slash. Must match `emailRedirectTo` exactly.

### iOS (ios/Runner/Info.plist)

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.example.myapp</string>
    </array>
  </dict>
</array>
```

### Android (android/app/src/main/AndroidManifest.xml)

Inside `<activity>`:

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="com.example.myapp" android:host="auth-callback" />
</intent-filter>
```

---

## 4. Handle App Killed State

`onAuthStateChange` doesn't fire if app was killed. Check session on startup.

```dart
home: supabase.auth.currentSession == null ? LoginPage() : HomePage(),
```

Source: GitHub #3789

---

## 5. Same-Device Requirement

PKCE magic links only work on the device that requested them. Opening on another device fails with "invalid or expired."

**Alternative:** Use OTP code. Edit email template in Dashboard:

```html
<p>Your code: {{ .Token }}</p>
```

Verify:

```dart
await supabase.auth.verifyOTP(
  type: OtpType.email,
  token: code,
  email: email,
);
```

Source: GitHub #21583

---

## 6. Rate Limits

|Limit|Value|
|---|---|
|Request rate|1 per 60s per email|
|Expiration|1 hour|
|Usage|One-time|

---

## Troubleshooting

|Issue|Fix|
|---|---|
|"Link is invalid"|Open on same device that requested it|
|Opens browser, not app|Check deep link config (iOS/Android)|
|Works on web, fails on mobile|Add `emailRedirectTo` with custom scheme|
|App opens, no redirect|App was killed; check `currentSession` on startup|
|"No API key found"|Redirect URL in Dashboard missing or mismatched|

---

## Checklist

```
[ ] Redirect URL in Dashboard (trailing slash)
[ ] iOS: CFBundleURLSchemes in Info.plist
[ ] Android: intent-filter in AndroidManifest.xml
[ ] emailRedirectTo matches Dashboard URL exactly
[ ] onAuthStateChange listener in initState()
[ ] Subscription cancelled in dispose()
[ ] currentSession check on app startup
```