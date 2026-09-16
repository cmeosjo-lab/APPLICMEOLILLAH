import 'package:flutter/material.dart';

class SchoolHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? teacher;

  const SchoolHeader({super.key, required this.title, required this.subtitle, this.teacher});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (teacher != null && teacher!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [const Icon(Icons.person_outline, size: 18), const SizedBox(width: 6), Expanded(child: Text(teacher!, style: const TextStyle(fontWeight: FontWeight.w600)))]),
          ],
        ]),
      );
}
