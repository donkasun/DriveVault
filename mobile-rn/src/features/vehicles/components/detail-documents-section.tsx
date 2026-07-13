/**
 * Documents section: header, docsStatus banner, and doc list. Parity with
 * Flutter `vehicle_detail_screen.dart` `_DocumentsSection` / `_DocsStatusBanner`
 * / `_DocumentCard` (lines 1115-1349).
 */

import Ionicons from '@expo/vector-icons/Ionicons';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { StatusPill, renewalStatusPill } from '@/components/status-pill';
import { Colors, Radii, cardShadow } from '@/constants/theme';
import { useDocuments } from '@/features/documents/hooks';
import type { Document } from '@/features/documents/types';
import type { DocsStatus } from '../types';
import {
  documentExpirySubLabel,
  documentIconKey,
  documentRenewalStatus,
  sortDocumentsByExpiry,
  type DocumentIconKey,
} from '../vehicle-detail-helpers';
import { DetailEmptyCard } from './detail-empty-card';
import { DetailSectionHeader } from './detail-section-header';

/** docType → (icon, bg, fg). One-off literals, Dart `_DocumentCard._iconStyle` (lines 1242-1261). */
const ICON_STYLE: Record<DocumentIconKey, { icon: React.ComponentProps<typeof Ionicons>['name']; bg: string; fg: string }> = {
  insurance: { icon: 'shield-outline', bg: '#FCF1DC', fg: '#B45309' },
  revenue_license: { icon: 'receipt-outline', bg: '#FCEBEB', fg: '#DC2626' },
  emission_test: { icon: 'flask-outline', bg: '#E8F1FD', fg: '#2563EB' },
  default: { icon: 'document-text-outline', bg: Colors.divider, fg: Colors.textMuted },
};

const dayMonthFmt = new Intl.DateTimeFormat('en-GB', { day: 'numeric', month: 'short' });

type Props = {
  vehicleId: string;
  docsStatus: DocsStatus;
  onUpload: () => void;
  onOpenDocument: (doc: Document) => void;
};

export function DetailDocumentsSection({ vehicleId, docsStatus, onUpload, onOpenDocument }: Props) {
  const { data: docs, isLoading, error } = useDocuments(vehicleId);
  const sorted = docs ? sortDocumentsByExpiry(docs) : [];

  return (
    <View>
      <DetailSectionHeader
        title="Documents"
        count={docs ? docs.length : null}
        buttonLabel="Upload"
        onAdd={onUpload}
      />

      <DocsStatusBanner docsStatus={docsStatus} />

      {isLoading ? null : error ? (
        <Text style={styles.error}>Error: {String(error)}</Text>
      ) : sorted.length === 0 ? (
        <DetailEmptyCard label="No documents yet." />
      ) : (
        sorted.map((doc) => (
          <DocumentRow key={doc.id} doc={doc} onPress={() => onOpenDocument(doc)} />
        ))
      )}
    </View>
  );
}

function DocsStatusBanner({ docsStatus }: { docsStatus: DocsStatus }) {
  let icon: React.ComponentProps<typeof Ionicons>['name'];
  let label: string;
  let iconColor: string;
  let bgColor: string;

  if (docsStatus.state === 'valid') {
    icon = 'checkmark-circle-outline';
    label = 'All Good';
    iconColor = Colors.success;
    bgColor = Colors.successBg;
  } else if (docsStatus.state === 'needs_action') {
    icon = 'warning-outline';
    label = `${docsStatus.needsActionCount} ${docsStatus.needsActionCount === 1 ? 'doc' : 'docs'} need attention`;
    iconColor = '#B45309';
    bgColor = '#FCF1DC';
  } else {
    icon = 'information-circle-outline';
    label = 'No documents';
    iconColor = Colors.textMuted;
    bgColor = Colors.divider;
  }

  return (
    <View style={[styles.banner, { backgroundColor: bgColor }]}>
      <Ionicons name={icon} size={16} color={iconColor} />
      <Text style={[styles.bannerLabel, { color: iconColor }]}>{label}</Text>
    </View>
  );
}

function DocumentRow({ doc, onPress }: { doc: Document; onPress: () => void }) {
  const style = ICON_STYLE[documentIconKey(doc.docType)];
  const subLabel = documentExpirySubLabel(doc.expiryDate, (d) => dayMonthFmt.format(d));
  const renewal = documentRenewalStatus(doc.expiryDate);
  const pill = renewal ? renewalStatusPill(renewal.status, renewal.daysRemaining) : null;

  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={styles.row}>
      <View style={[styles.rowIcon, { backgroundColor: style.bg }]}>
        <Ionicons name={style.icon} size={20} color={style.fg} />
      </View>
      <View style={styles.rowBody}>
        <Text style={styles.rowTitle} numberOfLines={1}>
          {doc.title}
        </Text>
        <Text style={styles.rowSubtitle} numberOfLines={1}>
          {subLabel}
        </Text>
      </View>
      {pill ? (
        <View style={styles.pillWrap}>
          <StatusPill {...pill} />
        </View>
      ) : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  error: {
    marginHorizontal: 16,
    color: Colors.danger,
  },
  banner: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    marginHorizontal: 16,
    marginBottom: 10,
    paddingHorizontal: 12,
    paddingVertical: 9,
    borderRadius: 12,
  },
  bannerLabel: {
    marginLeft: 7,
    fontSize: 13,
    fontWeight: '600',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    marginHorizontal: 16,
    marginBottom: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
    backgroundColor: Colors.surface,
    borderRadius: Radii.card,
    ...cardShadow,
  },
  rowIcon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rowBody: {
    flex: 1,
    marginLeft: 13,
  },
  rowTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: Colors.textPrimary,
  },
  rowSubtitle: {
    marginTop: 1,
    fontSize: 12.5,
    fontWeight: '500',
    color: Colors.textMuted,
  },
  pillWrap: {
    marginLeft: 8,
  },
});
