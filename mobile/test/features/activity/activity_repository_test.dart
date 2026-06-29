import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivevault/core/network/api_client.dart';
import 'package:drivevault/features/auth/data/auth_repository.dart';
import 'package:drivevault/features/activity/data/activity_provider.dart';
import 'package:drivevault/features/activity/data/activity_repository.dart';
import 'package:drivevault/features/activity/domain/activity_entry.dart';

ProviderContainer _makeContainer(List<Map<String, dynamic>> response) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: response),
        );
      },
    ),
  );
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(AuthRepository.testing()),
      apiClientProvider.overrideWith((ref) => ApiClient(ref, dio: dio)),
    ],
  );
}

List<Map<String, dynamic>> _sampleActivityResponse() => [
  {
    'type': 'fuel',
    'id': 'fuel-1',
    'vehicleId': 'v-1',
    'vehicleLabel': '2020 Toyota Hilux',
    'date': '2026-06-14',
    'amountCents': 7800,
    'label': 'Fuel',
    'currency': 'LKR',
    'createdAt': '2026-06-14T10:00:00Z',
    'liters': 30.5,
    'isFullTank': true,
    'odometer': 48100,
    'notes': null,
  },
  {
    'type': 'maintenance',
    'id': 'maint-1',
    'vehicleId': 'v-1',
    'vehicleLabel': '2020 Toyota Hilux',
    'date': '2026-06-10',
    'amountCents': 6500,
    'label': 'Oil Change',
    'currency': 'LKR',
    'createdAt': '2026-06-10T10:00:00Z',
    'odometer': 48000,
    'workshop': 'City Auto',
    'notes': null,
    'source': 'manual',
    'category': 'engine',
  },
  {
    'type': 'document',
    'id': 'doc-1',
    'vehicleId': 'v-1',
    'vehicleLabel': '2020 Toyota Hilux',
    'date': '2026-06-01',
    'amountCents': null,
    'label': 'Insurance Policy',
    'title': 'Insurance Policy',
    'currency': 'LKR',
    'createdAt': '2026-06-01T10:00:00Z',
    'docType': 'insurance',
    'storageUrl': 'https://example.com/doc.pdf',
    'storagePublicId': 'vehicles/doc-1',
    'mimeType': 'application/pdf',
    'fileSizeBytes': 12345,
    'issueDate': '2026-06-01',
    'expiryDate': '2026-12-31',
  },
];

class _FakeActivityRepository implements ActivityRepository {
  int calls = 0;
  final List<ActivityEntry> entries;

  _FakeActivityRepository(this.entries);

  @override
  Future<List<ActivityEntry>> fetchActivity({int limit = 50}) async {
    calls++;
    return entries;
  }
}

void main() {
  group('ActivityRepository', () {
    test('maps fuel, maintenance, and document rows', () async {
      final container = _makeContainer(_sampleActivityResponse());
      addTearDown(container.dispose);

      final entries = await container
          .read(activityRepositoryProvider)
          .fetchActivity();

      expect(entries.length, 3);
      expect(entries[0].kind, ActivityKind.fuel);
      expect(entries[0].expense!.fuelLog!.priceCents, 7800);
      expect(entries[1].kind, ActivityKind.maintenance);
      expect(entries[1].expense!.maintenanceRecord!.serviceType, 'Oil Change');
      expect(entries[2].kind, ActivityKind.document);
      expect(entries[2].document!.title, 'Insurance Policy');
      expect(entries[2].document!.mimeType, 'application/pdf');
    });

    test('allActivityProvider calls the repository once', () async {
      final fakeEntries = [
        ActivityEntry.fromApi(_sampleActivityResponse().first),
      ];
      final fakeRepo = _FakeActivityRepository(fakeEntries);

      final container = ProviderContainer(
        overrides: [activityRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      final entries = await container.read(allActivityProvider.future);

      expect(fakeRepo.calls, 1);
      expect(entries, hasLength(1));
      expect(entries.first.kind, ActivityKind.fuel);
    });
  });
}
