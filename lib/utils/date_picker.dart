import 'package:flutter/material.dart';

Future<DateTime?> pickDateTime(BuildContext context, {DateTime? initialDate}) async {
  final now = DateTime.now();

  // Step 1: Pick a date
  final date = await showDatePicker(
    context: context,
    initialDate: initialDate ?? now,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  if (date == null) return null; // User canceled

  // ignore: use_build_context_synchronously
  final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initialDate ?? now));

  if (time == null) return null; // User canceled

  // Step 3: Combine both
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
