import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/db.dart';
import 'customer/shop_list_screen.dart';
import 'shop/order_board_screen.dart';

class RoleGate extends StatefulWidget {
  final User user;
  const RoleGate({super.key, required this.user});

  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  bool _showRolePicker = true;

  @override
  Widget build(BuildContext context) {
    final db = Db();
    return StreamBuilder<Map<String, dynamic>?>(
      stream: db.watchProfile(widget.user.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = snap.data;
        if (_showRolePicker || profile == null) {
          return _ChooseRole(
            user: widget.user,
            db: db,
            profile: profile,
            onRoleSelected: () => setState(() => _showRolePicker = false),
          );
        }
        if (profile['role'] == 'shop') {
          return OrderBoardScreen(
            user: widget.user,
            shopId: profile['shopId'] as String,
          );
        }
        return ShopListScreen(user: widget.user);
      },
    );
  }
}

class _ChooseRole extends StatelessWidget {
  final User user;
  final Db db;
  final Map<String, dynamic>? profile;
  final VoidCallback onRoleSelected;
  const _ChooseRole({
    required this.user,
    required this.db,
    required this.profile,
    required this.onRoleSelected,
  });

  Future<void> _pickCustomer() async {
    await db.becomeCustomer(user.uid, user.displayName ?? '');
    onRoleSelected();
  }

  Future<void> _pickShop(BuildContext context) async {
    final existingShopId = profile?['shopId'] as String?;
    if (existingShopId != null && existingShopId.isNotEmpty) {
      await db.switchToShop(user.uid, user.displayName ?? '');
      onRoleSelected();
      return;
    }

    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ตั้งชื่อร้านของคุณ'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'เช่น ครัวคุณยาย',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('สร้างร้าน'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await db.becomeShop(user.uid, user.displayName ?? '', name);
      onRoleSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เลือกบทบาทการใช้งาน')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3ED),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.restaurant_rounded,
                  size: 34,
                  color: Color(0xFF557C70),
                ),
                const SizedBox(height: 12),
                Text(
                  'ยินดีต้อนรับสู่ MSU Food',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'เลือกวิธีใช้งานที่เหมาะกับคุณ สามารถเริ่มต้นได้ทันที',
                  style: TextStyle(color: Colors.blueGrey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'เลือกบทบาท',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _RoleCard(
            icon: Icons.person_outline_rounded,
            title: 'สั่งอาหาร',
            detail: 'เลือกร้าน ดูเมนู และติดตามออร์เดอร์ของคุณ',
            onTap: _pickCustomer,
          ),
          const SizedBox(height: 12),
          _RoleCard(
            icon: Icons.storefront_outlined,
            title: 'จัดการร้านอาหาร',
            detail: 'จัดการเมนู รับออร์เดอร์ และอัปเดตสถานะร้าน',
            onTap: () => _pickShop(context),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: const Color(0xFF557C70)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: TextStyle(
                        color: Colors.blueGrey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
