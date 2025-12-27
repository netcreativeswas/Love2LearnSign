# SendGrid Email Setup Guide

This guide explains how to configure SendGrid for automatic approval emails when an admin assigns roles to users.

## Why SendGrid?

- **Free tier**: 100 emails/day (more than enough for our use case)
- **Easy integration**: Simple REST API
- **Reliable**: Professional email delivery service
- **Secure**: API keys stored in Firebase Functions environment variables

## Step 1: Create SendGrid Account

1. Go to https://sendgrid.com
2. Click "Start for Free"
3. Sign up with your email
4. Verify your email address

## Step 2: Create API Key

1. In SendGrid dashboard, go to **Settings** → **API Keys**
2. Click **Create API Key**
3. Name it: `Firebase Functions`
4. Select **Full Access** (or **Restricted Access** with Mail Send permissions)
5. Click **Create & View**
6. **IMPORTANT**: Copy the API key immediately (you won't be able to see it again!)

## Step 3: Verify Sender Email

1. Go to **Settings** → **Sender Authentication**
2. Click **Verify a Single Sender**
3. Fill in the form:
   - **From Email**: Your email (e.g., `noreply@lovetolearnsign.app`)
   - **From Name**: `Love2Learn Sign`
   - Complete all required fields
4. Check your email and click the verification link

## Step 4: Configure Firebase Functions

### Option A: Using Firebase Console

1. Go to Firebase Console → **Functions** → **Configuration**
2. Add environment variable:
   - **Key**: `SENDGRID_API_KEY`
   - **Value**: Your SendGrid API key (from Step 2)
3. Add environment variable:
   - **Key**: `SENDGRID_FROM_EMAIL`
   - **Value**: Your verified sender email (from Step 3)

### Option B: Using Firebase CLI

```bash
cd functions
firebase functions:config:set sendgrid.api_key="YOUR_SENDGRID_API_KEY"
firebase functions:config:set sendgrid.from_email="noreply@lovetolearnsign.app"
```

## Step 5: Deploy Functions

```bash
cd functions
firebase deploy --only functions:updateUserRoles
```

## Step 6: Test

1. Create a test user account (Sign Up)
2. In Admin Panel, approve the user and assign a role
3. Check the user's email inbox
4. Check Firebase Functions logs for any errors

## Troubleshooting

### Email not received?

1. Check Firebase Functions logs:
   ```bash
   firebase functions:log
   ```

2. Check SendGrid Activity Feed:
   - Go to SendGrid dashboard → **Activity**
   - Look for sent emails or errors

3. Common issues:
   - **API key not set**: Check environment variables
   - **Sender not verified**: Verify sender email in SendGrid
   - **Email in spam**: Check spam folder
   - **Rate limit**: Free tier is 100 emails/day

### Functions not triggering?

1. Check Firestore rules allow updates
2. Verify Cloud Function is deployed:
   ```bash
   firebase functions:list
   ```

## Email Content

The email sent will have:

**Subject**: Your Love2Learn Sign Account Has Been Approved

**Body**:
```
Welcome to Love2Learn Sign!

Your account has been approved and you have been assigned the role of [ROLE].

You may now sign in to access all features.

Thank you for joining us!
```

## Alternative Email Providers

If you prefer a different provider:

- **Mailgun**: Similar setup, 100 emails/day free
- **Brevo (formerly Sendinblue)**: 300 emails/day free
- **AWS SES**: Very cheap, but requires AWS account setup

The Cloud Function code can be easily adapted for any REST API email service.

