/// <reference types="vite/client" />

declare global {
  interface Window {
    AGAIN26_CONFIG?: {
      SUPABASE_URL?: string;
      SUPABASE_ANON_KEY?: string;
    };
  }
}

declare module '*.css';

export {};
