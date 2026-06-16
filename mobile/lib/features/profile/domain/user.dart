/// Current user profile returned by `GET /api/v1/me` (Doc 3).
class AppUser {
  final String id;
  final String firebaseUid;
  final String email;
  final String? displayName;
  final String? photoUrl;

  /// Account-wide money preference (3-letter code, e.g. "USD").
  final String currency;

  /// Account-wide distance display preference ("km" or "mi").
  final String distanceUnit;

  /// User-level toggle for reminder notifications.
  final bool renewalRemindersEnabled;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.firebaseUid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.currency = 'USD',
    this.distanceUnit = 'km',
    this.renewalRemindersEnabled = true,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      firebaseUid: json['firebaseUid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      currency: json['currency'] as String? ?? 'USD',
      distanceUnit: json['distanceUnit'] as String? ?? 'km',
      renewalRemindersEnabled: json['renewalRemindersEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
