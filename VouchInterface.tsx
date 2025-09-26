import React, { useState } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  TouchableOpacity, 
  TextInput,
  ScrollView,
  Alert 
} from 'react-native';
import { theme } from '../../utils/theme';

interface VouchInterfaceProps {
  onVouch: (skillId: string, comment: string, confidence: number) => void;
  userSkills: string[];
}

const VouchInterface: React.FC<VouchInterfaceProps> = ({ onVouch, userSkills }) => {
  const [selectedSkill, setSelectedSkill] = useState<string>('');
  const [comment, setComment] = useState<string>('');
  const [confidence, setConfidence] = useState<number>(5);

  const skillCategories = [
    { id: 'tech', name: 'Tech & Coding', icon: '💻' },
    { id: 'business', name: 'Business', icon: '💼' },
    { id: 'creative', name: 'Creative', icon: '🎨' },
    { id: 'trades', name: 'Trades', icon: '🔧' },
    { id: 'academic', name: 'Academic', icon: '📚' },
    { id: 'social', name: 'Social Skills', icon: '🤝' },
  ];

  const handleVouch = () => {
    if (!selectedSkill) {
      Alert.alert('Oya Now!', 'Select one skill you wan vouch for first.');
      return;
    }

    onVouch(selectedSkill, comment, confidence);
    setSelectedSkill('');
    setComment('');
    setConfidence(5);
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Show Some Love 💚</Text>
      <Text style={styles.subtitle}>Vouch for your person's skills</Text>
      
      {/* Skill Categories */}
      <View style={styles.skillsContainer}>
        {skillCategories.map((category) => (
          <TouchableOpacity
            key={category.id}
            style={[
              styles.skillButton,
              selectedSkill === category.id && styles.skillButtonSelected
            ]}
            onPress={() => setSelectedSkill(category.id)}
          >
            <Text style={styles.skillIcon}>{category.icon}</Text>
            <Text style={styles.skillText}>{category.name}</Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Confidence Rating */}
      <View style={styles.confidenceContainer}>
        <Text style={styles.confidenceLabel}>How much you trust this skill?</Text>
        <View style={styles.starsContainer}>
          {[1, 2, 3, 4, 5].map((star) => (
            <TouchableOpacity
              key={star}
              onPress={() => setConfidence(star)}
            >
              <Text style={[
                styles.star,
                star <= confidence && styles.starSelected
              ]}>
                ⭐
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      {/* Comment */}
      <TextInput
        style={styles.commentInput}
        placeholder="Add small comment (optional)..."
        value={comment}
        onChangeText={setComment}
        multiline
        numberOfLines={3}
      />

      {/* Submit Button */}
      <TouchableOpacity 
        style={[
          styles.submitButton,
          !selectedSkill && styles.submitButtonDisabled
        ]}
        onPress={handleVouch}
        disabled={!selectedSkill}
      >
        <Text style={styles.submitButtonText}>Send Vouch 🙌</Text>
      </TouchableOpacity>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: theme.spacing.md,
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: theme.colors.text,
    marginBottom: theme.spacing.xs,
  },
  subtitle: {
    fontSize: 16,
    color: theme.colors.textSecondary,
    marginBottom: theme.spacing.lg,
  },
  skillsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.lg,
  },
  skillButton: {
    width: '48%',
    padding: theme.spacing.md,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.md,
    alignItems: 'center',
    marginBottom: theme.spacing.sm,
    borderWidth: 2,
    borderColor: 'transparent',
  },
  skillButtonSelected: {
    borderColor: theme.colors.primary,
    backgroundColor: '#E8F5E8',
  },
  skillIcon: {
    fontSize: 24,
    marginBottom: theme.spacing.xs,
  },
  skillText: {
    fontSize: 12,
    fontWeight: '600',
    textAlign: 'center',
  },
  confidenceContainer: {
    marginBottom: theme.spacing.lg,
  },
  confidenceLabel: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: theme.spacing.sm,
  },
  starsContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
  },
  star: {
    fontSize: 28,
    marginHorizontal: theme.spacing.xs,
    opacity: 0.3,
  },
  starSelected: {
    opacity: 1,
  },
  commentInput: {
    borderWidth: 1,
    borderColor: theme.colors.surface,
    borderRadius: theme.borderRadius.md,
    padding: theme.spacing.md,
    fontSize: 16,
    marginBottom: theme.spacing.lg,
    textAlignVertical: 'top',
  },
  submitButton: {
    backgroundColor: theme.colors.primary,
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.lg,
    alignItems: 'center',
  },
  submitButtonDisabled: {
    opacity: 0.5,
  },
  submitButtonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: '700',
  },
});

export default VouchInterface;