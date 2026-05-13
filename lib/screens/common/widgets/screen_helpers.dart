import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ScreenTemplate extends StatelessWidget {
  const ScreenTemplate({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class FormScreen extends StatelessWidget {
  const FormScreen({
    super.key,
    required this.title,
    required this.fields,
    required this.nextLabel,
    required this.onNext,
  });

  final String title;
  final List<String> fields;
  final String nextLabel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ScreenTemplate(
      title: title,
      subtitle: 'Frontend-only form layout',
      child: Column(
        children: [
          for (final field in fields) ...[
            TextField(decoration: InputDecoration(labelText: field)),
            const SizedBox(height: 12),
          ],
          ElevatedButton(onPressed: onNext, child: Text(nextLabel)),
        ],
      ),
    );
  }
}

class QuickNavWrap extends StatelessWidget {
  const QuickNavWrap({super.key, required this.routes});

  final Map<String, String> routes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          routes.entries
              .map(
                (entry) => ActionChip(
                  label: Text(entry.key),
                  onPressed: () => Navigator.pushNamed(context, entry.value),
                ),
              )
              .toList(),
    );
  }
}

class MedicationCard extends StatelessWidget {
  const MedicationCard({
    super.key,
    required this.nameUrdu,
    required this.nameEnglish,
    required this.time,
    required this.status,
    required this.statusColor,
  });

  final String nameUrdu;
  final String nameEnglish;
  final String time;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nameUrdu,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'NotoNastaliqUrdu',
                height: 1.7,
              ),
            ),
            Text(nameEnglish, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(time),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  const InfoTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(child: ListTile(title: Text(label), subtitle: Text(value)));
  }
}

class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.day, required this.status});

  final String day;
  final String status;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = switch (status) {
      'Taken' => AppTheme.takenGreen,
      'Missed' => AppTheme.missedRed,
      _ => AppTheme.upcomingAmber,
    };

    return Card(
      child: ListTile(
        title: Text(day),
        trailing: Text(
          status,
          style: TextStyle(fontWeight: FontWeight.w700, color: statusColor),
        ),
      ),
    );
  }
}
