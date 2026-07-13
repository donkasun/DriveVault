import { useLocalSearchParams, useRouter } from 'expo-router';

import { DocumentUploadScreen } from '@/features/documents/components/document-upload-screen';

export default function UploadDocumentRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();

  return <DocumentUploadScreen vehicleId={id} onDone={() => router.back()} />;
}
