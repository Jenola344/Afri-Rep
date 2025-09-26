export interface User {
  id: string;
  phone: string;
  name: string;
  profileImage?: string;
  location: string;
  skills: Skill[];
  repScore: number;
  joinedAt: Date;
  isVerified: boolean;
}

export interface Skill {
  id: string;
  name: string;
  category: SkillCategory;
  vouches: Vouch[];
  evidence?: string[];
}

export interface Vouch {
  id: string;
  fromUserId: string;
  toUserId: string;
  skillId: string;
  comment?: string;
  evidence?: string;
  createdAt: Date;
  confidence: number; // 1-5 stars
}

export interface InnerCircle {
  id: string;
  name: string;
  description: string;
  minRepScore: number;
  memberCount: number;
  members: string[];
  savingsPool: number;
  nextPayout: Date;
  isPublic: boolean;
}

export type SkillCategory = 
  | 'tech' 
  | 'business' 
  | 'creative' 
  | 'trades' 
  | 'academic' 
  | 'social';

export interface Opportunity {
  id: string;
  title: string;
  description: string;
  payout: number;
  requiredSkills: string[];
  minRepScore: number;
  location: string;
  deadline: Date;
  employerId: string;
}