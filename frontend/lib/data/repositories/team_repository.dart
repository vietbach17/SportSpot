import '../../core/network/api_client.dart';
import '../models/team_model.dart';

class TeamRepository {
  final ApiClient client;
  TeamRepository({ApiClient? client}) : client = client ?? ApiClient();
  Future<List<FootballTeam>> myTeams() async =>
      ((await client.get('/api/teams/mine')) as List)
          .map((j) => FootballTeam.fromJson(j))
          .toList();
  Future<List<TeamChallenge>> challenges({bool mine = false}) async =>
      ((await client.get(
        '/api/teams/challenges${mine ? '/mine' : ''}',
      )) as List).map((j) => TeamChallenge.fromJson(j)).toList();
  Future<void> createTeam(String name, int size, String level) async =>
      client.post('/api/teams', {
        'name': name,
        'teamSize': size,
        'skillLevel': level,
      });
  Future<void> open(int teamId, int bookingId, String note) async =>
      client.post('/api/teams/challenges', {
        'teamId': teamId,
        'bookingId': bookingId,
        'note': note,
      });
  Future<void> apply(int id, int teamId, String message) async => client.post(
    '/api/teams/challenges/$id/apply',
    {'teamId': teamId, 'message': message},
  );
  Future<void> action(
    int id,
    String action, {
    int? requestId,
  }) async => client.post(
    '/api/teams/challenges/$id/${requestId == null ? '' : 'requests/$requestId/'}$action',
    {},
  );
  Future<List<Map<String, dynamic>>> bookings(int userId) async =>
      ((await client.get('/api/bookings/my-bookings/$userId')) as List)
          .cast<Map<String, dynamic>>()
          .where(
            (b) =>
                b['status'] == 'Upcoming' &&
                b['sportName'].toString().contains('Bóng đá') &&
                b['userRoleInMatch'] == 'Host' &&
                b['matchId'] == null,
          )
          .toList();
}
