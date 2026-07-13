/**
 * Dashboard (home tab) screen. Parity with Flutter
 * `features/dashboard/presentation/dashboard_screen.dart`.
 */

import { useRouter } from 'expo-router';
import { RefreshControl, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { AppButton } from '@/components/app-button';
import { ShimmerBox } from '@/components/shimmer-box';
import { Colors, cardShadow } from '@/constants/theme';
import { VerifyEmailBanner } from '@/features/auth/components/verify-email-banner';
import { useMe } from '@/features/profile/hooks';
import { FALLBACK_CURRENCY } from '@/lib/currencies';
import { useDashboard } from '../hooks';
import { attentionRenewals } from '../helpers';
import { CredentialExpiryBanner } from './credential-expiry-banner';
import { DashboardHeader } from './dashboard-header';
import { NeedsAttentionCard } from './needs-attention-card';
import { RecentActivitySection } from './recent-activity-section';
import { SpendCard } from './spend-card';

export function DashboardScreen() {
  const { data, isLoading, isError, error, refetch, isRefetching } = useDashboard();
  const { data: me } = useMe();
  const currency = me?.currency ?? FALLBACK_CURRENCY;

  if (isLoading) return <LoadingState />;
  if (isError) {
    return (
      <ErrorState message={error instanceof Error ? error.message : String(error)} onRetry={refetch} />
    );
  }
  if (!data) return null;

  return (
    <SafeAreaView style={styles.safeArea} edges={['top']}>
      <ScrollView
        contentContainerStyle={styles.content}
        refreshControl={<RefreshControl refreshing={isRefetching} onRefresh={refetch} />}
      >
        <DashboardHeader displayName={me?.displayName ?? null} photoUrl={me?.photoUrl ?? null} />
        <View style={styles.gapLarge} />
        <VerifyEmailBanner />
        <CredentialExpiryBanner />

        {data.vehicleCount === 0 ? (
          <WelcomeCard />
        ) : (
          <LoadedBody currency={currency} data={data} />
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

function LoadedBody({
  currency,
  data,
}: {
  currency: string;
  data: NonNullable<ReturnType<typeof useDashboard>['data']>;
}) {
  const attention = attentionRenewals(data.upcomingRenewals);

  return (
    <View>
      {attention.length > 0 ? (
        <View style={styles.gapLarge}>
          <NeedsAttentionCard renewals={attention} />
        </View>
      ) : null}

      <View style={attention.length > 0 ? undefined : styles.gapLarge}>
        <SpendCard data={data} currency={currency} />
      </View>

      {data.recentActivity.length > 0 ? (
        <View style={styles.gapLarge}>
          <RecentActivitySection items={data.recentActivity.slice(0, 5)} currency={currency} />
        </View>
      ) : null}
    </View>
  );
}

function WelcomeCard() {
  const router = useRouter();
  return (
    <View style={[styles.welcomeCard, cardShadow]}>
      <View style={styles.welcomeHero}>
        <Text style={styles.welcomeHeroGlyph}>🚙</Text>
      </View>
      <View style={styles.welcomeBody}>
        <Text style={styles.welcomeTitle}>Welcome to DriveVault</Text>
        <Text style={styles.welcomeSubtitle}>
          Add your first vehicle to start tracking fuel, costs and paperwork — all in one
          place.
        </Text>
        <AppButton
          label="Add your first vehicle"
          onPress={() => router.push('/garage/add-vehicle')}
          style={styles.welcomeButton}
        />
      </View>
    </View>
  );
}

function LoadingState() {
  return (
    <SafeAreaView style={styles.safeArea} edges={['top']}>
      <View style={styles.content}>
        <ShimmerBox height={56} borderRadius={12} />
        <View style={{ height: 20 }} />
        <ShimmerBox height={100} borderRadius={16} />
        <View style={{ height: 16 }} />
        <ShimmerBox height={80} borderRadius={16} />
        <View style={{ height: 16 }} />
        <ShimmerBox height={60} borderRadius={12} />
        <View style={{ height: 8 }} />
        <ShimmerBox height={60} borderRadius={12} />
      </View>
    </SafeAreaView>
  );
}

function ErrorState({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <SafeAreaView style={styles.safeArea} edges={['top']}>
      <View style={styles.errorCenter}>
        <Text style={styles.errorGlyph}>⚠️</Text>
        <Text style={styles.errorMessage}>{message}</Text>
        <AppButton label="Retry" onPress={onRetry} style={styles.errorButton} />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  content: {
    padding: 16,
    paddingBottom: 120,
  },
  gapLarge: {
    marginTop: 16,
  },
  welcomeCard: {
    marginTop: 16,
    backgroundColor: Colors.surface,
    borderRadius: 20,
    overflow: 'hidden',
  },
  welcomeHero: {
    height: 120,
    backgroundColor: Colors.surfaceDark,
    alignItems: 'center',
    justifyContent: 'center',
  },
  welcomeHeroGlyph: {
    fontSize: 40,
    opacity: 0.4,
  },
  welcomeBody: {
    padding: 20,
    alignItems: 'center',
  },
  welcomeTitle: {
    fontSize: 20,
    fontWeight: '800',
    letterSpacing: -0.4,
    color: Colors.textPrimary,
    textAlign: 'center',
  },
  welcomeSubtitle: {
    marginTop: 8,
    fontSize: 14,
    fontWeight: '400',
    color: Colors.textMuted,
    lineHeight: 20,
    textAlign: 'center',
  },
  welcomeButton: {
    marginTop: 20,
    width: '100%',
  },
  errorCenter: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  errorGlyph: {
    fontSize: 40,
  },
  errorMessage: {
    marginTop: 16,
    color: Colors.danger,
    textAlign: 'center',
  },
  errorButton: {
    marginTop: 16,
    width: '100%',
  },
});
