import { useRouter } from 'expo-router';

import { VehicleFormScreen } from '@/features/vehicles/components/vehicle-form-screen';

export default function AddVehicleRoute() {
  const router = useRouter();
  return <VehicleFormScreen onDone={() => router.back()} />;
}
