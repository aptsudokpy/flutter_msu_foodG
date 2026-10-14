import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/shop.dart';
import '../../models/menu_item.dart';
import '../../models/food_order.dart';
import '../../services/auth_service.dart';
import '../../services/db.dart';
import '../../widgets/menu_image.dart';
import 'menu_manage_screen.dart';
import 'order_history_screen.dart';
import 'shop_profile_screen.dart';

class OrderBoardScreen extends StatelessWidget {
  final User user;
  final String shopId;
  const OrderBoardScreen({super.key, required this.user, required this.shopId});
  @override
  Widget build(BuildContext context) {
    final db = Db();
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ศูนย์ออร์เดอร์',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text('จัดการคำสั่งซื้อของร้าน', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'จัดการร้าน',
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (value) {
              final page = switch (value) {
                'menu' => MenuManageScreen(shopId: shopId),
                'history' => OrderHistoryScreen(shopId: shopId),
                _ => ShopProfileScreen(shopId: shopId),
              };
              Navigator.push(context, MaterialPageRoute(builder: (_) => page));
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'menu',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.restaurant_menu_rounded),
                  title: Text('จัดการเมนู'),
                ),
              ),
              PopupMenuItem(
                value: 'history',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.history_rounded),
                  title: Text('ประวัติออร์เดอร์'),
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.storefront_outlined),
                  title: Text('โปรไฟล์ร้าน'),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'ออกจากระบบ',
            onPressed: () => AuthService().signOut(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<Shop>(
            stream: db.watchShop(shopId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                );
              }
              final shop = snap.data!;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Card(
                  color: shop.isOpen
                      ? const Color(0xFFEAF3ED)
                      : const Color(0xFFF0F1F1),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            shop.isOpen
                                ? Icons.storefront_rounded
                                : Icons.store_mall_directory_outlined,
                            color: shop.isOpen
                                ? const Color(0xFF298653)
                                : Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                shop.isOpen
                                    ? 'กำลังรับออร์เดอร์'
                                    : 'หยุดรับออร์เดอร์ชั่วคราว',
                                style: TextStyle(
                                  color: shop.isOpen
                                      ? const Color(0xFF287548)
                                      : Colors.blueGrey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: shop.isOpen,
                          onChanged: (value) => db.setShopOpen(shopId, value),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'ออร์เดอร์ที่กำลังดำเนินการ',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.bolt_rounded,
                  size: 18,
                  color: Color(0xFFD58A28),
                ),
                const SizedBox(width: 4),
                Text(
                  'เรียลไทม์',
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MenuItem>>(
              stream: db.watchMenu(shopId),
              builder: (context, menuSnap) {
                if (menuSnap.hasError) {
                  return Center(
                    child: Text('โหลดรูปเมนูไม่สำเร็จ: ${menuSnap.error}'),
                  );
                }
                final menuItems = menuSnap.data ?? const <MenuItem>[];
                return StreamBuilder<List<FoodOrder>>(
                  stream: db.watchShopOrders(shopId),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(child: Text('ผิดพลาด: ${snap.error}'));
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
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 54,
                                color: Colors.blueGrey.shade300,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'ยังไม่มีออร์เดอร์ใหม่',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'เมื่อมีลูกค้าสั่งอาหาร รายการจะแสดงที่นี่',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.blueGrey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                      itemCount: orders.length,
                      itemBuilder: (context, i) => _OrderCard(
                        order: orders[i],
                        menuItems: menuItems,
                        db: db,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final FoodOrder order;
  final List<MenuItem> menuItems;
  final Db db;
  const _OrderCard({
    required this.order,
    required this.menuItems,
    required this.db,
  });

  MenuItem? _menuItemFor(OrderItem item) {
    for (final menuItem in menuItems) {
      if (item.menuId != null && menuItem.id == item.menuId) return menuItem;
      if (item.menuId == null && menuItem.name == item.name) return menuItem;
    }
    return null;
  }

  Future<void> _onAction(BuildContext context) async {
    // ถ้ายังเป็น pending ให้ใช้ธุรกรรมเพื่อกันการกดซ้ำ้ำ
    if (order.status == OrderStatus.pending) {
      final error = await db.acceptOrder(order.id);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }
    // สถานะอื่นเลื่อนไปข้างหน้าตามลำำดับได้เลย
    await db.advanceStatus(order.id, order.status);
  }

  @override
  Widget build(BuildContext context) {
    final action = OrderStatus.actionLabel(order.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
                Chip(
                  avatar: Icon(
                    order.status == OrderStatus.pending
                        ? Icons.fiber_new_rounded
                        : Icons.timelapse_rounded,
                    size: 16,
                  ),
                  label: Text(OrderStatus.labels[order.status] ?? ''),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 6            ),
            ...order.items.map((item) {
              final menuItem = _menuItemFor(item);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    MenuImage(bytes: menuItem?.imageBytes, size: 52),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${item.name}  × ${item.qty}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text('${item.subtotal} บาท'),
                  ],
                ),
              );
            }),
            if (order.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'หมายเหตุจากลูกค้า\n${order.note}',
                  style: TextStyle(color: Colors.deepOrange.shade900),
                ),
              ),
            ],
            const Divider(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'รวม ${order.total} บาท',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (order.status == OrderStatus.pending)
                      OutlinedButton(
                        onPressed: () => db.cancelOrder(order.id),
                        child: const Text('ปฏิเสธ'),
                      ),
                    if (action != null)
                      FilledButton(
                        onPressed: () => _onAction(context),
                        child: Text(action),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
