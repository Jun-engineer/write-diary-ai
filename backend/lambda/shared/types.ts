// User types
export interface User {
  userId: string;
  email: string;
  plan: 'free' | 'premium';
  createdAt: number;
  updatedAt?: number;
}

// Diary types
export interface Diary {
  diaryId: string;
  userId: string;
  date: string; // YYYY-MM-DD
  originalText: string;
  correctedText?: string;
  corrections?: Correction[];
  inputType: 'manual' | 'scan';
  imageKey?: string; // S3 key for scanned image
  createdAt: number;
  updatedAt?: number;
}

export interface Correction {
  type: 'grammar' | 'spelling' | 'style' | 'vocabulary';
  before: string;
  after: string;
  explanation: string;
}

export type CorrectionMode = 'beginner' | 'intermediate' | 'advanced';

// Review Card types
export interface ReviewCard {
  cardId: string;
  userId: string;
  diaryId: string;
  before: string;
  after: string;
  context: string;
  tags: string[];
  createdAt: number;
}

// Scan Usage types
export interface ScanUsage {
  userId: string;
  date: string; // YYYY-MM-DD
  count: number;
  ttl?: number; // TTL for auto-cleanup
}

// API Request/Response types
export interface CreateDiaryRequest {
  date: string;
  originalText: string;
  inputType: 'manual' | 'scan';
  imageBase64?: string;
}

export interface CreateDiaryResponse {
  diaryId: string;
  status: 'saved';
}

export interface CorrectDiaryRequest {
  mode: CorrectionMode;
}

export interface CorrectDiaryResponse {
  correctedText: string;
  corrections: Correction[];
}

export interface CreateReviewCardsRequest {
  diaryId: string;
  selectedCorrections: number[];
}

export interface CreateReviewCardsResponse {
  created: number;
}

export interface GetScanUsageResponse {
  count: number;
  limit: number;
}

// Plan limits
export const PLAN_LIMITS = {
  free: {
    scanPerDay: 1,
  },
  premium: {
    scanPerDay: 999, // Virtually unlimited
  },
} as const;
