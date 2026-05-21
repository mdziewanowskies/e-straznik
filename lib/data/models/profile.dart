class Profile {
  final String id;
  final String organizationId;
  final String email;
  final String? fullName;
  final Map<String, dynamic> notificationPrefs;

  const Profile({
    required this.id,
    required this.organizationId,
    required this.email,
    this.fullName,
    this.notificationPrefs = const {},
  });

  /// Struktura w bazie: `{"channels": {"push": {"enabled": true}, "email": {"enabled": true}}}`.
  /// Patrz `docs/mobile_push_integration.md`.
  bool get pushEnabled => _channelEnabled('push');
  bool get emailEnabled => _channelEnabled('email');

  bool _channelEnabled(String channel) {
    final channels = notificationPrefs['channels'];
    if (channels is! Map) return false;
    final ch = channels[channel];
    if (ch is! Map) return false;
    return ch['enabled'] == true;
  }

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        email: json['email'] as String? ?? '',
        fullName: json['full_name'] as String?,
        notificationPrefs:
            (json['notification_prefs'] as Map?)?.cast<String, dynamic>() ??
                const {},
      );
}

class Organization {
  final String id;
  final String name;
  final String? subscriptionStatus;

  const Organization({
    required this.id,
    required this.name,
    this.subscriptionStatus,
  });

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        subscriptionStatus: json['subscription_status'] as String?,
      );
}
