/**
 * Core User Models
 */
export interface User {
  id: string;
  stellarAddress: string; // Ed25519 Public Key
  phone: string;
  name: string;
  profileImage?: string; // IPFS hash
  countryCode: string; // ISO 3166-1 alpha-3 (e.g., 'NGA')
  skills: Skill[];
  repScore: number; // 0 - 1000
  joinedAt: Date;
  isVerified: boolean;
  totalVouchesReceived: number;
  totalVouchesGiven: number;
}

/**
 * Skill Definitions
 */
export type SkillCategory = 
  | 'tech' 
  | 'business' 
  | 'creative' 
  | 'trades' 
  | 'academic' 
  | 'social';

export interface Skill {
  id: string;
  name: string;
  category: SkillCategory;
  vouches: Vouch[];
  evidence?: string[]; // IPFS hashes
}

/**
 * Reputation & Vouching
 */
export interface Vouch {
  id: string; // Soroban standard identifier
  fromUserId: string;
  toUserId: string;
  skillId: string;
  comment?: string;
  evidence?: string; // IPFS hash
  createdAt: Date;
  confidence: number; // 1-5 stars
  isValid: boolean; // Can be invalidated by validators or revoked
}

/**
 * Inner Circle DAOs
 */
export interface InnerCircle {
  id: string; // Proposal count/ID
  name: string;
  description: string;
  minRepScoreToJoin: number;
  minRepScoreToCreate: number;
  memberCount: number;
  members: string[]; // Stellar Addresses
  treasuryBalance: number; // XLM balance
  proposals: Proposal[];
}

export enum ProposalState {
  Pending = 0,
  Active = 1,
  Defeated = 2,
  Succeeded = 3,
  Executed = 4,
  Cancelled = 5
}

export interface Proposal {
  id: string;
  proposer: string;
  title: string;
  description: string;
  amount: number; // XLM/AFD amount
  recipient: string;
  voteStart: Date;
  voteEnd: Date;
  forVotes: number;
  againstVotes: number;
  state: ProposalState;
}

/**
 * Opportunity Marketplace
 */
export interface Opportunity {
  id: string;
  title: string;
  description: string;
  payoutAmount: number;
  payoutCurrency: string; // e.g., 'AFD', 'NGN'
  requiredSkills: string[];
  minRepScore: number;
  location: string; // Country code or 'Remote'
  deadline: Date;
  employerId: string;
  status: 'open' | 'in_progress' | 'completed' | 'cancelled';
}

/**
 * Activity Feed & Notifications
 */
export type ActivityType = 
  | 'VOUCH_RECEIVED'
  | 'VOUCH_GIVEN'
  | 'REP_INCREASED'
  | 'NEW_OPPORTUNITY'
  | 'DAO_PROPOSAL'
  | 'PAYMENT_RECEIVED';

export interface ActivityFeedItem {
  id: string;
  type: ActivityType;
  actorId: string; // User who triggered the activity
  targetId: string; // Relevant entity (vouch ID, opportunity ID, etc.)
  timestamp: Date;
  metadata: Record<string, any>; // Flexible data payload for UI rendering
  read: boolean;
}

/**
 * Financial Transactions (Stablecoin)
 */
export type TransactionType = 'MINT' | 'BURN' | 'TRANSFER';
export type FiatCurrency = 'NGN' | 'KES' | 'ZAR' | 'GHS' | 'EGP' | 'XOF' | 'XAF' | 'TZS' | 'UGX';

export interface Transaction {
  id: string;
  type: TransactionType;
  amount: number; // AFD Amount
  fiatAmount?: number;
  fiatCurrency?: FiatCurrency;
  exchangeRate?: number;
  fromAddress: string;
  toAddress: string;
  timestamp: Date;
  status: 'pending' | 'completed' | 'failed';
  txHash: string; // Blockchain transaction hash
}