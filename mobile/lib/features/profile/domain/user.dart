import '../../../shared/constants/currencies.dart';

/// Current user profile returned by `GET /api/v1/me` (Doc 3).
class AppUser {
  final String id;
  final String firebaseUid;
  final String email;
  final String? displayName;
  final String? photoUrl;

  /// Account-wide money preference (3-letter code, e.g. "LKR").
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
    this.currency = kFallbackCurrency,
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
      currency: json['currency'] as String? ?? kFallbackCurrency,
      distanceUnit: json['distanceUnit'] as String? ?? 'km',
      renewalRemindersEnabled: json['renewalRemindersEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firebaseUid': firebaseUid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'currency': currency,
        'distanceUnit': distanceUnit,
        'renewalRemindersEnabled': renewalRemindersEnabled,
        'createdAt': createdAt.toIso8601String(),
      };
}
