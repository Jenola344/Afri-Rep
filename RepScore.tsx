import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Svg, { Circle, G } from 'react-native-svg';
import { theme } from '../../utils/theme';

interface RepScoreProps {
  score: number;
  size?: number;
  strokeWidth?: number;
  showLabel?: boolean;
}

const RepScore: React.FC<RepScoreProps> = ({ 
  score, 
  size = 100, 
  strokeWidth = 8,
  showLabel = true 
}) => {
  const radius = (size - strokeWidth) / 2;
  const circumference = radius * 2 * Math.PI;
  const progress = (score / 1000) * circumference;
  
  const getScoreColor = () => {
    if (score < 200) return theme.colors.error;
    if (score < 500) return theme.colors.gold;
    return theme.colors.success;
  };

  const getScoreLevel = () => {
    if (score < 100) return 'Beginner';
    if (score < 300) return 'Trusted';
    if (score < 600) return 'Respected';
    if (score < 800) return 'Influencer';
    return 'Legend';
  };

  return (
    <View style={styles.container}>
      <View style={[styles.circleContainer, { width: size, height: size }]}>
        <Svg width={size} height={size}>
          <G rotation="-90" origin={`${size / 2}, ${size / 2}`}>
            {/* Background circle */}
            <Circle
              cx={size / 2}
              cy={size / 2}
              r={radius}
              stroke={theme.colors.surface}
              strokeWidth={strokeWidth}
              fill="transparent"
            />
            {/* Progress circle */}
            <Circle
              cx={size / 2}
              cy={size / 2}
              r={radius}
              stroke={getScoreColor()}
              strokeWidth={strokeWidth}
              fill="transparent"
              strokeDasharray={circumference}
              strokeDashoffset={circumference - progress}
              strokeLinecap="round"
            />
          </G>
        </Svg>
        
        <View style={styles.scoreContainer}>
          <Text style={styles.scoreText}>{score}</Text>
          {showLabel && (
            <Text style={[styles.levelText, { color: getScoreColor() }]}>
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
  },
  scoreContainer: {
    position: 'absolute',
    alignItems: 'center',
  },
  scoreText: {
    fontSize: 24,
    fontWeight: '700',
    color: theme.colors.text,
  },
  levelText: {
    fontSize: 12,
    fontWeight: '600',
    marginTop: 2,
  },
});

export default RepScore;