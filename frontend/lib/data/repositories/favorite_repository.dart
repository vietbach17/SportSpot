import '../../core/network/api_client.dart';

abstract class IFavoriteRepository {
  Future<List<int>> getFavoriteVenueIds({int? userId});
  Future<bool> toggleFavorite(int venueId, {int? userId});
}

class MockFavoriteRepository implements IFavoriteRepository {
  final Set<int> _favoriteIds = {1};

  @override
  Future<List<int>> getFavoriteVenueIds({int? userId}) async {
    return _favoriteIds.toList();
  }

  @override
  Future<bool> toggleFavorite(int venueId, {int? userId}) async {
    if (_favoriteIds.contains(venueId)) {
      _favoriteIds.remove(venueId);
      return false;
    } else {
      _favoriteIds.add(venueId);
      return true;
    }
  }
}

class ApiFavoriteRepository implements IFavoriteRepository {
  final ApiClient _client;
  final MockFavoriteRepository _fallback = MockFavoriteRepository();

  ApiFavoriteRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<List<int>> getFavoriteVenueIds({int? userId}) async {
    try {
      final query = userId != null ? '?userId=$userId' : '';
      final response = await _client.get('/api/favorites$query', requiresAuth: false);
      if (response is List) {
        return response.map((e) => (e as num).toInt()).toList();
      }
      return await _fallback.getFavoriteVenueIds(userId: userId);
    } catch (_) {
      return await _fallback.getFavoriteVenueIds(userId: userId);
    }
  }

  @override
  Future<bool> toggleFavorite(int venueId, {int? userId}) async {
    try {
      final query = userId != null ? '?userId=$userId' : '';
      final response = await _client.post('/api/favorites/$venueId/toggle$query', {});
      if (response is Map<String, dynamic> && response.containsKey('isFavorite')) {
        return response['isFavorite'] as bool;
      }
      return await _fallback.toggleFavorite(venueId, userId: userId);
    } catch (_) {
      return await _fallback.toggleFavorite(venueId, userId: userId);
    }
  }
}
