import '../../core/network/api_client.dart';
import '../models/booking_model.dart';
import '../models/owner_schedule_model.dart';
import '../models/venue_config_models.dart';

abstract class IVenueConfigRepository {
  Future<List<Map<String, dynamic>>> getSports();
  // --- Venue Applications ---
  Future<List<VenueSlotConfigItemModel>> getSlotTemplates();
  Future<List<VenueApplicationModel>> getMyApplications();
  Future<List<UploadedVenueImageModel>> getUnusedImages();
  Future<UploadedVenueImageModel> uploadVenueImage(List<int> bytes, String filename);
  Future<VenueApplicationModel> submitVenueApplication(Map<String, dynamic> body, {int? id});

  // --- Owner Configuration ---
  Future<List<ManagedVenue>> getManagedVenues();
  Future<OwnerVenueConfigModel> getOwnerVenueConfig(int venueId);
  Future<OwnerVenueConfigModel> updateOwnerVenueInfo(int venueId, Map<String, dynamic> body);
  Future<OwnerVenueConfigModel> updateOwnerSlotConfig(int venueId, Map<String, dynamic> body);
  Future<SubVenueModel> addSubVenue(int venueId, String name, {bool isActive = true});
  Future<SubVenueModel> updateSubVenue(int subVenueId, String name, bool isActive);
  Future<void> deleteSubVenue(int subVenueId);
  Future<VenueServiceModel> addVenueService(int venueId, Map<String, dynamic> body);
  Future<VenueServiceModel> updateVenueService(int serviceId, Map<String, dynamic> body);
  Future<void> deleteVenueService(int serviceId);
  Future<VenueStaffMemberModel> assignVenueStaff(int venueId, String identifier);
  Future<void> removeVenueStaff(int venueId, int staffUserId);

  // --- Admin Hub ---
  Future<AdminOverviewModel> getAdminOverview();
  Future<List<VenueApplicationModel>> getAdminVenues();
  Future<VenueApplicationModel> reviewVenue(int venueId, {required bool approve, required int revision, String reason = ''});
  Future<bool> setVenueActive(int venueId, bool isActive);
  Future<List<AdminUserModel>> getAdminUsers();
  Future<bool> setUserActive(int userId, bool isActive);
  Future<AdminUserModel> assignUserRoleAndVenue(int userId, {required String role, int? venueId});
}

class ApiVenueConfigRepository implements IVenueConfigRepository {
  final ApiClient _api;
  ApiVenueConfigRepository([ApiClient? api]) : _api = api ?? ApiClient();

  @override
  Future<List<Map<String, dynamic>>> getSports() async {
    final res = await _api.get('/api/sports', requiresAuth: false);
    return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static List<VenueSlotConfigItemModel> defaultSlotTemplates() {
    const raw = [
      (14, '05:00', '06:00', false, false),
      (1, '06:00', '07:00', true, false),
      (2, '07:00', '08:00', true, false),
      (3, '08:00', '09:00', true, false),
      (4, '09:00', '10:00', true, false),
      (5, '10:00', '11:00', true, false),
      (15, '11:00', '12:00', false, false),
      (16, '12:00', '13:00', false, false),
      (17, '13:00', '14:00', false, false),
      (6, '14:00', '15:00', true, false),
      (7, '15:00', '16:00', true, false),
      (8, '16:00', '17:00', true, false),
      (9, '17:00', '18:00', true, true),
      (10, '18:00', '19:00', true, true),
      (11, '19:00', '20:00', true, true),
      (12, '20:00', '21:00', true, true),
      (13, '21:00', '22:00', true, true),
      (18, '22:00', '23:00', false, true),
      (19, '23:00', '23:59', false, true),
    ];
    return raw
        .map(
          (r) => VenueSlotConfigItemModel(
            slotId: r.$1,
            startTime: r.$2,
            endTime: r.$3,
            isActive: r.$4,
            isPeak: r.$5,
            effectivePrice: r.$5 ? 150000 : 100000,
          ),
        )
        .toList();
  }

  @override
  Future<List<VenueSlotConfigItemModel>> getSlotTemplates() async {
    try {
      final res = await _api.get('/api/venue-applications/slot-templates');
      if (res is List && res.isNotEmpty) {
        return res
            .map((e) => VenueSlotConfigItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {}
    return defaultSlotTemplates();
  }

  @override
  Future<List<VenueApplicationModel>> getMyApplications() async {
    final res = await _api.get('/api/venue-applications/mine');
    return (res as List)
        .map((e) => VenueApplicationModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<UploadedVenueImageModel>> getUnusedImages() async {
    final res = await _api.get('/api/venue-applications/images');
    return (res as List)
        .map((e) => UploadedVenueImageModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<UploadedVenueImageModel> uploadVenueImage(List<int> bytes, String filename) async {
    final res = await _api.uploadMultipartBytes(
      '/api/venue-applications/images',
      bytes: bytes,
      filename: filename,
    );
    return UploadedVenueImageModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<VenueApplicationModel> submitVenueApplication(Map<String, dynamic> body, {int? id}) async {
    final res = id == null
        ? await _api.post('/api/venue-applications', body)
        : await _api.put('/api/venue-applications/$id', body);
    return VenueApplicationModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<List<ManagedVenue>> getManagedVenues() async {
    final res = await _api.get('/api/owner/venues');
    return (res as List)
        .map((e) => ManagedVenue.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<OwnerVenueConfigModel> getOwnerVenueConfig(int venueId) async {
    final res = await _api.get('/api/owner/venues/$venueId/config');
    return OwnerVenueConfigModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<OwnerVenueConfigModel> updateOwnerVenueInfo(int venueId, Map<String, dynamic> body) async {
    final res = await _api.put('/api/owner/venues/$venueId/info', body);
    return OwnerVenueConfigModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<OwnerVenueConfigModel> updateOwnerSlotConfig(int venueId, Map<String, dynamic> body) async {
    final res = await _api.put('/api/owner/venues/$venueId/slots', body);
    return OwnerVenueConfigModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<SubVenueModel> addSubVenue(int venueId, String name, {bool isActive = true}) async {
    final res = await _api.post('/api/owner/venues/$venueId/subvenues', {
      'name': name,
      'isActive': isActive,
    });
    return SubVenueModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<SubVenueModel> updateSubVenue(int subVenueId, String name, bool isActive) async {
    final res = await _api.put('/api/owner/subvenues/$subVenueId', {
      'name': name,
      'isActive': isActive,
    });
    return SubVenueModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<void> deleteSubVenue(int subVenueId) async {
    await _api.delete('/api/owner/subvenues/$subVenueId');
  }

  @override
  Future<VenueServiceModel> addVenueService(int venueId, Map<String, dynamic> body) async {
    final res = await _api.post('/api/owner/venues/$venueId/services', body);
    return VenueServiceModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<VenueServiceModel> updateVenueService(int serviceId, Map<String, dynamic> body) async {
    final res = await _api.put('/api/owner/services/$serviceId', body);
    return VenueServiceModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<void> deleteVenueService(int serviceId) async {
    await _api.delete('/api/owner/services/$serviceId');
  }

  @override
  Future<VenueStaffMemberModel> assignVenueStaff(int venueId, String identifier) async {
    final res = await _api.post('/api/owner/venues/$venueId/staff', {
      'identifier': identifier,
    });
    return VenueStaffMemberModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<void> removeVenueStaff(int venueId, int staffUserId) async {
    await _api.delete('/api/owner/venues/$venueId/staff/$staffUserId');
  }

  @override
  Future<AdminOverviewModel> getAdminOverview() async {
    final res = await _api.get('/api/admin/overview');
    return AdminOverviewModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<List<VenueApplicationModel>> getAdminVenues() async {
    final res = await _api.get('/api/admin/venues');
    return (res as List)
        .map((e) => VenueApplicationModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<VenueApplicationModel> reviewVenue(
    int venueId, {
    required bool approve,
    required int revision,
    String reason = '',
  }) async {
    final res = await _api.post('/api/admin/venues/$venueId/review', {
      'approve': approve,
      'revision': revision,
      'reason': reason,
    });
    return VenueApplicationModel.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<bool> setVenueActive(int venueId, bool isActive) async {
    final res = await _api.put('/api/admin/venues/$venueId/status', {'isActive': isActive});
    return res == true;
  }

  @override
  Future<List<AdminUserModel>> getAdminUsers() async {
    final res = await _api.get('/api/admin/accounts');
    return (res as List)
        .map((e) => AdminUserModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<bool> setUserActive(int userId, bool isActive) async {
    final res = await _api.put('/api/admin/accounts/$userId/status', {'isActive': isActive});
    return res == true;
  }

  @override
  Future<AdminUserModel> assignUserRoleAndVenue(
    int userId, {
    required String role,
    int? venueId,
  }) async {
    final res = await _api.put('/api/admin/accounts/$userId/role-venue', {
      'role': role,
      if (venueId != null && venueId > 0) 'venueId': venueId,
    });
    return AdminUserModel.fromJson(Map<String, dynamic>.from(res as Map));
  }
}

