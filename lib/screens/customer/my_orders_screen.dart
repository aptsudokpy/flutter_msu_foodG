import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/food_order.dart';
import '../../services/db.dart';
import 'order_track_screen.dart';

class MyOrdersScreen extends StatelessWidget {
  final User user;
  const MyOrdersScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d/M/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('ออร์เดอร์ของฉัน')),
      body: StreamBuilder<List<FoodOrder>>(
        stream: Db().watchMyOrders(user.uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('โหลดออร์เดอร์ไม่สำเร็จ: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snap.data!;
          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 58, color: Colors.blueGrey.shade300),
                    const SizedBox(height: 14),
                    const Text('ยังไม่มีออร์เดอร์', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('เมื่อคุณสั่งอาหาร รายการจะปรากฏที่นี่', style: TextStyle(color: Colors.blueGrey.shade500)),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final order = orders[i];
              final when = order.createdAt == null
                  ? 'กำลังส่งข้อมูล...'
                  : fmt.format(order.createdAt!);
              final isActive = OrderStatus.active.contains(order.status);
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderTrackScreen(orderId: order.id),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF2ED),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Color(0xFF557C70),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(order.shopName, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 3),
                                  Text(when, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade500)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${order.items.length} รายการ · ${order.total} บาท',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFE7F2EB)
                                    : const Color(0xFFF0F1F1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                OrderStatus.labels[order.status] ?? '',
                                style: TextStyle(
                                  color: isActive
                                      ? const Color(0xFF287548)
                                      : Colors.blueGrey.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
