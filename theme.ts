import { Dimensions, Platform } from 'react-native';

const { width, height } = Dimensions.get('window');

// Responsive breakpoints
export const layout = {
  window: { width, height },
  isSmallDevice: width < 375,
  isTablet: width >= 768,
};

// Base colors that can be used directly or through semantic tokens
const palette = {
  // Brand colors
  naijaGreen: '#008751',
  vibrantOrange: '#FF6B35',
  deepPurple: '#6B46C1',
  successGold: '#F59E0B',
  
  // Neutral colors (slate scale)
  slate50: '#F8FAFC',
  slate100: '#F1F5F9',
  slate200: '#E2E8F0',
  slate300: '#CBD5E1',
  slate400: '#94A3B8',
  slate500: '#64748B',
  slate600: '#475569',
  slate700: '#334155',
  slate800: '#1E293B',
  slate900: '#0F172A',
  slate950: '#020617',
  
  // Semantic base
  white: '#FFFFFF',
  black: '#000000',
  red600: '#DC2626',
  emerald600: '#059669',
  blue600: '#2563EB',
};

// Gradients for premium UI elements
export const gradients = {
  primary: ['#008751', '#059669'], // Green gradient
  accent: ['#FF6B35', '#F59E0B'], // Orange to Gold
  dark: ['#1E293B', '#0F172A'], // Dark slate
  reputation: {
    low: ['#EF4444', '#DC2626'],
    medium: ['#F59E0B', '#D97706'],
    high: ['#10B981', '#059669'],
    legend: ['#8B5CF6', '#6B46C1'],
  }
};

export const theme = {
  // Light mode colors (default)
  colors: {
    primary: palette.naijaGreen,
    secondary: palette.vibrantOrange,
    accent: palette.deepPurple,
    gold: palette.successGold,
    
    // Backgrounds
    background: palette.slate50,
    surface: palette.white,
    surfaceSubdued: palette.slate100,
    
    // Text
    text: palette.slate900,
    textSecondary: palette.slate500,
    textInverse: palette.white,
    
    // Feedback
    error: palette.red600,
    success: palette.emerald600,
    info: palette.blue600,
    warning: palette.successGold,
    
    // Borders & Dividers
    border: palette.slate200,
    divider: palette.slate200,
    
    // Overlays
    overlay: 'rgba(15, 23, 42, 0.5)', // Slate 900 at 50%
  },
  
  // Dark mode colors
  darkColors: {
    primary: '#10B981', // Slightly lighter green for dark mode contrast
    secondary: palette.vibrantOrange,
    accent: '#8B5CF6', // Lighter purple
    gold: palette.successGold,
    
    background: palette.slate950,
    surface: palette.slate900,
    surfaceSubdued: palette.slate800,
    
    text: palette.slate50,
    textSecondary: palette.slate400,
    textInverse: palette.slate900,
    
    error: '#EF4444',
    success: '#10B981',
    info: '#3B82F6',
    warning: '#FBBF24',
    
    border: palette.slate800,
    divider: palette.slate800,
    
    overlay: 'rgba(2, 6, 23, 0.7)',
  },

  spacing: {
    xxs: 2,
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 48,
    xxxl: 64,
  },

  typography: {
    h1: {
      fontSize: 32,
      fontWeight: '800',
      lineHeight: 40,
    },
    h2: {
      fontSize: 24,
      fontWeight: '700',
      lineHeight: 32,
    },
    h3: {
      fontSize: 20,
      fontWeight: '600',
      lineHeight: 28,
    },
    bodyLarge: {
      fontSize: 18,
      fontWeight: '400',
      lineHeight: 28,
    },
    body: {
      fontSize: 16,
      fontWeight: '400',
      lineHeight: 24,
    },
    bodyMedium: {
      fontSize: 16,
      fontWeight: '500',
      lineHeight: 24,
    },
    caption: {
      fontSize: 14,
      fontWeight: '400',
      lineHeight: 20,
    },
    small: {
      fontSize: 12,
      fontWeight: '500',
      lineHeight: 16,
    },
  },

  borderRadius: {
    none: 0,
    sm: 4,
    md: 8,
    lg: 12,
    xl: 16,
    xxl: 24,
    pill: 9999,
  },

  // Cross-platform shadow generation
  shadows: {
    sm: Platform.select({
      ios: {
        shadowColor: palette.slate900,
        shadowOffset: { width: 0, height: 1 },
        shadowOpacity: 0.05,
        shadowRadius: 2,
      },
      android: {
        elevation: 2,
      },
    }),
    md: Platform.select({
      ios: {
        shadowColor: palette.slate900,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.1,
        shadowRadius: 6,
      },
      android: {
        elevation: 4,
      },
    }),
    lg: Platform.select({
      ios: {
        shadowColor: palette.slate900,
        shadowOffset: { width: 0, height: 10 },
        shadowOpacity: 0.1,
        shadowRadius: 15,
      },
      android: {
        elevation: 8,
      },
    }),
  },

  // Animation timing configuration
  animation: {
    duration: {
      fast: 150,
      normal: 300,
      slow: 500,
    },
    easing: {
      // standard cubic-bezier(0.4, 0, 0.2, 1) equivalent
      standard: 'ease-in-out',
      bounce: 'spring',
    }
  }
};