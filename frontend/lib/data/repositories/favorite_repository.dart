import 'dart:async';
import '../../core/network/api_client.dart';

/// Stream broadcast toàn cục thông báo sự kiện thay đổi danh sách yêu thích (thêm / xoá)
final StreamController<void> _globalFavoritesChangedController =
    StreamController<void>.broadcast();

abstract class IFavoriteRepository {
  Future<List<int>> getFavoriteVenueIds({int? userId});
  Future<bool> toggleFavorite(int venueId, {int? userId});
  Stream<void> get onFavoritesChanged;
}

class MockFavoriteRepository implements IFavoriteRepository {
  static final Set<int> _favoriteIds = {1};

  static void reset() {
    _favoriteIds.clear();
    _favoriteIds.add(1);
    _globalFavoritesChangedController.add(null);
  }

  @override
  Stream<void> get onFavoritesChanged => _globalFavoritesChangedController.stream;

  @override
  Future<List<int>> getFavoriteVenueIds({int? userId}) async {
    return _favoriteIds.toList();
  }

  @override
  Future<bool> toggleFavorite(int venueId, {int? userId}) async {
    final bool isFav;
    if (_favoriteIds.contains(venueId)) {
      _favoriteIds.remove(venueId);
      isFav = false;
    } else {
      _favoriteIds.add(venueId);
      isFav = true;
    }
    _globalFavoritesChangedController.add(null);
    return isFav;
  }
}

class ApiFavoriteRepository implements IFavoriteRepository {
  final ApiClient _client;
  static final MockFavoriteRepository _fallback = MockFavoriteRepository();

  ApiFavoriteRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Stream<void> get onFavoritesChanged => _globalFavoritesChangedController.stream;

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
      final response = await _client.post('/api/favorites/$venueId/toggle$query', {}, requiresAuth: false);
      bool isFav;
      if (response is Map<String, dynamic> && response.containsKey('isFavorite')) {
        isFav = response['isFavorite'] as bool;
      } else {
        isFav = await _fallback.toggleFavorite(venueId, userId: userId);
      }
      _globalFavoritesChangedController.add(null);
      return isFav;
    } catch (_) {
      final isFav = await _fallback.toggleFavorite(venueId, userId: userId);
      _globalFavoritesChangedController.add(null);
      return isFav;
    }
  }
}
