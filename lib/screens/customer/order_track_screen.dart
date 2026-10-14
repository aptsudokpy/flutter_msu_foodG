import 'package:flutter/material.dart';
import '../../models/food_order.dart';
import '../../services/db.dart';

/// หน้าติดตามสถานะคำำสั่งซื้อ
///
/// ใช้การฟัง "เอกสารเดียว" ซึ่งประหยัดโควตาที่สุด
/// เพราะจะนับการอ่านเพิ่มก็ต่อเมื่อเอกสารใบนั้นเปลี่ยนแปลงจริง
///
/// เมื่อร้านกดเปลี่ยนสถานะบนอีกเครื่อง StreamBuilder จะได้รับค่าใหม่
/// แล้วเรียก builder ให้เองโดยอัตโนมัติ จึงไม่ต้องเรียก setState() เลย
class OrderTrackScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackScreen({super.key, required this.orderId});
  @override
  Widget build(BuildContext context) {
    final db = Db();
    return Scaffold(
      appBar: AppBar(title: const Text('ติดตามออร์เดอร์')),
      body: StreamBuilder<FoodOrder>(
        stream: db.watchOrder(orderId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('ผิดพลาด: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = snap.data!;
          final steps = OrderStatus.flow;
          final currentIndex = steps.indexOf(order.status);
          final cancelled = order.status == OrderStatus.cancelled;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Card(
                color: cancelled
                    ? const Color(0xFFFFEEEE)
                    : const Color(0xFFEAF3ED),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        cancelled
                            ? Icons.cancel_outlined
                            : order.status == OrderStatus.ready
                                ? Icons.check_circle_outline
                                : Icons.delivery_dining_rounded,
                        size: 34,
                        color: cancelled
                            ? Colors.red.shade600
                            : const Color(0xFF2F8157),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cancelled
                                  ? 'ออร์เดอร์ถูกยกเลิก'
                                  : OrderStatus.labels[order.status] ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cancelled
                                  ? 'ดูรายละเอียดออร์เดอร์ด้านล่าง'
                                  : 'สถานะจะอัปเดตเมื่อร้านดำเนินการ',
                              style: TextStyle(color: Colors.blueGrey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.shopName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 14),
                      for (final item in order.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Expanded(child: Text('${item.name}  × ${item.qty}')),
                              Text('${item.subtotal} บาท'),
                            ],
                          ),
                        ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'ยอดรวม',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '${order.total} บาท',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      if (order.note.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF6E8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('หมายเหตุ: ${order.note}'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!cancelled) ...[
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ความคืบหน้า',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(steps.length, (i) {
                          final passed = i <= currentIndex;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                Icon(
                                  passed
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: passed
                                      ? const Color(0xFF359261)
                                      : Colors.blueGrey.shade300,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  OrderStatus.labels[steps[i]] ?? '',
                                  style: TextStyle(
                                    fontWeight: i == currentIndex
                                        ? FontWeight.w800
                                        : FontWeight.normal,
                                    color: passed
                                        ? null
                                        : Colors.blueGrey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (order.status == OrderStatus.pending)
                OutlinedButton(
                  onPressed: () => db.cancelOrder(order.id),
                  child: const Text('ยกเลิกออร์เดอร์'),
                ),
              if (order.status == OrderStatus.ready)
                FilledButton(
                  onPressed: () => db.advanceStatus(order.id, order.status),
                  child: const Text('ยืนยันว่าได้รับอาหารแล้ว'),
                ),
            ],
          );
        },
      ),
    );
  }
}
