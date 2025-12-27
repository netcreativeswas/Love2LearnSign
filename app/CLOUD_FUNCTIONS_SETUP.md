# Cloud Functions Setup Guide

This guide explains how to deploy the Cloud Functions for the Love to Learn Sign application.

## Prerequisites

1. **Firebase CLI**: Install Firebase CLI if you haven't already:
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Verify Dependencies** (already installed):
   ```bash
   cd functions
   npm list firebase-admin firebase-functions
   ```
   
   ✅ **Status**: Dependencies are already installed in the `functions/` directory.

## Cloud Functions Overview

The following Cloud Functions are implemented:

### 1. `updateUserRoles`
- **Trigger**: Firestore document update (`/users/{userId}`)
- **Purpose**: Automatically updates Firebase Custom Claims when user roles change
- **Behavior**: 
  - Reads the `roles` array from Firestore
  - Updates Custom Claims with the new roles
  - Logs the change to `roleLogs` collection

### 2. `validateAdminAccess`
- **Type**: Callable function (HTTPS)
- **Purpose**: Validates if a user has admin role
- **Usage**: Can be called from the Flutter app to verify admin access

### 3. `onUserRegistration`
- **Trigger**: Firebase Auth user creation
- **Purpose**: Creates a user document in Firestore with pending status
- **Behavior**:
  - Creates `/users/{uid}` document
  - Sets `roles: []`, `status: 'pending'`, `approved: false`
  - No default role assigned

## Deployment Steps

### Step 1: Navigate to Functions Directory
```bash
cd functions
```

### Step 2: Verify Dependencies (Already Installed)
```bash
npm list firebase-admin firebase-functions
```

✅ **Note**: Dependencies are already installed. If you need to reinstall:
```bash
npm install
```

### Step 3: Deploy Functions
```bash
firebase deploy --only functions
```

Or deploy specific functions:
```bash
firebase deploy --only functions:updateUserRoles
firebase deploy --only functions:validateAdminAccess
firebase deploy --only functions:onUserRegistration
```

### Step 4: Verify Deployment
Check the Firebase Console:
1. Go to Firebase Console > Functions
2. Verify all three functions are deployed and active

## Testing

### Test `updateUserRoles`
1. Update a user's roles in Firestore `/users/{userId}`
2. Check Firebase Console > Authentication > Users > Custom Claims
3. The user's Custom Claims should reflect the new roles

### Test `onUserRegistration`
1. Create a new user account (sign up)
2. Check Firestore `/users/{uid}` - should have:
   - `roles: []`
   - `status: 'pending'`
   - `approved: false`

### Test `validateAdminAccess`
Call from Flutter app:
```dart
final callable = FirebaseFunctions.instance.httpsCallable('validateAdminAccess');
final result = await callable();
print(result.data); // {isAdmin: true/false, roles: [...]}
```

## Important Notes

1. **Custom Claims**: Custom Claims are stored in the JWT token. Users need to refresh their token (`getIdToken(true)`) to get updated claims.

2. **Security**: The Cloud Functions run with admin privileges. They can modify any user's Custom Claims and Firestore documents.

3. **Logging**: Role changes are logged to `/roleLogs` collection for audit purposes.

4. **Error Handling**: Functions include error handling and logging. Check Firebase Console > Functions > Logs for any errors.

## Troubleshooting

### Function not triggering
- Check Firebase Console > Functions > Logs for errors
- Verify the trigger path matches your Firestore structure
- Ensure the function is deployed successfully

### Custom Claims not updating
- Users must call `getIdToken(true)` to refresh their token
- Check Firebase Console > Authentication > Users > Custom Claims
- Verify the function logs show successful execution

### Permission errors
- Ensure Firestore rules allow Cloud Functions to write
- Check that the function has proper IAM permissions

## Local Development

To test functions locally:

```bash
cd cloud_functions
npm run serve
```

This starts the Firebase emulator. You can test functions locally before deploying.

## Next Steps

After deploying Cloud Functions:

1. **Update Firestore Rules**: Copy the updated `firestore.rules` to Firebase Console
2. **Test Authentication Flow**: Create a new user and verify pending status
3. **Test Admin Panel**: Approve a user and verify roles are updated
4. **Monitor Logs**: Check Firebase Console > Functions > Logs regularly

