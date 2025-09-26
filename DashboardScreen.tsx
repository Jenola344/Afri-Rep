import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useSelector } from 'react-redux';
import { RootState } from '../store/store';
import RepScore from '../components/reputation/RepScore';
import { theme } from '../utils/theme';

const DashboardScreen: React.FC = () => {
  const user = useSelector((state: RootState) => state.auth.user);
  const opportunities = useSelector((state: RootState) => state.opportunities.list);

  const quickActions = [
    { icon: '👋', title: 'Get Vouched', screen: 'VouchRequest' },
    { icon: '💚', title: 'Vouch Someone', screen: 'VouchInterface' },
    { icon: '💼', title: 'Find Work', screen: 'Opportunities' },
    { icon: '👥', title: 'My Circles', screen: 'Circles' },
  ];

  return (
    <ScrollView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.greeting}>How you dey, {user?.name}!