import { useRouter } from 'expo-router';

import { EditProfileScreen } from '@/features/profile/components/edit-profile-screen';

export default function EditProfileRoute() {
  const router = useRouter();
  return <EditProfileScreen onDone={() => router.back()} />;
}
