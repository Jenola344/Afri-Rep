import React, { useState } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  TouchableOpacity, 
  TextInput,
  ScrollView,
  Alert,
  Modal,
  Platform
} from 'react-native';
import { theme } from '../theme';

interface VouchInterfaceProps {
  onVouch?: (skillId: string, comment: string, confidence: number, evidenceUrl: string) => void;
  userSkills?: string[];
  recipientName?: string;
}

const VouchInterface: React.FC<VouchInterfaceProps> = ({ 
  onVouch, 
  userSkills = [], 
  recipientName = "this person"
}) => {
  const [selectedSkill, setSelectedSkill] = useState<string>('');
  const [comment, setComment] = useState<string>('');
  const [confidence, setConfidence] = useState<number>(5);
  const [evidenceUrl, setEvidenceUrl] = useState<string>('');
  const [showConfirmModal, setShowConfirmModal] = useState<boolean>(false);

  const skillCategories = [
    { id: 'tech', name: 'Tech & Coding', icon: '💻' },
    { id: 'business', name: 'Business', icon: '💼' },
    { id: 'creative', name: 'Creative', icon: '🎨' },
    { id: 'trades', name: 'Trades', icon: '🔧' },
    { id: 'academic', name: 'Academic', icon: '📚' },
    { id: 'social', name: 'Social Skills', icon: '🤝' },
  ];

  const handleVouchSubmit = () => {
    if (!selectedSkill) {
      Alert.alert('Hold on!', 'Please select a skill to vouch for.');
      return;
    }
    // Show confirmation modal before executing transaction
    setShowConfirmModal(true);
  };

  const confirmVouch = () => {
    setShowConfirmModal(false);
    if (onVouch) {
      onVouch(selectedSkill, comment, confidence, evidenceUrl);
    } else {
      Alert.alert("Success", `You successfully vouched for ${recipientName}!`);
    }
    // Reset form
    setSelectedSkill('');
    setComment('');
    setConfidence(5);
    setEvidenceUrl('');
  };

  return (
    <View style={styles.mainContainer}>
      <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
        <View style={styles.header}>
          <Text style={styles.title}>Show Some Love 💚</Text>
          <Text style={styles.subtitle}>Vouch for {recipientName}'s skills</Text>
        </View>
        
        {/* Skill Categories */}
        <Text style={styles.sectionTitle}>1. Select a Skill Category</Text>
        <View style={styles.skillsContainer}>
          {skillCategories.map((category) => (
            <TouchableOpacity
              key={category.id}
              activeOpacity={0.7}
              style={[
                styles.skillButton,
                selectedSkill === category.id && styles.skillButtonSelected
              ]}
              onPress={() => setSelectedSkill(category.id)}
            >
              <Text style={styles.skillIcon}>{category.icon}</Text>
              <Text style={[
                styles.skillText,
                selectedSkill === category.id && styles.skillTextSelected
              ]}>
                {category.name}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Confidence Rating */}
        <Text style={styles.sectionTitle}>2. Confidence Level</Text>
        <View style={styles.confidenceContainer}>
          <Text style={styles.confidenceLabel}>How strongly do you back this?</Text>
          <View style={styles.starsContainer}>
            {[1, 2, 3, 4, 5].map((star) => (
              <TouchableOpacity
                key={star}
                activeOpacity={0.6}
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
          <Text style={styles.confidenceHint}>
            {confidence === 1 && "Just started learning"}
            {confidence === 2 && "Knows the basics"}
            {confidence === 3 && "Solid, reliable performer"}
            {confidence === 4 && "Expert level"}
            {confidence === 5 && "Absolute Master (Legend)"}
          </Text>
        </View>

        {/* Evidence Link */}
        <Text style={styles.sectionTitle}>3. Evidence (Optional but boosts Rep)</Text>
        <TextInput
          style={styles.input}
          placeholder="Link to portfolio, GitHub, or project..."
          placeholderTextColor={theme.colors.textSecondary}
          value={evidenceUrl}
          onChangeText={setEvidenceUrl}
          autoCapitalize="none"
          autoCorrect={false}
        />

        {/* Comment */}
        <Text style={styles.sectionTitle}>4. Leave a Comment</Text>
        <TextInput
          style={styles.commentInput}
          placeholder="E.g., 'Omo, this dev sabi work! Delivered before deadline...'"
          placeholderTextColor={theme.colors.textSecondary}
          value={comment}
          onChangeText={setComment}
          multiline
          numberOfLines={4}
          textAlignVertical="top"
        />

        {/* Submit Button */}
        <TouchableOpacity 
          style={[
            styles.submitButton,
            !selectedSkill && styles.submitButtonDisabled
          ]}
          onPress={handleVouchSubmit}
          disabled={!selectedSkill}
        >
          <Text style={styles.submitButtonText}>Send Vouch 🙌</Text>
        </TouchableOpacity>
        
        <View style={styles.bottomSpacer} />
      </ScrollView>

      {/* Confirmation Modal */}
      <Modal
        visible={showConfirmModal}
        transparent={true}
        animationType="fade"
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Confirm Vouch</Text>
            <Text style={styles.modalBody}>
              You are staking your own reputation by vouching for {recipientName}. 
              If this vouch is later invalidated by the community, your Rep Score will decrease.
            </Text>
            <View style={styles.modalButtons}>
              <TouchableOpacity 
                style={[styles.modalButton, styles.modalButtonCancel]}
                onPress={() => setShowConfirmModal(false)}
              >
                <Text style={styles.modalButtonCancelText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity 
                style={[styles.modalButton, styles.modalButtonConfirm]}
                onPress={confirmVouch}
              >
                <Text style={styles.modalButtonConfirmText}>I Stand By It</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  mainContainer: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  container: {
    flex: 1,
    padding: theme.spacing.lg,
  },
  header: {
    marginBottom: theme.spacing.lg,
  },
  title: {
    ...theme.typography.h1,
    color: theme.colors.text,
    marginBottom: theme.spacing.xs,
  },
  subtitle: {
    ...theme.typography.bodyLarge,
    color: theme.colors.textSecondary,
  },
  sectionTitle: {
    ...theme.typography.h3,
    color: theme.colors.text,
    marginTop: theme.spacing.md,
    marginBottom: theme.spacing.md,
  },
  skillsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  skillButton: {
    width: '48%',
    padding: theme.spacing.md,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.md,
    alignItems: 'center',
    marginBottom: theme.spacing.md,
    borderWidth: 2,
    borderColor: 'transparent',
    ...theme.shadows.sm,
  },
  skillButtonSelected: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}10`, // 10% opacity primary
  },
  skillIcon: {
    fontSize: 28,
    marginBottom: theme.spacing.sm,
  },
  skillText: {
    ...theme.typography.bodyMedium,
    color: theme.colors.text,
    textAlign: 'center',
  },
  skillTextSelected: {
    color: theme.colors.primary,
    fontWeight: '700',
  },
  confidenceContainer: {
    backgroundColor: theme.colors.surface,
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.lg,
    alignItems: 'center',
    ...theme.shadows.sm,
  },
  confidenceLabel: {
    ...theme.typography.body,
    color: theme.colors.textSecondary,
    marginBottom: theme.spacing.sm,
  },
  starsContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginBottom: theme.spacing.sm,
  },
  star: {
    fontSize: 36,
    marginHorizontal: theme.spacing.xs,
    opacity: 0.2,
  },
  starSelected: {
    opacity: 1,
  },
  confidenceHint: {
    ...theme.typography.bodyMedium,
    color: theme.colors.primary,
    marginTop: theme.spacing.xs,
  },
  input: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: theme.borderRadius.md,
    padding: theme.spacing.md,
    ...theme.typography.body,
    color: theme.colors.text,
    ...theme.shadows.sm,
  },
  commentInput: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: theme.borderRadius.md,
    padding: theme.spacing.md,
    ...theme.typography.body,
    color: theme.colors.text,
    minHeight: 100,
    ...theme.shadows.sm,
  },
  submitButton: {
    backgroundColor: theme.colors.primary,
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.xl,
    alignItems: 'center',
    marginTop: theme.spacing.xl,
    ...theme.shadows.md,
  },
  submitButtonDisabled: {
    backgroundColor: theme.colors.border,
    elevation: 0,
    shadowOpacity: 0,
  },
  submitButtonText: {
    color: theme.colors.surface,
    ...theme.typography.h3,
  },
  bottomSpacer: {
    height: 60,
  },
  // Modal Styles
  modalOverlay: {
    flex: 1,
    backgroundColor: theme.colors.overlay,
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme.spacing.xl,
  },
  modalContent: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.xl,
    padding: theme.spacing.xl,
    width: '100%',
    ...theme.shadows.lg,
  },
  modalTitle: {
    ...theme.typography.h2,
    color: theme.colors.text,
    marginBottom: theme.spacing.sm,
  },
  modalBody: {
    ...theme.typography.body,
    color: theme.colors.textSecondary,
    marginBottom: theme.spacing.xl,
    lineHeight: 24,
  },
  modalButtons: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  modalButton: {
    flex: 1,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.md,
    alignItems: 'center',
  },
  modalButtonCancel: {
    backgroundColor: theme.colors.surfaceSubdued,
    marginRight: theme.spacing.sm,
  },
  modalButtonConfirm: {
    backgroundColor: theme.colors.primary,
    marginLeft: theme.spacing.sm,
  },
  modalButtonCancelText: {
    ...theme.typography.bodyMedium,
    color: theme.colors.text,
  },
  modalButtonConfirmText: {
    ...theme.typography.bodyMedium,
    color: 'white',
  },
});

export default VouchInterface;