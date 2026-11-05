import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportspot/core/network/api_client.dart';
import 'package:sportspot/data/models/owner_dashboard_model.dart';
import 'package:sportspot/data/repositories/owner_repository.dart';
import 'package:sportspot/screens/owner/owner_dashboard_screen.dart';

class DashboardRepo extends Fake implements IOwnerRepository {
  bool forbidden = false;
  int reads = 0;
  OwnerDashboardModel data = OwnerDashboardModel.fromJson({'venueId': 0});
  @override
  Future<OwnerDashboardModel> getDashboard({int? venueId}) async {
    reads++;
    if (forbidden) {
      throw ApiException(403, 'Bạn không có quyền quản lý cụm sân này');
    }
    return data;
  }
}

void main() {
  testWidgets(
    'Unassigned owner sees onboarding and can refresh after approval',
    (tester) async {
      final repo = DashboardRepo();
      await tester.pumpWidget(
        MaterialApp(home: OwnerDashboardScreen(repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa có cụm sân được phê duyệt'), findsOneWidget);
      expect(find.text('Đăng ký / Theo dõi hồ sơ'), findsOneWidget);
      expect(find.text('Doanh thu thực tế'), findsNothing);
      repo.data = await MockOwnerRepository().getDashboard();
      await tester.tap(find.text('Kiểm tra lại trạng thái'));
      await tester.pumpAndSettle();
      expect(repo.reads, 2);
      expect(find.text('Doanh thu thực tế'), findsOneWidget);
      expect(find.text('Chưa có cụm sân được phê duyệt'), findsNothing);
    },
  );

  testWidgets(
    'Actual permission denial is not displayed as an empty dashboard',
    (tester) async {
      final repo = DashboardRepo()..forbidden = true;
      await tester.pumpWidget(
        MaterialApp(home: OwnerDashboardScreen(repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Bạn không có quyền quản lý cụm sân này'),
        findsOneWidget,
      );
      expect(find.text('Chưa có cụm sân được phê duyệt'), findsNothing);
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );

  testWidgets('Owner onboarding fits a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: OwnerDashboardScreen(repository: DashboardRepo())),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Đăng ký / Theo dõi hồ sơ'), findsOneWidget);
  });
}
