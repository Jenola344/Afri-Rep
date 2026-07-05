import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, RefreshControl } from 'react-native';
import { useSelector } from 'react-redux';
import { RootState } from '../store/store'; // Assuming this path exists
import RepScore from './RepScore';
import { theme } from '../theme';
import { LinearGradient } from 'expo-linear-gradient';

// Mock data for the UI since Redux state might not be fully populated
const MOCK_OPPORTUNITIES = [
  { id: '1', title: 'Smart Contract Auditor', location: 'Remote (Lagos Hub)', payout: '500 AFD', type: 'Gig' },
  { id: '2', title: 'UI/UX Designer', location: 'Nairobi, Kenya', payout: '300 AFD', type: 'Full-time' },
];

const MOCK_ACTIVITY = [
  { id: '1', user: 'Kwame', action: 'vouched for your', skill: 'React Native', time: '2h ago' },
  { id: '2', user: 'Amina', action: 'invited you to', skill: 'Tech Innovators DAO', time: '1d ago' },
];

const DashboardScreen: React.FC = () => {
  // Commented out Redux hooks to prevent runtime errors if store isn't set up yet
  // const user = useSelector((state: RootState) => state.auth.user);
  // const opportunities = useSelector((state: RootState) => state.opportunities.list);
  const [refreshing, setRefreshing] = React.useState(false);

  // Mock user for UI
  const user = { name: 'Chinedu', repScore: 780, countryCode: 'NGA' };

  const onRefresh = React.useCallback(() => {
    setRefreshing(true);
    setTimeout(() => setRefreshing(false), 2000);
  }, []);

  const quickActions = [
    { icon: '👋', title: 'Get Vouched', screen: 'VouchRequest', color: theme.colors.primary },
    { icon: '💚', title: 'Vouch Someone', screen: 'VouchInterface', color: theme.colors.secondary },
    { icon: '💼', title: 'Find Work', screen: 'Opportunities', color: theme.colors.info },
    { icon: '👥', title: 'My Circles', screen: 'Circles', color: theme.colors.accent },
  ];

  return (
    <ScrollView 
      style={styles.container}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={theme.colors.primary} />}
    >
      {/* Header Profile Section */}
      <View style={styles.header}>
        <View style={styles.greetingContainer}>
          <Text style={styles.greeting}>How you dey,</Text>
          <Text style={styles.userName}>{user?.name} 🇳🇬</Text>
        </View>
        <TouchableOpacity style={styles.profileBadge}>
          <Text style={styles.profileInitials}>{user?.name?.charAt(0) || 'U'}</Text>
        </TouchableOpacity>
      </View>

      {/* Main Reputation Card */}
      <View style={styles.repCardContainer}>
        <LinearGradient
          colors={['#008751', '#059669']}
          style={styles.repCardGradient}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        >
          <View style={styles.repCardContent}>
            <View style={styles.repTextContent}>
              <Text style={styles.repLabel}>Your Afri Rep Score</Text>
              <Text style={styles.repSubtitle}>Top 5% in West Africa</Text>
              <TouchableOpacity style={styles.viewDetailsBtn}>
                <Text style={styles.viewDetailsText}>View Details →</Text>
              </TouchableOpacity>
            </View>
            <View style={styles.repScoreWrapper}>
              <RepScore score={user.repScore || 0} size={110} strokeWidth={10} inverseColor={true} />
            </View>
          </View>
        </LinearGradient>
      </View>

      {/* Quick Actions Grid */}
      <Text style={styles.sectionTitle}>Quick Actions</Text>
      <View style={styles.quickActionsGrid}>
        {quickActions.map((action, index) => (
          <TouchableOpacity 
            key={index} 
            style={styles.actionCard}
            activeOpacity={0.7}
          >
            <View style={[styles.iconContainer, { backgroundColor: `${action.color}15` }]}>
              <Text style={styles.actionIcon}>{action.icon}</Text>
            </View>
            <Text style={styles.actionTitle}>{action.title}</Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Recent Activity */}
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>Recent Activity</Text>
        <TouchableOpacity><Text style={styles.seeAllText}>See All</Text></TouchableOpacity>
      </View>
      <View style={styles.activityContainer}>
        {MOCK_ACTIVITY.map((activity) => (
          <View key={activity.id} style={styles.activityItem}>
            <View style={styles.activityDot} />
            <View style={styles.activityTextContainer}>
              <Text style={styles.activityText}>
                <Text style={styles.boldText}>{activity.user}</Text> {activity.action} <Text style={styles.boldText}>{activity.skill}</Text>
              </Text>
              <Text style={styles.timeText}>{activity.time}</Text>
            </View>
          </View>
        ))}
      </View>

      {/* Opportunities */}
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>Opportunities for You</Text>
        <TouchableOpacity><Text style={styles.seeAllText}>See All</Text></TouchableOpacity>
      </View>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.opportunitiesScroll}>
        {MOCK_OPPORTUNITIES.map((opp) => (
          <TouchableOpacity key={opp.id} style={styles.opportunityCard}>
            <View style={styles.oppHeader}>
              <Text style={styles.oppType}>{opp.type}</Text>
              <Text style={styles.oppPayout}>{opp.payout}</Text>
            </View>
            <Text style={styles.oppTitle}>{opp.title}</Text>
            <Text style={styles.oppLocation}>📍 {opp.location}</Text>
          </TouchableOpacity>
        ))}
      </ScrollView>
      
      {/* Bottom padding */}
      <View style={styles.bottomSpacer} />
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: theme.spacing.lg,
    paddingTop: theme.spacing.xl,
    paddingBottom: theme.spacing.md,
  },
  greetingContainer: {
    flex: 1,
  },
  greeting: {
    ...theme.typography.bodyMedium,
    color: theme.colors.textSecondary,
  },
  userName: {
    ...theme.typography.h1,
    color: theme.colors.text,
    marginTop: theme.spacing.xxs,
  },
  profileBadge: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: theme.colors.primary,
    justifyContent: 'center',
    alignItems: 'center',
    ...theme.shadows.sm,
  },
  profileInitials: {
    color: theme.colors.textInverse,
    ...theme.typography.h3,
  },
  repCardContainer: {
    paddingHorizontal: theme.spacing.lg,
    marginBottom: theme.spacing.lg,
  },
  repCardGradient: {
    borderRadius: theme.borderRadius.xl,
    padding: theme.spacing.lg,
    ...theme.shadows.md,
  },
  repCardContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  repTextContent: {
    flex: 1,
  },
  repLabel: {
    color: 'rgba(255, 255, 255, 0.9)',
    ...theme.typography.bodyMedium,
  },
  repSubtitle: {
    color: 'white',
    ...theme.typography.h3,
    marginTop: theme.spacing.xs,
    marginBottom: theme.spacing.md,
  },
  viewDetailsBtn: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.pill,
    alignSelf: 'flex-start',
  },
  viewDetailsText: {
    color: 'white',
    ...theme.typography.small,
  },
  repScoreWrapper: {
    marginLeft: theme.spacing.md,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: theme.spacing.lg,
    marginTop: theme.spacing.lg,
    marginBottom: theme.spacing.md,
  },
  sectionTitle: {
    ...theme.typography.h3,
    color: theme.colors.text,
    paddingHorizontal: theme.spacing.lg,
  },
  seeAllText: {
    ...theme.typography.bodyMedium,
    color: theme.colors.primary,
  },
  quickActionsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: theme.spacing.lg,
    marginTop: theme.spacing.sm,
    justifyContent: 'space-between',
  },
  actionCard: {
    width: '48%',
    backgroundColor: theme.colors.surface,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    marginBottom: theme.spacing.md,
    alignItems: 'center',
    ...theme.shadows.sm,
  },
  iconContainer: {
    width: 56,
    height: 56,
    borderRadius: 28,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: theme.spacing.sm,
  },
  actionIcon: {
    fontSize: 24,
  },
  actionTitle: {
    ...theme.typography.bodyMedium,
    color: theme.colors.text,
  },
  activityContainer: {
    paddingHorizontal: theme.spacing.lg,
    backgroundColor: theme.colors.surface,
    marginHorizontal: theme.spacing.lg,
    borderRadius: theme.borderRadius.lg,
    paddingVertical: theme.spacing.md,
    ...theme.shadows.sm,
  },
  activityItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme.spacing.sm,
  },
  activityDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: theme.colors.secondary,
    marginRight: theme.spacing.md,
  },
  activityTextContainer: {
    flex: 1,
  },
  activityText: {
    ...theme.typography.body,
    color: theme.colors.text,
  },
  boldText: {
    fontWeight: '700',
  },
  timeText: {
    ...theme.typography.caption,
    color: theme.colors.textSecondary,
    marginTop: 2,
  },
  opportunitiesScroll: {
    paddingLeft: theme.spacing.lg,
  },
  opportunityCard: {
    backgroundColor: theme.colors.surface,
    width: 280,
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.lg,
    marginRight: theme.spacing.md,
    ...theme.shadows.sm,
  },
  oppHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.sm,
  },
  oppType: {
    color: theme.colors.primary,
    ...theme.typography.small,
    backgroundColor: `${theme.colors.primary}15`,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 2,
    borderRadius: theme.borderRadius.sm,
  },
  oppPayout: {
    color: theme.colors.success,
    ...theme.typography.bodyMedium,
  },
  oppTitle: {
    ...theme.typography.h3,
    color: theme.colors.text,
    marginBottom: theme.spacing.xs,
  },
  oppLocation: {
    ...theme.typography.caption,
    color: theme.colors.textSecondary,
  },
  bottomSpacer: {
    height: 40,
  }
});

export default DashboardScreen;