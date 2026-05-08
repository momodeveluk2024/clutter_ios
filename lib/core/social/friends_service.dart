import '../api/api_client.dart';

/// Phase 6 social. Minimal client for /v1/friends and /v1/friends/requests.
/// Build leaderboards and shared progress on top of `list()`; do not model
/// groups or feeds in this layer.
class FriendsService {
  FriendsService({required ApiClient api}) : _api = api;
  final ApiClient _api;

  Future<List<Friend>> list() async {
    final response = await _api.get('/friends');
    return (response.data['friends'] as List? ?? const [])
        .map((v) => Friend.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  Future<void> sendRequest(String addresseeId) =>
      _api.post('/friends/requests', data: {'addressee_id': addresseeId});

  Future<void> respond(String friendshipId, {required bool accept}) =>
      _api.post(
        '/friends/requests/$friendshipId/respond',
        data: {'accept': accept},
      );
}

class Friend {
  Friend({required this.userId, required this.displayName, required this.since});
  final String userId;
  final String displayName;
  final DateTime since;
  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        since: DateTime.parse(json['since'] as String),
      );
}
