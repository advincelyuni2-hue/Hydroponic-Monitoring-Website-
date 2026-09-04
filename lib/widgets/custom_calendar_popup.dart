import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum CalendarMode { daily, weekly, monthly }

class CustomCalendarPopup extends StatefulWidget {
  final CalendarMode mode;
  final DateTime initialDate;
  final Function(DateTime selectedDate, DateTimeRange? weekRange) onDateSelected;

  const CustomCalendarPopup({
    super.key,
    required this.mode,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<CustomCalendarPopup> createState() => _CustomCalendarPopupState();
}

class _CustomCalendarPopupState extends State<CustomCalendarPopup> {
  late DateTime _focusedDate;
  late DateTime _selectedDate;
  bool _showYearPicker = false;

  @override
  void initState() {
    super.initState();
    _focusedDate = widget.initialDate;
    _selectedDate = widget.initialDate;
  }

  // Snaps 7 days starting directly on whatever date the user clicks
  DateTimeRange _getWeekRange(DateTime date) {
    final startOfWeek = DateTime(date.year, date.month, date.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return DateTimeRange(
      start: startOfWeek,
      end: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isInRange(DateTime day, DateTimeRange range) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(range.start) && !d.isAfter(range.end);
  }

  String get _title {
    switch (widget.mode) {
      case CalendarMode.daily:
        return 'Choose a date';
      case CalendarMode.weekly:
        return 'Choose a week';
      case CalendarMode.monthly:
        return 'Choose a month';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _title,
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildMonthYearHeader(),
            const SizedBox(height: 16),
            if (_showYearPicker)
              _buildYearGrid()
            else if (widget.mode == CalendarMode.monthly)
              _buildMonthGrid()
            else
              _buildDaysCalendar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthYearHeader() {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthName = months[_focusedDate.month - 1];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showYearPicker = !_showYearPicker;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$monthName, ${_focusedDate.year}',
                style: AppTextStyles.cardLabel.copyWith(fontSize: 16),
              ),
              const SizedBox(width: 4),
              Icon(
                _showYearPicker ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: textColor,
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, size: 20, color: textColor),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  if (_showYearPicker) {
                    _focusedDate = DateTime(_focusedDate.year - 1, _focusedDate.month);
                  } else {
                    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
                  }
                });
              },
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(Icons.chevron_right, size: 20, color: textColor),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  if (_showYearPicker) {
                    _focusedDate = DateTime(_focusedDate.year + 1, _focusedDate.month);
                  } else {
                    _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYearGrid() {
    final currentYear = _focusedDate.year;
    final years = List.generate(12, (index) => currentYear - 5 + index);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      height: 200,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: years.length,
        itemBuilder: (context, index) {
          final year = years[index];
          final isSelected = year == _focusedDate.year;
          return InkWell(
            onTap: () {
              setState(() {
                _focusedDate = DateTime(year, _focusedDate.month);
                _showYearPicker = false;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryButton : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                '$year',
                style: AppTextStyles.bodyBold.copyWith(
                  color: isSelected ? Colors.white : textColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthGrid() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final textColor = Theme.of(context).colorScheme.onSurface;
    final monthBackground = Theme.of(context).colorScheme.surfaceContainerHighest;

    return SizedBox(
      height: 200,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final isSelected = (index + 1) == _selectedDate.month &&
              _focusedDate.year == _selectedDate.year;

          return InkWell(
            onTap: () {
              final newDate = DateTime(_focusedDate.year, index + 1, 1);
              widget.onDateSelected(newDate, null);
              Navigator.of(context).pop();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryButton : monthBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                months[index],
                style: AppTextStyles.bodyBold.copyWith(
                  color: isSelected ? Colors.white : textColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDaysCalendar() {
    final daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedDate.year, _focusedDate.month, 1).weekday;
    final leadingPadding = (firstWeekday % 7); // Sunday = 0

    final weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final weekRange = _getWeekRange(_selectedDate);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final rangeBackground = Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF365230)
      : const Color(0xFFE2F0D9);

    return Column(
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays
              .map((d) => SizedBox(
                    width: 32,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.cardMeta.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // Grid of dates
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 0,
          ),
          itemCount: leadingPadding + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingPadding) {
              return const SizedBox();
            }

            final dayNum = index - leadingPadding + 1;
            final date = DateTime(_focusedDate.year, _focusedDate.month, dayNum);

            final isSelectedDay = _isSameDay(date, _selectedDate);
            final isInSelectedWeek = widget.mode == CalendarMode.weekly &&
                _isInRange(date, weekRange);

            final colIndex = index % 7;
            final isRowStart = colIndex == 0 || _isSameDay(date, weekRange.start);
            final isRowEnd = colIndex == 6 || _isSameDay(date, weekRange.end);

            // Outer decoration (light green band)
            BoxDecoration outerDecoration = const BoxDecoration();
            if (widget.mode == CalendarMode.weekly && isInSelectedWeek) {
              outerDecoration = BoxDecoration(
                color: rangeBackground,
                borderRadius: BorderRadius.horizontal(
                  left: isRowStart ? const Radius.circular(16) : Radius.zero,
                  right: isRowEnd ? const Radius.circular(16) : Radius.zero,
                ),
              );
            }

            // Inner decoration (selected date badge)
            BoxDecoration? innerDecoration;
            var dayTextColor = textColor;

            if (isSelectedDay) {
              innerDecoration = const BoxDecoration(
                color: AppColors.primaryButton,
                shape: BoxShape.circle,
              );
              dayTextColor = Colors.white;
            }

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
                final selectedWeek = widget.mode == CalendarMode.weekly
                    ? _getWeekRange(date)
                    : null;

                widget.onDateSelected(date, selectedWeek);
                Navigator.of(context).pop();
              },
              child: Container(
                decoration: outerDecoration,
                alignment: Alignment.center,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: innerDecoration,
                  alignment: Alignment.center,
                  child: Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelectedDay ? FontWeight.w700 : FontWeight.w400,
                      color: dayTextColor,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}