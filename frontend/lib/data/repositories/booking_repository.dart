import '../models/booking_model.dart';

abstract class BookingRepository {
  Future<List<TimeSlotModel>> getSlots(int venueId, int subVenueId, DateTime date);
  Future<List<ServiceItemModel>> getServices(int venueId);
  Future<BookingResponseModel> createBooking(BookingRequestModel request);
}
