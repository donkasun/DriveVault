import { profileApi } from './api';
import { profileRepository } from './repository';
import type { AppUser } from './types';

jest.mock('./api', () => ({
  profileApi: {
    getMe: jest.fn(),
    updateMe: jest.fn(),
  },
}));

const mockApi = profileApi as jest.Mocked<typeof profileApi>;

const USER: AppUser = {
  id: 'u1',
  firebaseUid: 'fb1',
  email: 'a@b.com',
  displayName: 'CR Test',
  photoUrl: null,
  currency: 'LKR',
  distanceUnit: 'km',
  renewalRemindersEnabled: true,
  createdAt: '2026-01-01T00:00:00Z',
};

beforeEach(() => {
  jest.clearAllMocks();
});

describe('profileRepository.getMe', () => {
  it('returns the user from the API', async () => {
    mockApi.getMe.mockResolvedValue(USER);
    await expect(profileRepository.getMe()).resolves.toEqual(USER);
  });
});

describe('profileRepository.updateMe', () => {
  it('sends only the fields provided', async () => {
    mockApi.updateMe.mockResolvedValue({ ...USER, displayName: 'New Name' });

    await profileRepository.updateMe({ displayName: 'New Name' });

    expect(mockApi.updateMe).toHaveBeenCalledWith({ displayName: 'New Name' });
  });

  it('drops undefined fields so PATCH never clears untouched values', async () => {
    mockApi.updateMe.mockResolvedValue(USER);

    await profileRepository.updateMe({
      displayName: undefined,
      distanceUnit: 'mi',
      currency: undefined,
    });

    expect(mockApi.updateMe).toHaveBeenCalledWith({ distanceUnit: 'mi' });
  });

  it('preserves an explicit false (does not treat it as absent)', async () => {
    mockApi.updateMe.mockResolvedValue({ ...USER, renewalRemindersEnabled: false });

    await profileRepository.updateMe({ renewalRemindersEnabled: false });

    expect(mockApi.updateMe).toHaveBeenCalledWith({ renewalRemindersEnabled: false });
  });

  it('returns the updated user', async () => {
    const updated = { ...USER, distanceUnit: 'mi' as const };
    mockApi.updateMe.mockResolvedValue(updated);

    await expect(profileRepository.updateMe({ distanceUnit: 'mi' })).resolves.toEqual(updated);
  });
});
