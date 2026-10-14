import 'package:flutter/material.dart';
import '../../models/menu_item.dart';
import '../../services/db.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/image_service.dart';
import '../../widgets/menu_image.dart';

/// หน้าจอจัดการเมนูของร้าน — CRUD ครบทั้งสี่การกระทำำ
///
/// C : ปุ่ม + มุมล่างขวา
/// R : StreamBuilder ที่ฟัง watchMenu()
/// U : แตะที่รายการเพื่อแก้ไข และสวิตช์เปิดปิดการขาย
/// D : ปุ่มถังขยะพร้อมกล่องยืนยัน
class MenuManageScreen extends StatelessWidget {
  final String shopId;
  const MenuManageScreen({super.key, required this.shopId});

  /// กล่องโต้ตอบเดียว ใช้ได้ทั้งเพิ่มใหม่และแก้ไขของเดิม
  /// ถ้า item เป็น null คือโหมดเพิ่ม ถ้าไม่ null คือโหมดแก้ไข
  Future<void> _openForm(BuildContext context, Db db, MenuItem? item) async {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final priceCtrl = TextEditingController(
      text: item == null ? '' : '${item.price}',
    );
    final imageService = ImageService();
    // สถานะของรูปภายในฟอร์ม
    String? newImage; // Base64 ของรูปที่เพิ่งเลือก
    bool removeImage = false; // ผู้ใช้กดลบรูปเดิม
    bool saving = false; // กำำลังบันทึก ใช้กันกดซ้ำ้ำ
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // ลำำดับการเลือกรูปตัวอย่าง: รูปใหม่ > รูปเดิม > ไม่มีรูป
          final preview = newImage != null
              ? ImageService.decode(newImage)
              : (removeImage ? null : item?.imageBytes);
          Future<void> pick(ImageSource source) async {
            try {
              final b64 = await imageService.pickAsBase64(source);
              if (b64 == null || !ctx.mounted) return; // ยกเลิก
              setDialogState(() {
                newImage = b64;
                removeImage = false;
              });
            } catch (e) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                ),
              );
            }
          }

          return AlertDialog(
            title: Text(item == null ? 'เพิ่มเมนูใหม่' : 'แก้ไขเมนู'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MenuImage(bytes: preview, size: 120),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'ถ่ายรูป',
                        icon: const Icon(Icons.photo_camera),
                        onPressed: saving
                            ? null
                            : () => pick(ImageSource.camera),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'เลือกจากคลังภาพ',
                        icon: const Icon(Icons.photo_library),
                        onPressed: saving
                            ? null
                            : () => pick(ImageSource.gallery),
                      ),
                      if (preview != null)
                        IconButton(
                          tooltip: 'ลบรูป',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: saving
                              ? null
                              : () => setDialogState(() {
                                  newImage = null;
                                  removeImage = true;
                                }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อเมนู',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ราคา (บาท)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final price = num.tryParse(priceCtrl.text.trim());
                        if (name.isEmpty || price == null) return;
                        setDialogState(() => saving = true);
                        try {
                          if (item == null) {
                            await db.addMenuItem(
                              shopId,
                              name,
                              price,
                              imageBase64: newImage,
                            );
                          } else {
                            await db.updateMenuItem(
                              item.id,
                              name,
                              price,
                              imageBase64: newImage,
                              removeImage: removeImage,
                            );
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          if (!ctx.mounted) return;
                          setDialogState(() => saving = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('บันทึกไม่สำำเร็จ: $e')),
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('บันทึก'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Db db,
    MenuItem item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบเมนู "${item.name}" หรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok == true) await db.deleteMenuItem(item.id); // DELETE
  }

  @override
  Widget build(BuildContext context) {
    final db = Db();
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการเมนู')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, db, null),
        child: const Icon(Icons.add),
      ),
      // READ แบบเรียลไทม์
      body: StreamBuilder<List<MenuItem>>(
        stream: db.watchMenu(shopId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('ผิดพลาด: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 56, color: Colors.blueGrey.shade300),
                    const SizedBox(height: 12),
                    const Text(
                      'ยังไม่มีเมนูอาหาร',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'เพิ่มเมนูพร้อมรูปและราคา เพื่อให้ลูกค้าเลือกสั่งได้',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blueGrey.shade500),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final m = items[i];
              return Card(
                color: m.available ? Colors.white : const Color(0xFFF0F2F1),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openForm(context, db, m),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                    child: Row(
                      children: [
                        MenuImage(bytes: m.imageBytes, size: 68),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: m.available
                                      ? null
                                      : Colors.blueGrey.shade600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${m.price} บาท',
                                style: TextStyle(
                                  color: m.available
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.blueGrey.shade500,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: m.available
                                      ? const Color(0xFFE4F3E9)
                                      : const Color(0xFFE1E5E3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  m.available ? 'พร้อมขาย' : 'สินค้าหมด',
                                  style: TextStyle(
                                    color: m.available
                                        ? const Color(0xFF267447)
                                        : Colors.blueGrey.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: m.available,
                          onChanged: (value) => db.setAvailable(m.id, value),
                        ),
                        IconButton(
                          tooltip: 'ลบเมนู',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => _confirmDelete(context, db, m),
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
