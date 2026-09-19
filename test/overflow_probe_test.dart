import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecowell/features/shared/who_to_follow_card.dart';
import 'package:ecowell/models/app_user.dart';

Future<void> runProbe(WidgetTester tester, double width, String label, Widget Function() build,
    {double textScale = 1.0}) async {
  final errors = <String>[];
  final oldOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.toString().contains('overflowed')) {
      errors.add(details.exceptionAsString());
    }
  };
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(body: build()),
  ));
  await tester.pump();
  FlutterError.onError = oldOnError;
  // ignore: avoid_print
  print('$label @$width:');
  if (errors.isEmpty) {
    // ignore: avoid_print
    print('  OK');
  }
  for (final e in errors.toSet()) {
    final first = e.indexOf('overflowed');
    // ignore: avoid_print
    print('  ${e.substring(0, (first + 130).clamp(0, e.length))}');
  }
}

void main() {
  testWidgets('probe each widget separately', (WidgetTester tester) async {
    final user = AppUser(
      id: '1',
      name: 'EcoExplorer',
      email: 'a@b.com',
      age: 25,
      createdAt: DateTime(2026, 1, 1),
      followersCount: '1.2k',
      isVerified: true,
    );

    for (final width in [320.0, 375.0, 390.0, 430.0]) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final sc = width / 390;

      await runProbe(tester, width, 'WHO_CARD', () => Center(
            child: SizedBox(
              height: 195 * sc,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 1,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, _) => WhoToFollowCard(user: user),
              ),
            ),
          ));

      for (final textScale in [1.0, 1.1, 1.3]) {
        await runProbe(tester, width, 'SETTINGS_CARD txt${textScale}x', () => Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: width - 28,
                padding: EdgeInsets.all(18 * sc),
                decoration: const BoxDecoration(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Settings & Reminders',
                        style: TextStyle(fontSize: 16 * sc, fontWeight: FontWeight.w800, fontFamily: 'serif')),
                    SizedBox(height: 12 * sc),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Daily Nature Walk Reminder',
                          style: TextStyle(fontSize: 14 * sc, fontWeight: FontWeight.w600)),
                      subtitle: Text('Smart reminder based on optimal Mati weather',
                          style: TextStyle(fontSize: 12 * sc)),
                      value: true,
                      activeTrackColor: Colors.green,
                      onChanged: (v) {},
                    ),
                    const Divider(color: Color(0xFFEEF2EF)),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.picture_as_pdf_rounded),
                      title: Text('Download Wellness Data (PDF)',
                          style: TextStyle(fontSize: 14 * sc, fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () {},
                    ),
                    const Divider(color: Color(0xFFEEF2EF)),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history_rounded),
                      title: Text('View Full Visit History',
                          style: TextStyle(fontSize: 14 * sc, fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ));
      }

      await runProbe(tester, width, 'STATS_ROW', () => Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width - 28 - 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final stat in [
                    ('Visits', '12'),
                    ('Streak', '7 Days'),
                    ('Avg Reduction', '+25.6%'),
                    ('Followers', '1.2k'),
                  ])
                    Column(
                      children: [
                        Text(stat.$2, style: TextStyle(fontSize: 16 * sc, fontWeight: FontWeight.w800)),
                        SizedBox(height: 2 * sc),
                        Text(stat.$1, style: TextStyle(fontSize: 11 * sc)),
                      ],
                    ),
                ],
              ),
            ),
          ));

      for (final textScale in [1.0, 1.3]) {
        final chipChildren = <Widget>[];
        for (final label in ['All', 'Reminders', 'Community', 'Weather']) {
          chipChildren.add(Container(
            padding: EdgeInsets.symmetric(horizontal: 12 * sc, vertical: 6 * sc),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16 * sc)),
            child: Text(label, style: TextStyle(fontSize: 12 * sc, fontWeight: FontWeight.w600)),
          ));
          chipChildren.add(SizedBox(width: 8 * sc));
        }
        chipChildren.removeLast();
        await runProbe(
          tester,
          width,
          'CHIPS txt${textScale}x',
          () => Padding(
            padding: EdgeInsets.symmetric(
                horizontal: [
              if (width < 360) 12.0 else if (width < 390) 14.0 else if (width < 420) 16.0 else 20.0,
            ].first),
            child: Row(children: chipChildren),
          ),
          textScale: textScale,
        );
      }
    }
  });
}