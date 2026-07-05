import React, { useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Svg, { Circle, G, Defs, LinearGradient as SvgLinearGradient, Stop } from 'react-native-svg';
import Animated, { 
  useSharedValue, 
  useAnimatedProps, 
  withTiming, 
  Easing,
  interpolateColor
} from 'react-native-reanimated';
import { theme } from '../theme';

interface RepScoreProps {
  score: number;
  size?: number;
  strokeWidth?: number;
  showLabel?: boolean;
  inverseColor?: boolean; // Used when displayed on dark/colored backgrounds
}

const AnimatedCircle = Animated.createAnimatedComponent(Circle);

const RepScore: React.FC<RepScoreProps> = ({ 
  score, 
  size = 120, 
  strokeWidth = 10,
  showLabel = true,
  inverseColor = false
}) => {
  const radius = (size - strokeWidth) / 2;
  const circumference = radius * 2 * Math.PI;
  const targetProgress = (score / 1000) * circumference;
  
  // Animation value
  const animatedProgress = useSharedValue(0);

  useEffect(() => {
    animatedProgress.value = withTiming(targetProgress, {
      duration: 1500,
      easing: Easing.bezier(0.4, 0, 0.2, 1), // Standard easing
    });
  }, [score]);

  const animatedProps = useAnimatedProps(() => {
    return {
      strokeDashoffset: circumference - animatedProgress.value,
    };
  });
  
  const getScoreColor = () => {
    if (inverseColor) return '#FFFFFF'; // White when on gradient background
    if (score < 200) return theme.colors.error;
    if (score < 500) return theme.colors.gold;
    if (score < 800) return theme.colors.primary;
    return theme.colors.accent; // Legend level
  };

  const getScoreLevel = () => {
    if (score < 100) return 'Beginner';
    if (score < 300) return 'Trusted';
    if (score < 600) return 'Respected';
    if (score < 800) return 'Influencer';
    return 'Legend';
  };

  const gradientId = `grad-${score}`;

  return (
    <View style={styles.container}>
      <View style={[styles.circleContainer, { width: size, height: size }]}>
        <Svg width={size} height={size}>
          <Defs>
            <SvgLinearGradient id={gradientId} x1="0%" y1="0%" x2="100%" y2="100%">
              {inverseColor ? (
                <>
                  <Stop offset="0%" stopColor="#FFFFFF" stopOpacity="1" />
                  <Stop offset="100%" stopColor="#FFFFFF" stopOpacity="0.7" />
                </>
              ) : (
                <>
                  <Stop offset="0%" stopColor={getScoreColor()} stopOpacity="1" />
                  <Stop offset="100%" stopColor={getScoreColor()} stopOpacity="0.7" />
                </>
              )}
            </SvgLinearGradient>
          </Defs>
          <G rotation="-90" origin={`${size / 2}, ${size / 2}`}>
            {/* Background track circle */}
            <Circle
              cx={size / 2}
              cy={size / 2}
              r={radius}
              stroke={inverseColor ? 'rgba(255,255,255,0.2)' : theme.colors.surfaceSubdued}
              strokeWidth={strokeWidth}
              fill="transparent"
            />
            {/* Animated Progress circle */}
            <AnimatedCircle
              cx={size / 2}
              cy={size / 2}
              r={radius}
              stroke={`url(#${gradientId})`}
              strokeWidth={strokeWidth}
              fill="transparent"
              strokeDasharray={circumference}
              animatedProps={animatedProps}
              strokeLinecap="round"
            />
          </G>
        </Svg>
        
        <View style={styles.scoreContainer}>
          <Text style={[
            styles.scoreText, 
            { color: inverseColor ? '#FFFFFF' : theme.colors.text }
          ]}>
            {score}
          </Text>
          {showLabel && (
            <Text style={[
              styles.levelText, 
              { color: inverseColor ? 'rgba(255,255,255,0.9)' : getScoreColor() }
            ]}>
              {getScoreLevel()}
            </Text>
          )}
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  circleContainer: {
    position: 'relative',
    alignItems: 'center',
    justifyContent: 'center',
    ...theme.shadows.sm,
  },
  scoreContainer: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
  },
  scoreText: {
    fontSize: 28,
    fontWeight: '800',
    letterSpacing: -1,
  },
  levelText: {
    fontSize: 12,
    fontWeight: '600',
    marginTop: 2,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
});

export default RepScore;