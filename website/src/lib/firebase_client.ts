"use client";

import { initializeApp, getApps } from "firebase/app";
import { initializeAppCheck, ReCaptchaV3Provider } from "firebase/app-check";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

// Firebase web config for project: love2learnsign-1914ce
// These values are not secrets, but must be correct.
const firebaseConfig = {
  apiKey: "AIzaSyAWnlmqkd7Q2AecPVcgOGHVNyPXw-WU8JU",
  authDomain: "love2learnsign-1914ce.firebaseapp.com",
  projectId: "love2learnsign-1914ce",
  storageBucket: "love2learnsign-1914ce.firebasestorage.app",
  messagingSenderId: "610518625822",
  appId: "1:610518625822:web:21c38c3c9c7177b764080f",
  measurementId: "G-0LSSSS25GN",
} as const;

export const firebaseApp = getApps().length
  ? getApps()[0]!
  : initializeApp(firebaseConfig);

declare global {
  // Prevent double init in dev / HMR
  var __L2L_APP_CHECK_INITIALIZED__: boolean | undefined;
}

// Firebase App Check (Web) using reCAPTCHA v3.
// IMPORTANT:
// - Firebase Console uses the reCAPTCHA *secret key*
// - Your website code uses the reCAPTCHA *site key* (public)
if (typeof window !== "undefined" && !globalThis.__L2L_APP_CHECK_INITIALIZED__) {
  const siteKey = process.env.NEXT_PUBLIC_RECAPTCHA_SITE_KEY;
  const debugToken = process.env.NEXT_PUBLIC_FIREBASE_APPCHECK_DEBUG_TOKEN;

  if (debugToken && debugToken !== "0" && debugToken.toLowerCase() !== "false") {
    // For local dev only. Can be "true" or a fixed debug token string.
    (self as unknown as { FIREBASE_APPCHECK_DEBUG_TOKEN?: string | boolean }).FIREBASE_APPCHECK_DEBUG_TOKEN =
      debugToken.toLowerCase() === "true" ? true : debugToken;
  }

  if (siteKey) {
    initializeAppCheck(firebaseApp, {
      provider: new ReCaptchaV3Provider(siteKey),
      isTokenAutoRefreshEnabled: true,
    });
    globalThis.__L2L_APP_CHECK_INITIALIZED__ = true;
  } else if (process.env.NODE_ENV !== "production") {
    console.warn("[AppCheck] Missing NEXT_PUBLIC_RECAPTCHA_SITE_KEY; App Check not initialized.");
  }
}

export const auth = getAuth(firebaseApp);

export const db = getFirestore(firebaseApp);


