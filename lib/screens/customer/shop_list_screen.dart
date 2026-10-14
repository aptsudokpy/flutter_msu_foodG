import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/shop.dart';
import '../../services/auth_service.dart';
import '../../services/db.dart';
import 'menu_screen.dart';
import 'my_orders_screen.dart';

class ShopListScreen extends StatefulWidget {
  final User user;
  const ShopListScreen({super.key, required this.user});

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  final _searchController = TextEditingController();
  bool _openOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = Db();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.restaurant_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('MSU Food', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'ออร์เดอร์ของฉัน',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MyOrdersScreen(user: widget.user)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'ออกจากระบบ',
            onPressed: () => AuthService().signOut(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<List<Shop>>(
        stream: db.watchShops(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('โหลดร้านค้าไม่สำเร็จ: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allShops = snap.data!;
          final query = _searchController.text.trim().toLowerCase();
          final shops = allShops.where((shop) {
            return (!_openOnly || shop.isOpen) &&
                (query.isEmpty || shop.name.toLowerCase().contains(query));
          }).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF285E50), Color(0xFF6FA18B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'หิวแล้วใช่ไหม?',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'เลือกร้านโปรด แล้วสั่งเมนูที่ใช่ได้เลย',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.ramen_dining_rounded, color: Colors.white, size: 48),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'ค้นหาร้านอาหาร',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'ล้างคำค้นหา',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ร้านอาหาร',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  FilterChip(
                    label: const Text('เปิดอยู่'),
                    avatar: Icon(
                      Icons.circle,
                      size: 10,
                      color: _openOnly ? Colors.white : const Color(0xFF3E9B68),
                    ),
                    selected: _openOnly,
                    onSelected: (selected) => setState(() => _openOnly = selected),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (allShops.isEmpty)
                const _EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'ยังไม่มีร้านค้า',
                  detail: 'ร้านอาหารจะแสดงที่นี่เมื่อพร้อมให้บริการ',
                )
              else if (shops.isEmpty)
                const _EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'ไม่พบร้านที่ค้นหา',
                  detail: 'ลองเปลี่ยนคำค้นหาหรือเลือกดูร้านทั้งหมด',
                )
              else
                ...shops.map(
                  (shop) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShopCard(
                      shop: shop,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MenuScreen(shop: shop, user: widget.user),
                        ),
                      ),
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

class _ShopCard extends StatelessWidget {
  final Shop shop;
  final VoidCallback onTap;
  const _ShopCard({required this.shop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = shop.isOpen ? const Color(0xFF298653) : Colors.blueGrey;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.storefront_rounded, size: 32, color: Color(0xFF557C70)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 9, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          shop.isOpen ? 'เปิดรับออร์เดอร์' : 'ร้านปิดชั่วคราว',
                          style: TextStyle(color: statusColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.blueGrey.shade300),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(detail, textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey.shade500)),
        ],
      ),
    );
  }
}
