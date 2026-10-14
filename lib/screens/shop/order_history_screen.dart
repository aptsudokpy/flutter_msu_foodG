import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/food_order.dart';
import '../../services/db.dart';

enum _HistoryPeriod { day, week, month, custom }

class OrderHistoryScreen extends StatefulWidget {
  final String shopId;

  const OrderHistoryScreen({super.key, required this.shopId});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  _HistoryPeriod _period = _HistoryPeriod.day;
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  DateTimeRange? _customRange;

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _numberFormat = NumberFormat('#,##0.##', 'th_TH');

  (DateTime, DateTime) get _range {
    switch (_period) {
      case _HistoryPeriod.day:
        final start = DateUtils.dateOnly(_selectedDate);
        return (start, start.add(const Duration(days: 1)));
      case _HistoryPeriod.week:
        final date = DateUtils.dateOnly(_selectedDate);
        final start = date.subtract(Duration(days: date.weekday - 1));
        return (start, start.add(const Duration(days: 7)));
      case _HistoryPeriod.month:
        final start = DateTime(_selectedDate.year, _selectedDate.month);
        return (start, DateTime(_selectedDate.year, _selectedDate.month + 1));
      case _HistoryPeriod.custom:
        final range = _customRange;
        if (range == null) {
          final start = DateUtils.dateOnly(_selectedDate);
          return (start, start.add(const Duration(days: 1)));
        }
        final start = DateUtils.dateOnly(range.start);
        final end = DateUtils.dateOnly(range.end).add(const Duration(days: 1));
        return (start, end);
    }
  }

  String get _rangeLabel {
    final (start, exclusiveEnd) = _range;
    final end = exclusiveEnd.subtract(const Duration(days: 1));
    if (start == end) return _dateFormat.format(start);
    return '${_dateFormat.format(start)} - ${_dateFormat.format(end)}';
  }

  Future<void> _selectCustomRange() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final initialStart = _customRange?.start ?? now;
    final initialEnd = _customRange?.end ?? now;
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: initialStart.isAfter(now) ? now : initialStart,
        end: initialEnd.isAfter(now) ? now : initialEnd,
      ),
      helpText: 'เลือกช่วงวันที่ของประวัติออร์เดอร์',
      saveText: 'แสดงประวัติ',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _customRange = selected;
      _period = _HistoryPeriod.custom;
    });
  }

  void _selectPeriod(_HistoryPeriod period) {
    if (period == _HistoryPeriod.custom) {
      _selectCustomRange();
      return;
    }
    setState(() {
      _period = period;
      _selectedDate = DateUtils.dateOnly(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final (start, end) = _range;
    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติออร์เดอร์')),
      body: StreamBuilder<List<FoodOrder>>(
        stream: Db().watchCompletedShopOrders(widget.shopId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('ผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.where((order) {
            final completedAt = order.updatedAt ?? order.createdAt;
            return completedAt != null &&
                !completedAt.isBefore(start) &&
                completedAt.isBefore(end);
          }).toList()
            ..sort((first, second) {
              final firstDate = first.updatedAt ?? first.createdAt!;
              final secondDate = second.updatedAt ?? second.createdAt!;
              return secondDate.compareTo(firstDate);
            });
          final income = orders.fold<num>(0, (sum, order) => sum + order.total);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_HistoryPeriod>(
                  segments: const [
                    ButtonSegment(
                      value: _HistoryPeriod.day,
                      label: Text('รายวัน'),
                    ),
                    ButtonSegment(
                      value: _HistoryPeriod.week,
                      label: Text('รายสัปดาห์'),
                    ),
                    ButtonSegment(
                      value: _HistoryPeriod.month,
                      label: Text('รายเดือน'),
                    ),
                    ButtonSegment(
                      value: _HistoryPeriod.custom,
                      label: Text('เลือกวันที่'),
                    ),
                  ],
                  selected: {_period},
                  onSelectionChanged: (selection) =>
                      _selectPeriod(selection.first),
                  showSelectedIcon: false,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectCustomRange,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'ช่วงวันที่',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(_rangeLabel)),
                      const Icon(Icons.edit_calendar_outlined, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('รายรับจากออร์เดอร์สำเร็จ',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        '${_numberFormat.format(income)} บาท',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('ออร์เดอร์สำเร็จ ${orders.length} รายการ'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('รายการออร์เดอร์',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              if (orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: Text('ไม่พบออร์เดอร์สำเร็จในช่วงวันที่นี้')),
                )
              else
                for (final order in orders)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(order.customerName),
                      subtitle: Text(
                        '${_dateTimeFormat.format(order.updatedAt ?? order.createdAt!)}\n'
                        '${order.items.map((item) => '${item.name} x${item.qty}').join(', ')}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        '${_numberFormat.format(order.total)} บาท',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}