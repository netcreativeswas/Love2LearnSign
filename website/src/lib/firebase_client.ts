"use client";

import { initializeApp, getApps } from "firebase/app";
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

export const auth = getAuth(firebaseApp);

export const db = getFirestore(firebaseApp);


