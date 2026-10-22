import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../data/models/booking_model.dart';
import '../data/repositories/booking_repository.dart';
import '../widgets/recruitment_form.dart';

class BookingProvider extends ChangeNotifier {
  IBookingRepository _repository;

  BookingProvider({IBookingRepository? repository})
      : _repository = repository ?? RemoteBookingRepository() {
    initDates();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  VenueDetailModel? _venueDetail;
  VenueDetailModel? get venueDetail => _venueDetail;

  List<SubVenueModel> _subVenues = [];
  List<SubVenueModel> get subVenues => _subVenues;

  SubVenueModel? _selectedSubVenue;
  SubVenueModel? get selectedSubVenue => _selectedSubVenue;

  late List<DateTime> _dateRange;
  List<DateTime> get dateRange => _dateRange;

  late DateTime _selectedDate;
  DateTime get selectedDate => _selectedDate;

  List<VenueSlotModel> _slots = [];
  List<VenueSlotModel> get slots => _slots;

  final List<VenueSlotModel> _selectedSlots = [];
  List<VenueSlotModel> get selectedSlots => List.unmodifiable(_selectedSlots);

  // Map ServiceId -> Quantity
  final Map<int, int> _selectedServices = {};
  Map<int, int> get selectedServices => Map.unmodifiable(_selectedServices);

  int _depositPercentage = 100; // 30 or 100
  int get depositPercentage => _depositPercentage;

  RecruitmentValue _recruitment = const RecruitmentValue();
  RecruitmentValue get recruitment => _recruitment;

  // 5-minute hold timer
  Timer? _holdTimer;
  int _secondsRemaining = 300; // 5:00 minutes
  int get secondsRemaining => _secondsRemaining;
  String get formattedHoldTime {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void initDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _dateRange = List.generate(7, (i) => today.add(Duration(days: i)));
    _selectedDate = today;
  }

  Future<void> loadVenue(int venueId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _venueDetail = await _repository.getVenueDetail(venueId);
      _subVenues = _venueDetail?.subVenues ?? [];
      if (_subVenues.isNotEmpty) {
        _selectedSubVenue = _subVenues.first;
      }
      initDates();
      await _fetchSlots();
    } catch (e) {
      // Fallback to Mock if remote fails (e.g. offline dev)
      if (_repository is! MockBookingRepository) {
        _repository = MockBookingRepository();
        await loadVenue(venueId);
        return;
      }
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectSubVenue(SubVenueModel subVenue) {
    if (_selectedSubVenue?.id == subVenue.id) return;
    _selectedSubVenue = subVenue;
    _selectedSlots.clear();
    loadSlotsForCurrentDate();
  }

  void selectDate(DateTime date) {
    if (_selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day) {
      return;
    }
    _selectedDate = date;
    _selectedSlots.clear();
    loadSlotsForCurrentDate();
  }

  Future<void> loadSlotsForCurrentDate() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _fetchSlots();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchSlots() async {
    if (_venueDetail == null || _selectedSubVenue == null) return;
    try {
      _slots = await _repository.getSlots(
        _venueDetail!.id,
        _selectedSubVenue!.id,
        _selectedDate,
      );
    } catch (e) {
      // If remote fails, fallback mock
      if (_repository is! MockBookingRepository) {
        _repository = MockBookingRepository();
        _slots = await _repository.getSlots(
          _venueDetail!.id,
          _selectedSubVenue!.id,
          _selectedDate,
        );
      } else {
        rethrow;
      }
    }
  }

  /// Toggle slot with consecutive & max 3 slots rules
  /// Returns null on success, or an error string (e.g. for Toast/SnackBar)
  String? toggleSlot(VenueSlotModel slot) {
    if (!slot.isAvailable) {
      return 'Khung giờ này đã kín hoặc đã qua!';
    }

    // Check if already selected -> remove it
    if (_selectedSlots.any((s) => s.slotId == slot.slotId)) {
      _selectedSlots.removeWhere((s) => s.slotId == slot.slotId);
      // Re-sort
      _selectedSlots.sort((a, b) => a.startTime.compareTo(b.startTime));
      // Verify remaining slots are still contiguous
      if (!_areSlotsConsecutive(_selectedSlots)) {
        // If removing broke continuity, clear all to avoid disjoint state
        _selectedSlots.clear();
        _selectedSlots.add(slot);
        notifyListeners();
        return 'Đã chọn lại slot này (yêu cầu các khung giờ phải liên tiếp).';
      }
      notifyListeners();
      return null;
    }

    // Check maximum 3 slots (3 hours)
    if (_selectedSlots.length >= 3) {
      return 'Chỉ được chọn tối đa 3 slot (3 tiếng) cho một đơn đặt!';
    }

    // Check consecutive rule
    if (_selectedSlots.isNotEmpty) {
      final candidateList = List<VenueSlotModel>.from(_selectedSlots)..add(slot);
      candidateList.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (!_areSlotsConsecutive(candidateList)) {
        return 'Vui lòng chọn các khung giờ liên tiếp nhau!';
      }
      _selectedSlots.clear();
      _selectedSlots.addAll(candidateList);
    } else {
      _selectedSlots.add(slot);
    }

    notifyListeners();
    return null;
  }

  bool _areSlotsConsecutive(List<VenueSlotModel> slotList) {
    if (slotList.length <= 1) return true;
    for (int i = 0; i < slotList.length - 1; i++) {
      if (slotList[i].endTime != slotList[i + 1].startTime) {
        return false;
      }
    }
    return true;
  }

  void updateServiceQuantity(int serviceId, int delta) {
    final current = _selectedServices[serviceId] ?? 0;
    final next = current + delta;
    if (next <= 0) {
      _selectedServices.remove(serviceId);
    } else {
      _selectedServices[serviceId] = next;
    }
    notifyListeners();
  }

  void setDepositPercentage(int percentage) {
    _depositPercentage = percentage;
    notifyListeners();
  }

  void updateRecruitment(RecruitmentValue value) {
    _recruitment = value;
    notifyListeners();
  }

  // Price calculations
  int get courtPrice {
    return _selectedSlots.fold(0, (sum, s) => sum + s.price);
  }

  int get servicesPrice {
    if (_venueDetail == null) return 0;
    int total = 0;
    for (var entry in _selectedServices.entries) {
      final svc = _venueDetail!.services.firstWhere(
        (s) => s.id == entry.key,
        orElse: () => VenueServiceModel(id: 0, name: '', type: '', price: 0, stockQuantity: 0),
      );
      total += svc.price * entry.value;
    }
    return total;
  }

  int get totalPrice => courtPrice + servicesPrice;

  int get depositAmount {
    if (_depositPercentage >= 100) return totalPrice;
    return (totalPrice * 0.3).round();
  }

  int get remainingBalance => totalPrice - depositAmount;

  // 5-minute hold timer
  void startHoldTimer({VoidCallback? onExpire}) {
    cancelHoldTimer();
    _secondsRemaining = 300;
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        timer.cancel();
        if (onExpire != null) onExpire();
      }
    });
  }

  void cancelHoldTimer() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  /// Submit booking
  Future<BookingResultModel> submitBooking() async {
    if (_selectedSubVenue == null || _selectedSlots.isEmpty) {
      throw Exception('Vui lòng chọn sân và ít nhất 1 khung giờ!');
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final serviceRequests = _selectedServices.entries
        .map((e) => BookingServiceItemRequest(serviceId: e.key, quantity: e.value))
        .toList();

    final request = BookingRequestModel(
      subVenueId: _selectedSubVenue!.id,
      playDate: dateStr,
      slotIds: _selectedSlots.map((s) => s.slotId).toList(),
      services: serviceRequests,
      isOpenMatch: _recruitment.enabled,
      totalExpectedPlayers: _recruitment.enabled ? _recruitment.total : null,
      neededPlayers: _recruitment.enabled ? _recruitment.needed : null,
      skillLevel: _recruitment.enabled ? _recruitment.skill : 'Cơ bản',
      depositPercentage: _depositPercentage,
    );

    try {
      final result = await _repository.createBooking(request);
      cancelHoldTimer();
      // DO NOT clear _selectedSlots here, so the screen doesn't flicker behind the success dialog!
      return result;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // Reload slots on conflict so the user sees updated occupancy
        await loadSlotsForCurrentDate();
      }
      rethrow;
    }
  }

  void resetBookingState() {
    _selectedSlots.clear();
    _selectedServices.clear();
    _depositPercentage = 100;
    _recruitment = const RecruitmentValue();
    cancelHoldTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    cancelHoldTimer();
    super.dispose();
  }
}
