/**
 * Settings/profile tab. Parity with Flutter
 * `profile/presentation/profile_screen.dart`.
 *
 * Assembles: account header, preferences, driving credentials, about, sign out.
 */

import { useRouter } from 'expo-router';
import { useQueryClient } from '@tanstack/react-query';
import { Alert, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ShimmerBox } from '@/components/shimmer-box';
import { Colors } from '@/constants/theme';
import { clearAllCaches } from '@/db/client';
import { authRepository } from '@/features/auth/repository';
import { useAuthStore } from '@/features/auth/store';
import { DrivingCredentialsSection } from '@/features/driving-credentials/components/driving-credentials-section';
import { useMe, useUpdateMe } from '../hooks';
import { AboutSection } from './about-section';
import { AccountHeaderCard } from './account-header-card';
import { PreferencesCard } from './preferences-card';
import { SignOutButton } from './sign-out-button';

const TEXT_MUTED = '#9A9AAF'; // profile_screen.dart line 901 `_SectionLabel`

function SectionLabel({ text }: { text: string }) {
  return <Text style={styles.sectionLabel}>{text.toUpperCase()}</Text>;
}

export function ProfileScreen() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const authUser = useAuthStore((s) => s.user);
  const { data: user, isLoading, isError, error } = useMe();
  const updateMe = useUpdateMe();

  async function handleSignOut() {
    // Clear all cached server state FIRST so the next user to sign in never
    // sees the previous user's data (CLAUDE.md — critical requirement). This
    // includes both the in-memory TanStack Query cache AND the on-disk
    // SQLite read-cache — missing either one is a privacy bug.
    queryClient.clear();
    await clearAllCaches();
    await authRepository.signOut();
  }

  function handleDistanceUnitChange(distanceUnit: 'km' | 'mi') {
    updateMe.mutate(
      { distanceUnit },
      {
        onError: (e) => {
          Alert.alert('Could not save preference', e instanceof Error ? e.message : String(e));
        },
      },
    );
  }

  function handleRenewalRemindersChange(renewalRemindersEnabled: boolean) {
    updateMe.mutate(
      { renewalRemindersEnabled },
      {
        onError: (e) => {
          Alert.alert('Could not save preference', e instanceof Error ? e.message : String(e));
        },
      },
    );
  }

  return (
    <SafeAreaView style={styles.safeArea} edges={['top']}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Settings</Text>
      </View>

      {isLoading ? (
        <ProfileLoadingSkeleton />
      ) : isError || !user ? (
        <View style={styles.center}>
          <Text style={styles.errorText}>
            Failed to load profile: {error instanceof Error ? error.message : String(error)}
          </Text>
        </View>
      ) : (
        <ScrollView contentContainerStyle={styles.content}>
          <SectionLabel text="Account" />
          <AccountHeaderCard
            user={user}
            authUser={authUser}
            onPress={() => router.push('/profile/edit')}
          />
          <View style={styles.sectionGap} />

          <SectionLabel text="Preferences" />
          <PreferencesCard
            user={user}
            saving={updateMe.isPending}
            onDistanceUnitChange={handleDistanceUnitChange}
            onRenewalRemindersChange={handleRenewalRemindersChange}
          />
          <View style={styles.sectionGap} />

          <SectionLabel text="Driving Credentials" />
          <DrivingCredentialsSection />
          <View style={styles.sectionGap} />

          <SectionLabel text="About" />
          <AboutSection />
          <View style={styles.sectionGap} />

          <SignOutButton onConfirm={handleSignOut} />
        </ScrollView>
      )}
    </SafeAreaView>
  );
}

function ProfileLoadingSkeleton() {
  return (
    <View style={styles.content}>
      <View style={styles.skeletonHeaderRow}>
        <ShimmerBox height={56} width={56} borderRadius={28} />
        <View style={styles.skeletonHeaderText}>
          <ShimmerBox height={20} borderRadius={6} />
        </View>
      </View>
      <View style={styles.sectionGap} />
      <ShimmerBox height={52} borderRadius={12} />
      <View style={styles.skeletonGapSmall} />
      <ShimmerBox height={52} borderRadius={12} />
      <View style={styles.skeletonGapSmall} />
      <ShimmerBox height={52} borderRadius={12} />
    </View>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  header: {
    height: 60,
    justifyContent: 'center',
    paddingHorizontal: 20,
  },
  headerTitle: {
    fontSize: 29,
    fontWeight: '800',
    color: Colors.textPrimary,
  },
  content: {
    paddingHorizontal: 16,
    paddingTop: 8,
    paddingBottom: 132,
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 16,
  },
  errorText: {
    color: Colors.danger,
    textAlign: 'center',
  },
  sectionLabel: {
    marginLeft: 4,
    marginBottom: 8,
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 1.2,
    color: TEXT_MUTED,
  },
  sectionGap: {
    height: 20,
  },
  skeletonHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  skeletonHeaderText: {
    flex: 1,
    marginLeft: 16,
  },
  skeletonGapSmall: {
    height: 12,
  },
});
