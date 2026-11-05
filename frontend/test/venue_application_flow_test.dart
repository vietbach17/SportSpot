import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportspot/core/network/api_client.dart';
import 'package:sportspot/data/models/venue_config_models.dart';
import 'package:sportspot/data/repositories/venue_config_repository.dart';
import 'package:sportspot/screens/admin/venue_moderation_screen.dart';
import 'package:sportspot/screens/owner/venue_application_form.dart';
import 'package:sportspot/screens/owner/venue_applications_screen.dart';

import 'test_http_client.dart';

VenueApplicationModel application(String status) =>
    VenueApplicationModel.fromJson({
      'id': 42,
      'name': 'Sân Phú Nhuận',
      'sportId': 2,
      'sportName': 'Pickleball',
      'address': '128 Nguyễn Trọng Tuyển',
      'district': 'Phú Nhuận',
      'hotline': '0909112233',
      'latitude': 10.799,
      'longitude': 106.678,
      'basePrice': 140000,
      'peakPrice': 210000,
      'maxSlotsPerBooking': 4,
      'minDepositPercent': 50,
      'status': status,
      'revision': 7,
      'courtNames': ['Sân 1', 'Sân 2'],
      'ownerName': 'Chủ sân thật',
      'ownerPhone': '0909112233',
      'rejectionReason': status == 'Rejected' ? 'Bổ sung ảnh mặt tiền' : null,
      'images': [
        {'id': 10, 'url': 'https://example.test/venue.png'},
      ],
      'slotConfigs': [
        {
          'slotId': 1,
          'startTime': '06:00',
          'endTime': '07:00',
          'isActive': true,
          'isPeak': false,
          'customPrice': 120000,
          'effectivePrice': 120000,
        },
      ],
      'services': [
        {
          'id': 5,
          'name': 'Thuê vợt',
          'type': 'Rental',
          'price': 40000,
          'stockQuantity': 5,
        },
      ],
    });

class VenueRepo extends Fake implements IVenueConfigRepository {
  List<VenueApplicationModel> items = [application('Pending')];
  Object? failure;
  bool failLoad = false;
  int reads = 0, reviews = 0, submits = 0;
  int? revision, submittedId;
  String? reason;
  Map<String, dynamic>? body;
  Completer<void>? gate;
  @override
  Future<List<VenueApplicationModel>> getAdminVenues() async {
    reads++;
    if (failLoad) throw ApiException(503, 'Không tải được hồ sơ');
    return items;
  }

  @override
  Future<List<VenueApplicationModel>> getMyApplications() => getAdminVenues();
  @override
  Future<VenueApplicationModel> reviewVenue(
    int venueId, {
    required bool approve,
    required int revision,
    String reason = '',
  }) async {
    reviews++;
    this.revision = revision;
    this.reason = reason;
    await gate?.future;
    if (failure != null) throw failure!;
    final updated = application(approve ? 'Approved' : 'Rejected');
    items = [updated];
    return updated;
  }

  @override
  Future<List<Map<String, dynamic>>> getSports() async => [
    {'id': 2, 'name': 'Pickleball'},
  ];
  @override
  Future<List<VenueSlotConfigItemModel>> getSlotTemplates() async => [
    const VenueSlotConfigItemModel(
      slotId: 1,
      startTime: '06:00',
      endTime: '07:00',
      isActive: true,
      isPeak: false,
    ),
  ];
  @override
  Future<List<UploadedVenueImageModel>> getUnusedImages() async => [
    const UploadedVenueImageModel(
      id: 11,
      url: 'https://example.test/unused.png',
    ),
  ];
  @override
  Future<VenueApplicationModel> submitVenueApplication(
    Map<String, dynamic> body, {
    int? id,
  }) async {
    submits++;
    this.body = body;
    submittedId = id;
    if (failure != null) throw failure!;
    return application('Pending');
  }
}

void main() {
  setUp(() => HttpOverrides.global = MockHttpOverrides());
  tearDown(() => HttpOverrides.global = null);

  Future<void> admin(WidgetTester tester, VenueRepo repo) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: VenueModerationScreen(repository: repo)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester, String button) async {
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
  }

  Future<void> openForm(
    WidgetTester tester,
    VenueRepo repo, {
    VenueApplicationModel? v,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) =>
                      VenueApplicationForm(repository: repo, application: v),
                ),
              ),
              child: const Text('Mở'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gửi hồ sơ chờ duyệt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi hồ sơ chờ duyệt'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Admin loads actual applications and requires a rejection reason',
    (tester) async {
      final repo = VenueRepo();
      await admin(tester, repo);
      expect(find.text('Sân Phú Nhuận'), findsOneWidget);
      await confirm(tester, 'Từ chối');
      expect(repo.reviews, 0);
      expect(find.text('Nhập lý do để chủ sân bổ sung hồ sơ'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Ảnh chưa rõ');
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(repo.reviews, 1);
      expect(repo.revision, 7);
      expect(repo.reason, 'Ảnh chưa rõ');
      expect(find.text('Phê duyệt'), findsNothing);
    },
  );

  testWidgets('Failed approval keeps pending application available for retry', (
    tester,
  ) async {
    final repo = VenueRepo()..failure = ApiException(503, 'Mất kết nối');
    await admin(tester, repo);
    await confirm(tester, 'Phê duyệt');
    expect(find.text('Mất kết nối'), findsOneWidget);
    expect(find.text('Sân Phú Nhuận'), findsOneWidget);
    expect(find.text('Phê duyệt'), findsOneWidget);
  });

  testWidgets('Stale admin decision refreshes applications from server', (
    tester,
  ) async {
    final repo = VenueRepo()..failure = ApiException(409, 'Hồ sơ vừa thay đổi');
    await admin(tester, repo);
    repo.items = [application('Approved')];
    await confirm(tester, 'Phê duyệt');
    expect(repo.reads, 2);
    expect(find.text('Phê duyệt'), findsNothing);
  });

  testWidgets(
    'Approval disables duplicate decisions while request is pending',
    (tester) async {
      final repo = VenueRepo()..gate = Completer<void>();
      await admin(tester, repo);
      await confirm(tester, 'Phê duyệt');
      expect(repo.reviews, 1);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Từ chối'),
            )
            .onPressed,
        isNull,
      );
      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Phê duyệt'), findsNothing);
    },
  );

  testWidgets('Load failure offers retry rather than demo applications', (
    tester,
  ) async {
    final repo = VenueRepo()..failLoad = true;
    await admin(tester, repo);
    expect(find.text('Không tải được hồ sơ'), findsOneWidget);
    expect(find.text('Sân Phú Nhuận'), findsNothing);
    repo.failLoad = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Sân Phú Nhuận'), findsOneWidget);
  });

  testWidgets('Applicant sees rejection feedback and can reopen form', (
    tester,
  ) async {
    final repo = VenueRepo()..items = [application('Rejected')];
    await tester.pumpWidget(
      MaterialApp(home: VenueApplicationsScreen(repository: repo)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lý do từ chối: Bổ sung ảnh mặt tiền'), findsOneWidget);
    await tester.ensureVisible(find.text('Bổ sung và gửi lại'));
    await tester.tap(find.text('Bổ sung và gửi lại'));
    await tester.pumpAndSettle();
    expect(find.text('Bổ sung hồ sơ'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('name')))
          .controller!
          .text,
      'Sân Phú Nhuận',
    );
  });

  testWidgets(
    'Resubmission preserves photos, services, policy, slot prices and revision',
    (tester) async {
      final repo = VenueRepo();
      await openForm(tester, repo, v: application('Rejected'));
      await send(tester);
      expect(repo.submittedId, 42);
      expect(repo.body!['revision'], 7);
      expect(repo.body!['imageIds'], [10]);
      expect(repo.body!['minDepositPercent'], 50);
      expect(repo.body!['maxSlotsPerBooking'], 4);
      expect((repo.body!['slotConfigs'] as List).single['customPrice'], 120000);
      expect((repo.body!['services'] as List).single['name'], 'Thuê vợt');
      expect(find.text('Mở'), findsOneWidget);
    },
  );

  testWidgets(
    'Validation includes fields scrolled offscreen and rejects duplicate courts',
    (tester) async {
      final repo = VenueRepo();
      await openForm(tester, repo, v: application('Rejected'));
      await tester.enterText(find.byKey(const ValueKey('name')), '');
      await tester.ensureVisible(find.byKey(const ValueKey('courts')));
      await tester.enterText(
        find.byKey(const ValueKey('courts')),
        'Sân 1\nSÂN 1',
      );
      await send(tester);
      expect(repo.submits, 0);
      expect(find.text('Nhập ít nhất 3 ký tự'), findsOneWidget);
      expect(find.text('Tên sân con không được trùng'), findsOneWidget);
    },
  );

  testWidgets(
    'New application submits an uploaded image selected from unused gallery',
    (tester) async {
      final repo = VenueRepo();
      await openForm(tester, repo);
      final inputs = {
        'name': 'Sân mới',
        'address': '123 Nguyễn Văn Trỗi',
        'district': 'Phú Nhuận',
        'hotline': '0909112233',
        'latitude': '10.8',
        'longitude': '106.7',
      };
      for (final entry in inputs.entries) {
        await tester.ensureVisible(find.byKey(ValueKey(entry.key)));
        await tester.enterText(find.byKey(ValueKey(entry.key)), entry.value);
      }
      await tester.ensureVisible(find.text('Ảnh đã tải chưa sử dụng'));
      await tester.tap(find.text('Ảnh đã tải chưa sử dụng'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(Image));
      await tester.tap(find.byType(Image));
      await tester.pumpAndSettle();
      await send(tester);
      expect(repo.submits, 1);
      expect(repo.submittedId, isNull);
      expect(repo.body!['imageIds'], [11]);
      expect(repo.body!['name'], 'Sân mới');
    },
  );

  testWidgets('Registration and moderation fit a 320px phone', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = VenueRepo();
    await admin(tester, repo);
    await tester.ensureVisible(find.text('Chi tiết hồ sơ'));
    await tester.tap(find.text('Chi tiết hồ sơ'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await openForm(tester, repo, v: application('Rejected'));
    await tester.ensureVisible(find.text('Gửi hồ sơ chờ duyệt'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
