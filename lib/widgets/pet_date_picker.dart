import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';

class PetDatePickerResult {
  final DateTime? date;

  const PetDatePickerResult(this.date);
}

class PetDateField extends StatelessWidget {
  final String labelText;
  final String emptyText;
  final IconData icon;
  final DateTime? selectedDate;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const PetDateField({
    super.key,
    required this.labelText,
    required this.emptyText,
    required this.icon,
    required this.selectedDate,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;

    return Semantics(
      button: true,
      label: labelText,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: labelText,
            prefixIcon: Icon(icon),
            suffixIcon: hasDate && onClear != null
                ? IconButton(
                    tooltip: 'Clear $labelText',
                    icon: const Icon(Icons.close),
                    onPressed: onClear,
                  )
                : const Icon(Icons.calendar_today),
          ),
          child: Text(
            hasDate ? DateFormat('MMMM d, y').format(selectedDate!) : emptyText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasDate
                  ? AppTheme.primaryText(context)
                  : AppTheme.mutedText(context),
            ),
          ),
        ),
      ),
    );
  }
}

Future<PetDatePickerResult?> showPetDatePicker({
  required BuildContext context,
  required String title,
  required DateTime? selectedDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showModalBottomSheet<PetDatePickerResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _PetDatePickerSheet(
        title: title,
        selectedDate: selectedDate,
        firstDate: _dateOnly(firstDate),
        lastDate: _dateOnly(lastDate),
      );
    },
  );
}

class _PetDatePickerSheet extends StatefulWidget {
  final String title;
  final DateTime? selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _PetDatePickerSheet({
    required this.title,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_PetDatePickerSheet> createState() => _PetDatePickerSheetState();
}

class _PetDatePickerSheetState extends State<_PetDatePickerSheet> {
  late DateTime? _selectedDate;
  late DateTime _initialDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate == null
        ? null
        : _clampDate(
            _dateOnly(widget.selectedDate!),
            widget.firstDate,
            widget.lastDate,
          );
    _initialDate = _selectedDate ?? widget.lastDate;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final screenSize = MediaQuery.sizeOf(context);
    final maxHeight = screenSize.height * 0.9;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Material(
            color: AppTheme.surfaceBackground(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 360
                      ? 12.0
                      : 20.0;

                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SheetHandle(),
                          const SizedBox(height: 12),
                          _DatePickerHeader(
                            title: widget.title,
                            selectedDate: _selectedDate,
                            onClose: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(height: 8),
                          _ResponsiveCalendar(
                            initialDate: _initialDate,
                            firstDate: widget.firstDate,
                            lastDate: widget.lastDate,
                            selectedDate: _selectedDate,
                            onDateChanged: (date) {
                              setState(() {
                                _selectedDate = _dateOnly(date);
                                _initialDate = _selectedDate!;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _DatePickerActions(
                            hasSelection: _selectedDate != null,
                            onClear: () {
                              Navigator.of(
                                context,
                              ).pop(const PetDatePickerResult(null));
                            },
                            onCancel: () => Navigator.of(context).pop(),
                            onDone: () {
                              Navigator.of(
                                context,
                              ).pop(PetDatePickerResult(_selectedDate));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePickerHeader extends StatelessWidget {
  final String title;
  final DateTime? selectedDate;
  final VoidCallback onClose;

  const _DatePickerHeader({
    required this.title,
    required this.selectedDate,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final selectedLabel = selectedDate == null
        ? 'No date selected'
        : DateFormat('EEE, MMM d, y').format(selectedDate!);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryText(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                selectedLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _ResponsiveCalendar extends StatelessWidget {
  static const double _calendarWidth = 340;
  static const double _calendarHeight = 348;

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _ResponsiveCalendar({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final scale = availableWidth < _calendarWidth
            ? availableWidth / _calendarWidth
            : 1.0;

        return Center(
          child: SizedBox(
            width: availableWidth,
            height: _calendarHeight * scale,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: _calendarWidth,
                height: _calendarHeight,
                child: CalendarDatePicker(
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  currentDate: _dateOnly(DateTime.now()),
                  initialCalendarMode: DatePickerMode.year,
                  onDateChanged: onDateChanged,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DatePickerActions extends StatelessWidget {
  final bool hasSelection;
  final VoidCallback onClear;
  final VoidCallback onCancel;
  final VoidCallback onDone;

  const _DatePickerActions({
    required this.hasSelection,
    required this.onClear,
    required this.onCancel,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (hasSelection)
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
          ),
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ElevatedButton.icon(
          onPressed: onDone,
          icon: const Icon(Icons.check),
          label: const Text('Done'),
        ),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.isDark(context)
              ? AppTheme.darkDivider
              : AppTheme.divider(context),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _clampDate(DateTime date, DateTime firstDate, DateTime lastDate) {
  if (date.isBefore(firstDate)) return firstDate;
  if (date.isAfter(lastDate)) return lastDate;
  return date;
}
