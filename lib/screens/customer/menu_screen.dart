import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/food_order.dart';
import '../../../models/menu_item.dart';
import '../../../models/shop.dart';
import '../../../services/db.dart';
import 'order_track_screen.dart';
import '../../widgets/menu_image.dart';

/// หน้าเมนูและตะกร้าของลูกค้า
///
/// ฟังสองกระแสข้อมูลพร้อมกัน
/// กระแสที่ 1 : เอกสารร้าน -> ดูว่ายังเปิดอยู่หรือไม่
/// กระแสที่ 2 : รายการเมนู -> ดูว่าเมนูใดของหมด
/// เมื่อร้านปิดสวิตช์หรือกดเมนูของหมดบนอีกเครื่อง
/// หน้าจอนี้จะเปลี่ยนทันทีทั้งที่ลูกค้าไม่ได้ทำำอะไรเลย
class MenuScreen extends StatefulWidget {
  final Shop shop;
  final User user;
  const MenuScreen({super.key, required this.shop, required this.user});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _db = Db();
  final _noteCtrl = TextEditingController();

  /// ตะกร้าเก็บไว้ในหน่วยความจำำของหน้าจอเท่านั้น
  /// ยังไม่บันทึกลงฐานข้อมูลจนกว่าจะกดยืนยันสั่งซื้อ
  /// key = รหัสเมนู, value = จำำนวน
  final Map<String, int> _cart = {};

  /// เก็บข้อมูลเมนูล่าสุดไว้ใช้ตอนสร้างออร์เดอร์
  List<MenuItem> _menu = [];
  bool _placing = false;
  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  num get _total {
    num sum = 0;
    for (final m in _menu) {
      if (!m.available) continue;
      final qty = _cart[m.id] ?? 0;
      sum += m.price * qty;
    }
    return sum;
  }

  bool get _hasOrderableItems =>
      _menu.any((m) => m.available && (_cart[m.id] ?? 0) > 0);

  void _showFoodImage(MenuItem item) {
    final imageBytes = item.imageBytes;
    if (imageBytes == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.memory(imageBytes, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    // แปลงตะกร้าให้เป็นรายการอาหารของออร์เดอร์
    final items = <OrderItem>[];
    for (final m in _menu) {
      final qty = _cart[m.id] ?? 0;
      if (qty > 0 && m.available) {
        items.add(
          OrderItem(
            menuId: m.id,
            name: m.name,
            price: m.price,
            qty: qty,
          ),
        );
      }
    }
    if (items.isEmpty) return;
    setState(() => _placing = true);
    try {
      final orderId = await _db.placeOrder(
        shop: widget.shop,
        customerId: widget.user.uid,
        customerName: widget.user.displayName ?? 'ลูกค้า',
        items: items,
        note: _noteCtrl.text,
      );
      if (!mounted) return;
      // แทนที่หน้านี้ด้วยหน้าติดตามสถานะ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderTrackScreen(orderId: orderId)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('สั่งซื้อไม่สำำเร็จ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.shop.name)),
      body: StreamBuilder<Shop>(
        stream: _db.watchShop(widget.shop.id),
        builder: (context, shopSnap) {
          final isOpen = shopSnap.data?.isOpen ?? false;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2ED),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Color(0xFF557C70),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.shop.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isOpen
                                    ? 'เลือกเมนูที่อยากทานได้เลย'
                                    : 'ร้านปิดอยู่ ยังไม่รับออร์เดอร์',
                                style: TextStyle(
                                  color: isOpen
                                      ? Colors.blueGrey.shade600
                                      : Colors.deepOrange.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isOpen ? Icons.check_circle : Icons.schedule,
                          color: isOpen
                              ? const Color(0xFF359261)
                              : Colors.deepOrange.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'เมนูจากร้าน',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<MenuItem>>(
                  stream: _db.watchMenu(widget.shop.id),
                  builder: (context, menuSnap) {
                    if (menuSnap.hasError) {
                      return Center(child: Text('ผิดพลาด: ${menuSnap.error}'));
                    }
                    if (!menuSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    _menu = menuSnap.data!;
                    if (_menu.isEmpty) {
                      return Center(
                        child: Text(
                          'ร้านนี้ยังไม่มีเมนู',
                          style: TextStyle(color: Colors.blueGrey.shade500),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                      itemCount: _menu.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final m = _menu[i];
                        final qty = m.available ? (_cart[m.id] ?? 0) : 0;
                        final canOrder = isOpen && m.available;
                        return Card(
                          color: m.available
                              ? Colors.white
                              : const Color(0xFFF0F2F1),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: m.imageBytes == null
                                      ? null
                                      : () => _showFoodImage(m),
                                  borderRadius: BorderRadius.circular(12),
                                  child: MenuImage(
                                    bytes: m.imageBytes,
                                    size: 84,
                                    grayscale: !m.available,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: m.available
                                                  ? null
                                                  : Colors.blueGrey.shade600,
                                            ),
                                      ),
                                      const SizedBox(height: 5),
                                      if (!m.available)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE1E5E3),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: const Text(
                                            'หมดชั่วคราว',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${m.price} บาท',
                                        style: TextStyle(
                                          color: m.available
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Colors.blueGrey.shade500,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 36,
                                            height: 36,
                                          ),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed: qty == 0
                                          ? null
                                          : () => setState(
                                              () => _cart[m.id] = qty - 1,
                                            ),
                                    ),
                                    Text(
                                      '$qty',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      visualDensity: VisualDensity.compact,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 36,
                                            height: 36,
                                          ),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.add),
                                      onPressed: !canOrder
                                          ? null
                                          : () => setState(
                                              () => _cart[m.id] = qty + 1,
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_hasOrderableItems)
                SafeArea(
                  top: false,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        children: [
                          TextField(
                            controller: _noteCtrl,
                            decoration: const InputDecoration(
                              labelText: 'หมายเหตุถึงร้าน (ไม่บังคับ)',
                              prefixIcon: Icon(Icons.edit_note_rounded),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: (!isOpen || _placing)
                                  ? null
                                  : _placeOrder,
                              child: _placing
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      'สั่งอาหาร · รวม $_total บาท',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
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
