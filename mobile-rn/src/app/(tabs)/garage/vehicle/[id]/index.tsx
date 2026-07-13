import { useLocalSearchParams, useRouter } from 'expo-router';

import { VehicleDetailScreen } from '@/features/vehicles/components/vehicle-detail-screen';

export default function VehicleDetailRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();

  return (
    <VehicleDetailScreen
      vehicleId={id}
      onBack={() => router.back()}
      onEditVehicle={(vehicleId) => router.push(`/garage/edit-vehicle/${vehicleId}`)}
      onDeleted={() => router.replace('/garage')}
      onAddFuel={(vehicleId) => router.push(`/garage/vehicle/${vehicleId}/fuel-records`)}
      onViewMoreFuel={(vehicleId) => router.push(`/garage/vehicle/${vehicleId}/fuel-records`)}
      onAddService={(vehicleId) => router.push(`/garage/vehicle/${vehicleId}/maintenance/add`)}
      onOpenMaintenanceRecord={(vehicleId, record) =>
        router.push(`/garage/vehicle/${vehicleId}/maintenance/${record.id}`)
      }
      onUploadDocument={(vehicleId) => router.push(`/garage/vehicle/${vehicleId}/documents/upload`)}
      onOpenDocument={(vehicleId, doc) => router.push(`/garage/vehicle/${vehicleId}/documents/${doc.id}`)}
    />
  );
}
