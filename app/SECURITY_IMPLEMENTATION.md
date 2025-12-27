# Security Implementation Guide

## ✅ Implemented Security Measures

### 1. ✅ Honeypot Field (Champ Piège)
**Status**: Fully implemented

- **Location**: `lib/signup_page.dart`
- **Implementation**: Hidden field (`_honeypotController`) that is invisible to users but visible to bots
- **Behavior**: If the field is filled, signup is silently rejected (no error shown to avoid revealing the honeypot)
- **Testing**: Bots that auto-fill forms will fill this field and be blocked

### 2. ✅ Rate Limiting
**Status**: Cloud Function created, needs deployment

- **Cloud Function**: `functions/index.js` → `checkRateLimit`
- **Limits**:
  - 3 signups per hour per IP address
  - 1 signup per email address
- **Storage**: Uses Firestore collection `signupAttempts` to track attempts
- **Integration**: `lib/services/security_service.dart` → `checkRateLimit()`
- **Client-side**: `lib/signup_page.dart` calls rate limiting before signup

**⚠️ TODO**: Deploy Cloud Function and create Firestore index for `signupAttempts` collection

### 3. ✅ Email Verification (Obligatoire)
**Status**: Fully implemented

- **Email Sending**: `lib/services/auth_service.dart` → `signUpWithEmailAndPassword()` sends verification email automatically
- **Verification Page**: `lib/email_verification_page.dart` - New page for users to verify their email
- **Flow**:
  1. User signs up → Email verification sent automatically
  2. User redirected to `EmailVerificationPage`
  3. User clicks verification link in email
  4. User clicks "I've Verified My Email" button
  5. If verified → Check approval status → Redirect to `PendingApprovalPage` or `MainInterface`
- **Login Check**: `lib/login_page.dart` checks email verification before allowing access
- **Resend**: Users can resend verification email from `EmailVerificationPage`

**✅ Complete**: No additional configuration needed

### 4. ⚠️ CAPTCHA (Partial Implementation)
**Status**: Cloud Function created, needs reCAPTCHA configuration

- **Cloud Function**: `functions/index.js` → `verifyCaptcha`
- **Mobile Support**: Uses device ID for mobile apps (basic validation)
- **Web Support**: Supports reCAPTCHA v3 tokens (needs configuration)
- **Integration**: `lib/services/security_service.dart` → `verifyCaptcha()`
- **Client-side**: `lib/signup_page.dart` calls CAPTCHA verification before signup

**⚠️ TODO**: 
1. Register your app with Google reCAPTCHA: https://www.google.com/recaptcha/admin
2. Get Site Key and Secret Key
3. Set environment variable in Firebase Functions: `RECAPTCHA_SECRET_KEY`
4. For web version: Integrate reCAPTCHA v3 widget (optional, mobile works without it)

## 📋 Deployment Checklist

### Cloud Functions Deployment
```bash
cd functions
npm install
firebase deploy --only functions:checkRateLimit,functions:verifyCaptcha
```

### Firestore Index Creation
Create a composite index for `signupAttempts` collection:
- Collection: `signupAttempts`
- Fields:
  - `ipAddress` (Ascending)
  - `timestamp` (Ascending)
- Query scope: Collection

### Environment Variables (Firebase Functions)
Set in Firebase Console → Functions → Configuration:
- `RECAPTCHA_SECRET_KEY`: Your reCAPTCHA secret key (if using reCAPTCHA)

### Firestore Rules Update
Add rules for `signupAttempts` collection (if needed):
```javascript
match /signupAttempts/{attemptId} {
  allow write: if request.auth == null; // Allow anonymous writes for rate limiting
  allow read: if false; // No reads needed
}
```

## 🔒 Security Flow

1. **User fills signup form**
   - Honeypot field checked (silent rejection if filled)

2. **Rate limiting check**
   - Checks IP and email limits
   - Records attempt in Firestore

3. **CAPTCHA verification**
   - Mobile: Device ID validation
   - Web: reCAPTCHA token verification (if configured)

4. **Account creation**
   - Firebase Auth creates account
   - Email verification sent automatically

5. **Email verification**
   - User redirected to `EmailVerificationPage`
   - User clicks link in email
   - User confirms verification

6. **Approval process**
   - Admin approves user
   - User can access app

## 🧪 Testing

### Test Honeypot
1. Fill signup form normally → Should work
2. Fill signup form + fill hidden "Website URL" field → Should silently reject

### Test Rate Limiting
1. Try to sign up 4 times from same IP in 1 hour → 4th attempt should be blocked
2. Try to sign up with same email twice → Second attempt should be blocked

### Test Email Verification
1. Sign up with valid email → Should receive verification email
2. Try to login without verifying → Should redirect to `EmailVerificationPage`
3. Click verification link → Should verify email
4. Click "I've Verified My Email" → Should proceed to approval page

### Test CAPTCHA
1. Sign up normally → Should pass (mobile uses device ID)
2. For web: Configure reCAPTCHA and test with token

## 📝 Notes

- **Fail-Open Strategy**: If security checks fail (network errors, etc.), signup is allowed to avoid blocking legitimate users. Errors are logged for monitoring.
- **Mobile CAPTCHA**: Currently uses device ID validation. For production, consider implementing Firebase App Check for better security.
- **Rate Limiting**: Uses Firestore for storage. Consider using Redis for high-traffic scenarios.
- **Email Verification**: Required before users can access the app. This prevents fake email signups.

## 🚀 Next Steps

1. Deploy Cloud Functions (`checkRateLimit`, `verifyCaptcha`)
2. Create Firestore index for `signupAttempts`
3. Configure reCAPTCHA (optional, for web)
4. Test all security measures
5. Monitor Firestore `signupAttempts` collection for suspicious patterns
6. Consider implementing Firebase App Check for mobile apps

