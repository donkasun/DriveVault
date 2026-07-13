import { useLocalSearchParams, useRouter } from 'expo-router';

import { MaintenanceFormScreen } from '@/features/maintenance/components/maintenance-form-screen';

export default function AddMaintenanceRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();

  return <MaintenanceFormScreen vehicleId={id} onDone={() => router.back()} />;
}
