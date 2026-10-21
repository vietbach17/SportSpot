import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/booking_model.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/remote_booking_repository.dart';

class SubVenueItem {
  final int id;
  final String name;
  const SubVenueItem({required this.id, required this.name});
}

class BookingProvider extends ChangeNotifier {
  final BookingRepository _repository;

  BookingProvider({BookingRepository? repository})
      : _repository = repository ?? RemoteBookingRepository() {
    _initUpcomingDays();
    loadSlots();
    loadServices();
  }

  // 1. Quản lý thông tin sân
  int _venueId = 1;
  int _subVenueId = 1;
  String _venueName = 'CLB Cầu Lông Cầu Giấy';
  String _subVenueName = 'Sân Thảm 1';
  String _sportName = 'Cầu lông';
  String _address = 'Số 35 Trần Quý Kiên, Dịch Vọng, Cầu Giấy, Hà Nội';

  List<SubVenueItem> _availableSubVenues = [
    const SubVenueItem(id: 1, name: 'Sân Thảm 1'),
    const SubVenueItem(id: 2, name: 'Sân Thảm 2'),
    const SubVenueItem(id: 3, name: 'Sân Thảm 3'),
  ];

  int get venueId => _venueId;
  int get subVenueId => _subVenueId;
  String get venueName => _venueName;
  String get subVenueName => _subVenueName;
  String get sportName => _sportName;
  String get address => _address;
  List<SubVenueItem> get availableSubVenues => _availableSubVenues;

  void setVenueInfo({
    required int venueId,
    required int subVenueId,
    required String venueName,
    required String subVenueName,
    required String sportName,
    required String address,
    List<SubVenueItem>? subVenues,
  }) {
    _venueId = venueId;
    _subVenueId = subVenueId;
    _venueName = venueName;
    _subVenueName = subVenueName;
    _sportName = sportName;
    _address = address;

    if (subVenues != null && subVenues.isNotEmpty) {
      _availableSubVenues = subVenues;
    } else if (venueId == 2) {
      _availableSubVenues = [
        const SubVenueItem(id: 4, name: 'Sân Cỏ 7A'),
        const SubVenueItem(id: 5, name: 'Sân Cỏ 7B'),
      ];
    } else {
      _availableSubVenues = [
        const SubVenueItem(id: 1, name: 'Sân Thảm 1'),
        const SubVenueItem(id: 2, name: 'Sân Thảm 2'),
        const SubVenueItem(id: 3, name: 'Sân Thảm 3'),
      ];
    }

    _selectedSlots.clear();
    loadSlots();
    loadServices();
    notifyListeners();
  }

  void switchSubVenue(int newSubVenueId, String newSubVenueName) {
    if (_subVenueId == newSubVenueId) return;
    _subVenueId = newSubVenueId;
    _subVenueName = newSubVenueName;
    _selectedSlots.clear();
    loadSlots();
    notifyListeners();
  }

  // 2. Quản lý ngày thi đấu (7 ngày tới: T đến T+6)
  late List<DateTime> _upcomingDays;
  late DateTime _selectedDate;

  List<DateTime> get upcomingDays => _upcomingDays;
  DateTime get selectedDate => _selectedDate;

  void _initUpcomingDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _upcomingDays = List.generate(7, (index) => today.add(Duration(days: index)));
    _selectedDate = today;
  }

  void selectDate(DateTime date) {
    if (_selectedDate == date) return;
    _selectedDate = date;
    _selectedSlots.clear();
    loadSlots();
    notifyListeners();
  }

  // 3. Quản lý danh sách TimeSlots & Lựa chọn (Consecutive Slot Rule)
  List<TimeSlotModel> _slots = [];
  final List<TimeSlotModel> _selectedSlots = [];
  bool _isLoadingSlots = false;

  List<TimeSlotModel> get slots => _slots;
  List<TimeSlotModel> get selectedSlots => List.unmodifiable(_selectedSlots);
  bool get isLoadingSlots => _isLoadingSlots;

  Future<void> loadSlots() async {
    _isLoadingSlots = true;
    notifyListeners();

    try {
      _slots = await _repository.getSlots(_venueId, _subVenueId, _selectedDate);
    } catch (e) {
      debugPrint('[BookingProvider] loadSlots error: $e');
    } finally {
      _isLoadingSlots = false;
      notifyListeners();
    }
  }

  /// Chọn hoặc bỏ chọn một slot.
  /// Kiểm tra các quy tắc nghiệp vụ:
  /// - Tối đa 3 slot (F06)
  /// - Phải liền kề nhau về thời gian (Consecutive Rule - F07)
  /// Trả về null nếu hợp lệ, hoặc chuỗi cảnh báo nếu vi phạm quy tắc.
  String? toggleSlot(TimeSlotModel slot) {
    if (!slot.isAvailable) {
      return 'Khung giờ này không khả dụng hoặc đã có người đặt!';
    }

    // Nếu đã chọn rồi -> cho phép bỏ chọn
    final existingIndex = _selectedSlots.indexWhere((s) => s.slotId == slot.slotId);
    if (existingIndex != -1) {
      _selectedSlots.removeAt(existingIndex);
      notifyListeners();
      return null;
    }

    // Kiểm tra giới hạn 3 slot
    if (_selectedSlots.length >= 3) {
      return 'Chỉ được chọn tối đa 3 khung giờ (3 tiếng) cho mỗi lượt đặt!';
    }

    // Nếu là slot đầu tiên -> chọn ngay
    if (_selectedSlots.isEmpty) {
      _selectedSlots.add(slot);
      notifyListeners();
      return null;
    }

    // Nếu đã có slot được chọn -> kiểm tra tính liền kề (Consecutive Rule)
    final tempSlots = List<TimeSlotModel>.from(_selectedSlots)..add(slot);
    tempSlots.sort((a, b) => a.slotId.compareTo(b.slotId));

    for (int i = 0; i < tempSlots.length - 1; i++) {
      if (tempSlots[i + 1].slotId - tempSlots[i].slotId != 1) {
        return 'Vui lòng chọn các khung giờ liền kề nhau!';
      }
    }

    _selectedSlots.clear();
    _selectedSlots.addAll(tempSlots);
    notifyListeners();
    return null;
  }

  void clearSelectedSlots() {
    _selectedSlots.clear();
    notifyListeners();
  }

  // 4. Quản lý phụ kiện & Dịch vụ đi kèm (F12)
  List<ServiceItemModel> _services = [];
  bool _isLoadingServices = false;

  List<ServiceItemModel> get services => _services;
  bool get isLoadingServices => _isLoadingServices;

  Future<void> loadServices() async {
    _isLoadingServices = true;
    notifyListeners();

    try {
      _services = await _repository.getServices(_venueId);
    } catch (e) {
      debugPrint('[BookingProvider] loadServices error: $e');
    } finally {
      _isLoadingServices = false;
      notifyListeners();
    }
  }

  void updateServiceQuantity(int serviceId, int delta) {
    final index = _services.indexWhere((s) => s.serviceId == serviceId);
    if (index != -1) {
      final current = _services[index];
      final newQty = (current.quantity + delta).clamp(0, 99);
      _services[index] = current.copyWith(quantity: newQty);
      notifyListeners();
    }
  }

  // 5. Tính toán chi phí
  int get courtPrice => _selectedSlots.fold(0, (sum, item) => sum + item.price);

  int get servicesPrice => _services.fold(0, (sum, item) => sum + item.itemTotalPrice);

  int get totalPrice => courtPrice + servicesPrice;

  int _depositPercentage = 100; // 30% hoặc 100%
  int get depositPercentage => _depositPercentage;

  void setDepositPercentage(int percent) {
    _depositPercentage = percent;
    notifyListeners();
  }

  int get depositAmount {
    if (_depositPercentage >= 100) return totalPrice;
    return (totalPrice * 0.3).round();
  }

  int get remainingBalance => totalPrice - depositAmount;

  // 6. Ghép kèo / Tuyển vãng lai (Module 4 preparation)
  bool _isOpenMatch = false;
  int _totalExpectedPlayers = 10;
  int _neededPlayers = 4;

  bool get isOpenMatch => _isOpenMatch;
  int get totalExpectedPlayers => _totalExpectedPlayers;
  int get neededPlayers => _neededPlayers;

  void toggleOpenMatch(bool value) {
    _isOpenMatch = value;
    notifyListeners();
  }

  void updateOpenMatchSettings({int? totalPlayers, int? needed}) {
    if (totalPlayers != null) _totalExpectedPlayers = totalPlayers;
    if (needed != null) _neededPlayers = needed;
    notifyListeners();
  }

  int get costPerPerson {
    if (_totalExpectedPlayers <= 0) return 0;
    return (courtPrice / _totalExpectedPlayers).round();
  }

  // 7. Đồng hồ đếm ngược giữ chỗ (Hold Timer - 5 phút = 300s)
  Timer? _holdTimer;
  int _holdSecondsLeft = 300;
  bool _isHoldExpired = false;

  int get holdSecondsLeft => _holdSecondsLeft;
  bool get isHoldExpired => _isHoldExpired;

  String get formattedHoldTimer {
    final minutes = (_holdSecondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_holdSecondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void startHoldTimer({VoidCallback? onExpired}) {
    _holdTimer?.cancel();
    _holdSecondsLeft = 300;
    _isHoldExpired = false;
    notifyListeners();

    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_holdSecondsLeft > 0) {
        _holdSecondsLeft--;
        notifyListeners();
      } else {
        _isHoldExpired = true;
        _holdTimer?.cancel();
        _selectedSlots.clear();
        notifyListeners();
        if (onExpired != null) {
          onExpired();
        }
      }
    });
  }

  void stopHoldTimer() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  // 8. Đặt sân (Submit Booking)
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  Future<BookingResponseModel?> submitBooking() async {
    if (_selectedSlots.isEmpty) return null;

    _isSubmitting = true;
    notifyListeners();

    try {
      final request = BookingRequestModel(
        subVenueId: _subVenueId,
        playDate: _selectedDate,
        slotIds: _selectedSlots.map((s) => s.slotId).toList(),
        services: _services.where((s) => s.quantity > 0).toList(),
        isOpenMatch: _isOpenMatch,
        totalExpectedPlayers: _isOpenMatch ? _totalExpectedPlayers : null,
        neededPlayers: _isOpenMatch ? _neededPlayers : null,
        depositPercentage: _depositPercentage,
        paymentGateway: 'MockPayment',
      );

      final response = await _repository.createBooking(request);
      stopHoldTimer();
      _isSubmitting = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      rethrow;
    }
  }

  void resetBookingState() {
    _selectedSlots.clear();
    _services = _services.map((s) => s.copyWith(quantity: 0)).toList();
    _isOpenMatch = false;
    _depositPercentage = 100;
    notifyListeners();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }
}
