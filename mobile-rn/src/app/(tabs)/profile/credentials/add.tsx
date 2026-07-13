import { useRouter } from 'expo-router';

import { DrivingCredentialFormScreen } from '@/features/driving-credentials/components/driving-credential-form-screen';

export default function AddCredentialRoute() {
  const router = useRouter();
  return <DrivingCredentialFormScreen onDone={() => router.back()} />;
}
