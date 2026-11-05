class ManagedVenue {
  final int id, basePrice, peakPrice;
  final String name;
  ManagedVenue.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      name = j['name'],
      basePrice = j['basePrice'],
      peakPrice = j['peakPrice'];
}

class ScheduleCourt {
  final int id;
  final String name;
  final bool isActive;
  ScheduleCourt.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      name = j['name'],
      isActive = j['isActive'];
}

class ScheduleSlot {
  final int id;
  final String startTime, endTime;
  final bool isPeak;
  ScheduleSlot.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      startTime = j['startTime'],
      endTime = j['endTime'],
      isPeak = j['isPeak'];
}

class ScheduleBooking {
  final int id, subVenueId, totalPrice, collectedAmount, remainingBalance;
  final String code, playDate, type, status, customerName, customerPhone, note;
  final List<int> slotIds;
  bool get isMaintenance => type == 'Maintenance';
  bool get isManaged => isMaintenance || type == 'WalkIn';
  ScheduleBooking.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      subVenueId = j['subVenueId'],
      totalPrice = j['totalPrice'],
      collectedAmount = j['collectedAmount'],
      remainingBalance = j['remainingBalance'],
      code = j['code'],
      playDate = j['playDate'],
      type = j['type'],
      status = j['status'],
      customerName = j['customerName'],
      customerPhone = j['customerPhone'],
      note = j['note'],
      slotIds = List<int>.from(j['slotIds']);
}

class OwnerSchedule {
  final ManagedVenue venue;
  final List<ScheduleCourt> courts;
  final List<ScheduleSlot> slots;
  final List<ScheduleBooking> bookings;
  OwnerSchedule.fromJson(Map<String, dynamic> j)
    : venue = ManagedVenue.fromJson(j['venue']),
      courts = (j['courts'] as List)
          .map((v) => ScheduleCourt.fromJson(v))
          .toList(),
      slots = (j['slots'] as List)
          .map((v) => ScheduleSlot.fromJson(v))
          .toList(),
      bookings = (j['bookings'] as List)
          .map((v) => ScheduleBooking.fromJson(v))
          .toList();
}
