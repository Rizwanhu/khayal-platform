import '../i18n/app_language.dart';
import 'chat_models.dart';

/// Labels for the patient's paid chat period (monthly subscription).
class ChatSubscriptionPeriodDisplay {
  const ChatSubscriptionPeriodDisplay({
    required this.planLabel,
    required this.rangeLabel,
  });

  final String planLabel;
  final String rangeLabel;
}

const _monthsEn = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _monthsUr = [
  'جنوری',
  'فروری',
  'مارچ',
  'اپریل',
  'مئی',
  'جون',
  'جولائی',
  'اگست',
  'ستمبر',
  'اکتوبر',
  'نومبر',
  'دسمبر',
];

DateTime _subtractOneCalendarMonth(DateTime date) {
  var month = date.month - 1;
  var year = date.year;
  if (month < 1) {
    month = 12;
    year -= 1;
  }
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = date.day > lastDay ? lastDay : date.day;
  return DateTime(year, month, day, date.hour, date.minute);
}

String _formatDayMonth(DateTime local, {required bool urdu}) {
  final months = urdu ? _monthsUr : _monthsEn;
  return '${local.day} ${months[local.month - 1]}';
}

String _formatRange(DateTime start, DateTime end, {required bool urdu}) {
  final a = _formatDayMonth(start, urdu: urdu);
  final b = _formatDayMonth(end, urdu: urdu);
  if (start.year == end.year) {
    return '$a – $b ${end.year}';
  }
  return '$a ${start.year} – $b ${end.year}';
}

ChatSubscriptionPeriodDisplay chatSubscriptionPeriodDisplay(
  PatientChatSubscription? subscription,
) {
  final urdu = AppLanguageState.isUrdu;
  final planLabel = AppLanguageState.pick(
    en: 'Paid chat · 1 month',
    ur: 'ادا شدہ چیٹ · ایک مہینہ',
  );

  final endUtc = subscription?.currentPeriodEnd;
  if (endUtc == null) {
    final now = DateTime.now();
    final fallbackEnd = now.add(const Duration(days: 30));
    return ChatSubscriptionPeriodDisplay(
      planLabel: planLabel,
      rangeLabel: _formatRange(now, fallbackEnd, urdu: urdu),
    );
  }

  final end = endUtc.toLocal();
  final start = _subtractOneCalendarMonth(end);
  return ChatSubscriptionPeriodDisplay(
    planLabel: planLabel,
    rangeLabel: _formatRange(start, end, urdu: urdu),
  );
}
