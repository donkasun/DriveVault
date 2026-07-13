/**
 * Tab shell. Parity with Flutter `MainShell`: the tab bar floats above the
 * content (inset 24 on each side and from the bottom) and hides while the
 * keyboard is open so it never covers form fields.
 */

import { Tabs, usePathname, useRouter } from 'expo-router';
import { useCallback, useEffect, useState } from 'react';
import { Keyboard, Platform, StyleSheet, View, useWindowDimensions } from 'react-native';

import { FloatingTabBar, type TabKey } from '@/components/floating-tab-bar';
import { QuickAddSheet, type QuickAddAction } from '@/components/quick-add-sheet';
import { QuickFuelEntrySheet } from '@/features/fuel-logs/components/quick-fuel-entry-sheet';
import { QuickMaintenanceSheet } from '@/features/maintenance/components/quick-maintenance-sheet';
import { useVehicles } from '@/features/vehicles/hooks';

function activeTabFrom(pathname: string): TabKey {
  if (pathname.startsWith('/garage')) return 'garage';
  if (pathname.startsWith('/expenses')) return 'expenses';
  if (pathname.startsWith('/profile')) return 'profile';
  return 'home';
}

export default function TabsLayout() {
  const router = useRouter();
  const pathname = usePathname();
  const { width } = useWindowDimensions();

  const [quickAddOpen, setQuickAddOpen] = useState(false);
  const [keyboardOpen, setKeyboardOpen] = useState(false);
  const [quickFuelVehicleId, setQuickFuelVehicleId] = useState<string | undefined>(undefined);
  const [quickFuelOpen, setQuickFuelOpen] = useState(false);
  const [quickMaintenanceVehicleId, setQuickMaintenanceVehicleId] = useState<string | undefined>(undefined);
  const [quickMaintenanceOpen, setQuickMaintenanceOpen] = useState(false);

  const { data: vehicles, isLoading, error } = useVehicles();

  useEffect(() => {
    const showEvent = Platform.OS === 'ios' ? 'keyboardWillShow' : 'keyboardDidShow';
    const hideEvent = Platform.OS === 'ios' ? 'keyboardWillHide' : 'keyboardDidHide';

    const show = Keyboard.addListener(showEvent, () => setKeyboardOpen(true));
    const hide = Keyboard.addListener(hideEvent, () => setKeyboardOpen(false));
    return () => {
      show.remove();
      hide.remove();
    };
  }, []);

  const onSelect = useCallback(
    (key: TabKey) => {
      router.navigate(`/${key}`);
    },
    [router],
  );

  const onQuickAddSelect = useCallback(
    (action: QuickAddAction) => {
      setQuickAddOpen(false);

      const list = vehicles ?? [];
      const soleVehicleId = list.length === 1 ? list[0].id : null;

      switch (action) {
        case 'vehicle':
          router.push('/garage/add-vehicle');
          break;
        case 'document':
          // Exactly one vehicle → straight to upload. Otherwise send them to the
          // Garage to pick one (the upload screen has no vehicle picker).
          if (soleVehicleId) {
            router.push(`/garage/vehicle/${soleVehicleId}/documents/upload`);
          } else {
            router.navigate('/garage');
          }
          break;
        case 'fuel':
          setQuickFuelVehicleId(soleVehicleId ?? undefined);
          setQuickFuelOpen(true);
          break;
        case 'service':
          setQuickMaintenanceVehicleId(soleVehicleId ?? undefined);
          setQuickMaintenanceOpen(true);
          break;
      }
    },
    [router, vehicles],
  );

  return (
    <View style={styles.container}>
      <Tabs
        screenOptions={{ headerShown: false }}
        // The custom floating bar below replaces the default tab bar entirely.
        tabBar={() => null}
      >
        <Tabs.Screen name="home" />
        <Tabs.Screen name="garage" />
        <Tabs.Screen name="expenses" />
        <Tabs.Screen name="profile" />
      </Tabs>

      {!keyboardOpen && !quickAddOpen ? (
        <View style={[styles.tabBarSlot, { width: width - 48 }]} pointerEvents="box-none">
          <FloatingTabBar
            active={activeTabFrom(pathname)}
            onSelect={onSelect}
            onQuickAdd={() => setQuickAddOpen(true)}
          />
        </View>
      ) : null}

      <QuickAddSheet
        visible={quickAddOpen}
        onClose={() => setQuickAddOpen(false)}
        onSelect={onQuickAddSelect}
        hasVehicles={(vehicles?.length ?? 0) > 0}
        loading={isLoading}
        error={error ? String(error) : null}
      />

      <QuickFuelEntrySheet
        visible={quickFuelOpen}
        vehicleId={quickFuelVehicleId}
        onClose={() => setQuickFuelOpen(false)}
      />
      <QuickMaintenanceSheet
        visible={quickMaintenanceOpen}
        vehicleId={quickMaintenanceVehicleId}
        onClose={() => setQuickMaintenanceOpen(false)}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  tabBarSlot: {
    position: 'absolute',
    left: 24,
    bottom: 24,
  },
});
