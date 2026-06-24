import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/storage/app_database.dart';
import 'package:sundial/features/sessions/presentation/session_card.dart';

import 'visual_golden_helper.dart';

// Mirror the construction helpers from
// test/features/sessions/session_card_test.dart so the golden exercises the
// same widget surface the unit tests assert against.
Session _session({String? profileId, String id = 's1', String? notes}) =>
    Session(
      id: id,
      startTime: DateTime(2026, 4, 9, 9).millisecondsSinceEpoch,
      endTime: DateTime(2026, 4, 9, 10).millisecondsSinceEpoch,
      durationSecs: 3600,
      dateDay: '2026-04-09',
      profileId: profileId,
      notes: notes,
      createdAt: 0,
      updatedAt: 0,
    );

Profile _profile({
  String id = 'dad',
  String name = 'Dad',
  int colorValue = 0xFF5E9478,
  String? emoji,
}) =>
    Profile(
      id: id,
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      sortOrder: 0,
      createdAt: 0,
    );

void main() {
  testWidgets('SessionCard responsive golden sweep', (tester) async {
    await goldenAtSizes(
      tester,
      name: 'session_card',
      // A profile-attributed session with the "Everyone" tag suppressed plus a
      // null-profile session showing the Everyone chip — the two width-hungry
      // layouts stacked so the sweep reveals any row overflow at narrow widths
      // and large text scales (the title Row holds avatar + duration + chip).
      home: Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SessionCard(
                session: _session(profileId: 'dad', id: 's1'),
                profile: _profile(),
                onTap: () {},
                onDelete: () {},
              ),
              SessionCard(
                session: _session(
                  profileId: null,
                  id: 's2',
                  notes: 'Deep work on the quarterly planning doc',
                ),
                showEveryoneTag: true,
                onTap: () {},
                onDelete: () {},
              ),
            ],
          ),
        ),
      ),
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      sizes: const {
        'phone': Size(360, 800),
        'narrow': Size(320, 800),
      },
      textScales: const <double>[1.0, 3.0],
    );
  });
}
