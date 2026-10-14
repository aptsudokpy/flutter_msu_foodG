import 'package:flutter/material.dart';
import '../../models/shop.dart';
import '../../services/db.dart';

class ShopProfileScreen extends StatelessWidget {
  final String shopId;

  const ShopProfileScreen({super.key, required this.shopId});

  static const _members = [
    ('66010914061', 'สุชาวดี สุระสิงห์'),
    ('66010914068', 'ณหทัย โกสิลา'),
    ('66010914090', 'จักริน อินทราราม'),
    ('66010914154', 'รัชชานนท์ พรดีมา'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์ร้านค้า')),
      body: StreamBuilder<Shop>(
        stream: Db().watchShop(shopId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('ผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('ชื่อร้านค้า', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                snapshot.data!.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Text(
                'สมาชิก (${_members.length} คน)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Divider(),
              for (final member in _members)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(member.$2),
                  subtitle: Text('รหัสประจำตัว ${member.$1}'),
                ),
            ],
          );
        },
      ),
    );
  }
}