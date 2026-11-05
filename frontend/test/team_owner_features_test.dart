import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sportspot/data/models/user_model.dart';
import 'package:sportspot/data/models/team_model.dart';
import 'package:sportspot/data/models/owner_schedule_model.dart';
import 'package:sportspot/data/repositories/team_repository.dart';
import 'package:sportspot/data/repositories/owner_schedule_repository.dart';
import 'package:sportspot/providers/auth_provider.dart';
import 'package:sportspot/screens/teams/team_match_screen.dart';
import 'package:sportspot/screens/owner/owner_schedule_screen.dart';

class Session extends AuthProvider {
  final String role;
  Session(this.role);
  @override
  bool get isAuthenticated => true;
  @override
  bool get isGuest => false;
  @override
  UserModel get currentUser => UserModel(
    userId: 1,
    fullName: 'Captain',
    phoneNumber: '0900000001',
    role: role,
  );
}

Map<String, dynamic> teamJson(int id, String name, int captain) => {
  'id': id,
  'name': name,
  'captainUserId': captain,
  'captainName': 'Captain',
  'teamSize': 7,
  'skillLevel': 'Cơ bản',
};

class Teams extends TeamRepository {
  bool host = false, fail = false;
  String? actionTaken, createdName;
  int? appliedTeam;
  @override
  Future<List<FootballTeam>> myTeams() async => [
    FootballTeam.fromJson(teamJson(1, 'My team', 1)),
  ];
  @override
  Future<List<TeamChallenge>> challenges({bool mine = false}) async {
    if (fail) throw Exception('Không tải được kèo');
    return [
      TeamChallenge.fromJson({
        'id': 11,
        'team': teamJson(2, 'Opponent FC', host ? 1 : 2),
        'bookingId': 25,
        'venueName': 'Sân bóng',
        'subVenueName': 'Sân 7',
        'district': 'Thủ Đức',
        'playDate': '2026-12-01',
        'timeSlots': ['19:00-20:00'],
        'opponentCourtShare': 250000,
        'note': 'Giao hữu',
        'status': 'Open',
        'isHost': host,
        'requests': host
            ? [
                {
                  'id': 15,
                  'team': teamJson(3, 'Visitor FC', 3),
                  'message': 'Xin giao hữu',
                  'status': 'Pending',
                },
              ]
            : [],
      }),
    ];
  }

  @override
  Future<void> apply(int id, int teamId, String message) async {
    appliedTeam = teamId;
  }

  @override
  Future<void> action(int id, String action, {int? requestId}) async {
    actionTaken = '$action/$requestId';
  }

  @override
  Future<void> createTeam(String name, int size, String level) async {
    createdName = name;
  }
}

class Schedule extends OwnerScheduleRepository {
  Map<String, dynamic>? created;
  bool cancelled = false, fail = false, empty = false;
  int? collected;
  String? rangeEnd;
  @override
  Future<List<ManagedVenue>> venues() async => empty
      ? []
      : [
          ManagedVenue.fromJson({
            'id': 1,
            'name': 'Arena',
            'basePrice': 300000,
            'peakPrice': 500000,
          }),
        ];
  @override
  Future<OwnerSchedule> schedule(int venueId, String from, String to) async {
    if (fail) throw Exception('Mất kết nối');
    rangeEnd = to;
    return OwnerSchedule.fromJson({
      'venue': {
        'id': 1,
        'name': 'Arena',
        'basePrice': 300000,
        'peakPrice': 500000,
      },
      'courts': [
        {'id': 1, 'name': 'Pitch 1', 'isActive': true},
      ],
      'slots': [
        {'id': 1, 'startTime': '23:00', 'endTime': '23:59', 'isPeak': true},
        {'id': 2, 'startTime': '22:00', 'endTime': '23:00', 'isPeak': true},
      ],
      'bookings': [
        {
          'id': 4,
          'code': 'OW-123',
          'subVenueId': 1,
          'playDate': from,
          'slotIds': [2],
          'type': 'WalkIn',
          'status': 'Upcoming',
          'customerName': 'Khách tại quầy',
          'customerPhone': '0901234567',
          'note': 'Đội A',
          'totalPrice': 500000,
          'collectedAmount': 100000,
          'remainingBalance': 400000,
        },
      ],
    });
  }

  @override
  Future<void> create(Map<String, dynamic> body) async {
    created = body;
  }

  @override
  Future<void> cancel(int id, bool refund) async {
    cancelled = refund;
  }

  @override
  Future<void> collect(int id, int amount) async {
    collected = amount;
  }
}

Widget app(Widget screen, String role) => ChangeNotifierProvider<AuthProvider>(
  create: (_) => Session(role),
  child: MaterialApp(home: screen),
);

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('Team and owner screens fit a ${width.toInt()}px phone', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app(TeamMatchScreen(repository: Teams()), 'Player'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(app(OwnerScheduleScreen(repository: Schedule()), 'Owner'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Opponent can send a request for the selected team', (
    tester,
  ) async {
    final repo = Teams();
    await tester.pumpWidget(app(TeamMatchScreen(repository: repo), 'Player'));
    await tester.pumpAndSettle();
    expect(find.text('Opponent FC'), findsOneWidget);
    await tester.tap(find.text('Gửi lời mời giao hữu'));
    await tester.pumpAndSettle();
    expect(find.textContaining('250000'), findsWidgets);
    await tester.tap(find.text('Gửi lời mời'));
    await tester.pumpAndSettle();
    expect(repo.appliedTeam, 1);
  });
  testWidgets('Captain accepts an opponent only after confirmation', (
    tester,
  ) async {
    final repo = Teams()..host = true;
    await tester.pumpWidget(app(TeamMatchScreen(repository: repo), 'Player'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Chọn đội'));
    await tester.tap(find.text('Chọn đội'));
    await tester.pumpAndSettle();
    expect(repo.actionTaken, isNull);
    await tester.tap(find.text('Xác nhận').last);
    await tester.pumpAndSettle();
    expect(repo.actionTaken, 'accept/15');
  });
  testWidgets('Create team validates the name before submitting', (
    tester,
  ) async {
    final repo = Teams();
    await tester.pumpWidget(app(TeamMatchScreen(repository: repo), 'Player'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo đội'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Tạo đội'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập ít nhất 2 ký tự'), findsOneWidget);
    expect(repo.createdName, isNull);
    await tester.enterText(find.byType(TextFormField).first, 'FPT FC');
    await tester.tap(find.widgetWithText(FilledButton, 'Tạo đội'));
    await tester.pumpAndSettle();
    expect(repo.createdName, 'FPT FC');
  });
  testWidgets('Team error is visible and supports retry', (tester) async {
    final repo = Teams()..fail = true;
    await tester.pumpWidget(app(TeamMatchScreen(repository: repo), 'Player'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không tải được kèo'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Opponent FC'), findsOneWidget);
  });
  testWidgets('Cash booking detail shows balance and records partial payment', (
    tester,
  ) async {
    final repo = Schedule();
    await tester.pumpWidget(
      app(OwnerScheduleScreen(repository: repo), 'Owner'),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('Khách tại quầy').first);
    await tester.tap(find.textContaining('Khách tại quầy').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Còn lại: 400000'), findsOneWidget);
    await tester.tap(find.text('Thu tiền mặt'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '150000');
    await tester.tap(find.text('Đã nhận tiền'));
    await tester.pumpAndSettle();
    expect(repo.collected, 150000);
  });
  testWidgets('Cash cancellation requires acknowledgement of cash return', (
    tester,
  ) async {
    final repo = Schedule();
    await tester.pumpWidget(
      app(OwnerScheduleScreen(repository: repo), 'Owner'),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('Khách tại quầy').first);
    await tester.tap(find.textContaining('Khách tại quầy').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy lịch tại quầy'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Xác nhận'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
    await tester.pumpAndSettle();
    expect(repo.cancelled, isTrue);
  });
  testWidgets('Seven-day schedule changes the queried range', (tester) async {
    final repo = Schedule();
    await tester.pumpWidget(
      app(OwnerScheduleScreen(repository: repo), 'VenueStaff'),
    );
    await tester.pumpAndSettle();
    final dayEnd = repo.rangeEnd;
    expect(find.text('Bảng giá'), findsNothing);
    await tester.tap(find.text('7 ngày'));
    await tester.pumpAndSettle();
    expect(repo.rangeEnd, isNot(dayEnd));
    expect(find.textContaining('Lịch từ '), findsOneWidget);
  });
  testWidgets('Unassigned owner sees an explicit empty state', (tester) async {
    await tester.pumpWidget(
      app(OwnerScheduleScreen(repository: Schedule()..empty = true), 'Owner'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('chưa được phân công'), findsOneWidget);
  });
}
