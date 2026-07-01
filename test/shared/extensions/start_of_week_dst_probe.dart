// NOT a test (no _test suffix): a probe executed as a child `dart` process
// under an explicit TZ by datetime_ext_dst_test.dart. The Dart VM resolves
// the local timezone once at startup, so a specific DST week can only be
// pinned from outside the running test process.
import 'package:sundial/shared/extensions/datetime_ext.dart';

void main() {
  // Run under TZ=America/Santiago. 2026 there: DST ends Sat Apr 4 at 24:00
  // (clocks fall back to 23:00), giving Saturday 25 hours — an extra hour
  // INSIDE the Mon Mar 30 .. Sun Apr 5 week. A Duration-subtraction
  // startOfWeek walked back from Sunday midnight by 6 * 24h therefore lands
  // on Monday 01:00, not Monday midnight.
  // ignore: avoid_print
  print('startOfWeek=${DateTime(2026, 4, 5, 12).startOfWeek.toIso8601String()}');
}
