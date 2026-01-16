// User types
export interface User {
  userId: string;
  email: string;
  displayName?: string;
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
  bonusCount: number; // Bonus scans from watching ads
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
  bonusCount: number;
  maxBonus: number;
}

export interface GetCorrectionUsageResponse {
  count: number;
  limit: number;
  bonusCount: number;
  maxBonus: number;
}

// Correction Usage types (same structure as ScanUsage but in separate table)
export interface CorrectionUsage {
  userId: string;
  date: string; // YYYY-MM-DD
  count: number;
  bonusCount?: number;
  ttl?: number;
}

// Plan limits
export const PLAN_LIMITS = {
  free: {
    scanPerDay: 1,
    maxScanBonusPerDay: 2, // Max bonus scans from watching ads
    correctionPerDay: 3,
    maxCorrectionBonusPerDay: 2, // Max bonus corrections from watching ads
  },
  premium: {
    scanPerDay: 999, // Virtually unlimited
    maxScanBonusPerDay: 0, // Premium users don't need bonus
    correctionPerDay: 999,
    maxCorrectionBonusPerDay: 0,
  },
} as const;
