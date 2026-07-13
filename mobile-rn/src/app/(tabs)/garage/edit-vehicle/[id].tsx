import { useLocalSearchParams, useRouter } from 'expo-router';

import { VehicleFormScreen } from '@/features/vehicles/components/vehicle-form-screen';

export default function EditVehicleRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  return <VehicleFormScreen vehicleId={id} onDone={() => router.back()} />;
}
