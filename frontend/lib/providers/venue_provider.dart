import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/venue_model.dart';
import '../data/repositories/venue_repository.dart';

class VenueProvider extends ChangeNotifier {
  final VenueRepository _repository = VenueRepository();

  List<VenueItemModel> _venues = [];
  List<SportCategoryModel> _sports = [];
  int? _selectedSportId;
  double _radiusKm = 15.0; // Mặc định quét bán kính 15km
  String _searchKeyword = '';
  Timer? _debounceTimer;

  // Tọa độ người dùng mặc định: TP. Thủ Đức, TP.HCM
  double _userLat = 10.8498;
  double _userLng = 106.7720;
  String _currentLocationName = 'TP. Thủ Đức, TP.HCM';

  bool _isLoading = false;
  String? _errorMessage;

  List<VenueItemModel> get venues => _venues;
  List<SportCategoryModel> get sports => _sports;
  int? get selectedSportId => _selectedSportId;
  double get radiusKm => _radiusKm;
  String get searchKeyword => _searchKeyword;
  double get userLat => _userLat;
  double get userLng => _userLng;
  String get currentLocationName => _currentLocationName;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  VenueProvider() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sports = await _repository.getSports();
      await _fetchVenues();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchVenues() async {
    _venues = await _repository.getVenues(
      sportId: _selectedSportId,
      search: _searchKeyword,
      userLat: _userLat,
      userLng: _userLng,
      radiusKm: _radiusKm,
    );
  }

  void selectSport(int? sportId) {
    if (_selectedSportId == sportId) {
      _selectedSportId = null; // Bấm lại để bỏ chọn, xem tất cả
    } else {
      _selectedSportId = sportId;
    }
    notifyListeners();
    refreshVenues();
  }

  void setRadius(double km) {
    _radiusKm = km;
    notifyListeners();
    refreshVenues();
  }

  /// Debounce 400ms: Ngừng gõ 400ms mới kích hoạt gọi API lọc tìm kiếm
  void onSearchChanged(String query) {
    _searchKeyword = query;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      refreshVenues();
    });
  }

  Future<void> refreshVenues() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _fetchVenues();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<VenueItemModel> getVenueDetail(int id) async {
    return await _repository.getVenueDetail(id);
  }

  void updateLocation(double lat, double lng, String name) {
    _userLat = lat;
    _userLng = lng;
    _currentLocationName = name;
    notifyListeners();
    refreshVenues();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
