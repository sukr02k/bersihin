import 'package:flutter_laundry_offline_app/data/database/database_helper.dart';

class DemoDataService {
  static final DemoDataService _instance = DemoDataService._internal();
  factory DemoDataService() => _instance;
  DemoDataService._internal();

  /// Seed realistic portfolio demo data (customers, 7-day orders, payments, expenses)
  Future<void> seedDemoData() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      // Clean up any previous demo data first so seeding is idempotent
      await txn.delete(
        'orders',
        where: "invoice_no LIKE 'BRSH-DEMO-%'",
      );
      await txn.delete(
        'expenses',
        where: "notes LIKE '%[DEMO]%'",
      );

      // Ensure default services exist and fetch their IDs
      final services = await txn.query('services');
      final serviceRegulerId = services.isNotEmpty ? services.first['id'] as int : null;

      // Upsert 4 realistic customers
      final demoCustomers = [
        {
          'name': 'Budi Santoso',
          'phone': '081234567801',
          'address': 'Jl. Merdeka No. 45, Jakarta Selatan',
          'notes': 'Pelanggan langganan mingguan (suka pewangi Ocean Fresh)',
          'total_orders': 12,
          'total_spent': 680000,
        },
        {
          'name': 'Siti Aminah',
          'phone': '081298765402',
          'address': 'Komp. Griya Asri Blok C2 No. 10',
          'notes': 'Pisahkan pakaian putih',
          'total_orders': 6,
          'total_spent': 320000,
        },
        {
          'name': 'Andi Pratama',
          'phone': '081355667703',
          'address': 'Apartemen Emerald Tower B Lt. 12',
          'notes': 'Sering pakai layanan Express',
          'total_orders': 15,
          'total_spent': 890000,
        },
        {
          'name': 'Rina Kartika',
          'phone': '085711223304',
          'address': 'Jl. Melati Indah No. 8',
          'notes': null,
          'total_orders': 3,
          'total_spent': 155000,
        },
      ];

      final customerIds = <int>[];
      for (final c in demoCustomers) {
        final existing = await txn.query(
          'customers',
          where: 'phone = ?',
          whereArgs: [c['phone']],
        );
        if (existing.isNotEmpty) {
          final id = existing.first['id'] as int;
          await txn.update(
            'customers',
            {
              ...c,
              'last_order_date': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [id],
          );
          customerIds.add(id);
        } else {
          final id = await txn.insert('customers', {
            ...c,
            'last_order_date': now.toIso8601String(),
            'created_at': now.subtract(const Duration(days: 60)).toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
          customerIds.add(id);
        }
      }

      // Helper to insert a demo order with items and optional payment
      Future<void> insertDemoOrder({
        required String code,
        required int customerIdx,
        required int daysAgo,
        required int dueDaysOffset,
        required String status,
        required List<Map<String, dynamic>> items,
        int discount = 0,
        required int paid,
        String paymentMethod = 'cash',
        String? notes,
      }) async {
        final orderDate = now.subtract(Duration(days: daysAgo));
        final dueDate = now.add(Duration(days: dueDaysOffset));
        final cust = demoCustomers[customerIdx];
        final custId = customerIds[customerIdx];

        int subtotal = 0;
        double totalWeight = 0;
        for (final item in items) {
          subtotal += item['subtotal'] as int;
          if ((item['unit'] as String).toLowerCase() == 'kg') {
            totalWeight += (item['quantity'] as num).toDouble();
          }
        }
        final totalPrice = subtotal - discount;

        final orderId = await txn.insert('orders', {
          'invoice_no': 'BRSH-DEMO-$code',
          'customer_id': custId,
          'customer_name': cust['name'],
          'customer_phone': cust['phone'],
          'order_date': orderDate.toIso8601String(),
          'due_date': dueDate.toIso8601String(),
          'status': status,
          'total_items': items.length,
          'total_weight': totalWeight,
          'discount': discount,
          'total_price': totalPrice,
          'paid': status == 'cancelled' ? 0 : paid,
          'notes': notes,
          'created_by': 1,
          'created_at': orderDate.toIso8601String(),
          'updated_at': orderDate.toIso8601String(),
        });

        for (final item in items) {
          await txn.insert('order_items', {
            'order_id': orderId,
            'service_id': serviceRegulerId,
            'service_name': item['service_name'],
            'quantity': item['quantity'],
            'unit': item['unit'],
            'price_per_unit': item['price_per_unit'],
            'subtotal': item['subtotal'],
          });
        }

        if (paid > 0 && status != 'cancelled') {
          await txn.insert('payments', {
            'order_id': orderId,
            'amount': paid,
            'change': 0,
            'payment_date': orderDate.toIso8601String(),
            'payment_method': paymentMethod,
            'notes': 'Pembayaran order demo',
            'received_by': 1,
            'created_at': orderDate.toIso8601String(),
          });
        }
      }

      // 1. 5 days ago - Done & Paid
      await insertDemoOrder(
        code: '0001',
        customerIdx: 0,
        daysAgo: 5,
        dueDaysOffset: -2,
        status: 'done',
        items: [
          {
            'service_name': 'Cuci Setrika Reguler',
            'quantity': 6.0,
            'unit': 'kg',
            'price_per_unit': 7000,
            'subtotal': 42000,
          },
          {
            'service_name': 'Bed Cover Besar',
            'quantity': 1.0,
            'unit': 'pcs',
            'price_per_unit': 25000,
            'subtotal': 25000,
          },
        ],
        paid: 67000,
        paymentMethod: 'qris',
      );

      // 2. 4 days ago - Done & Paid
      await insertDemoOrder(
        code: '0002',
        customerIdx: 1,
        daysAgo: 4,
        dueDaysOffset: -1,
        status: 'done',
        items: [
          {
            'service_name': 'Cuci Setrika Express',
            'quantity': 4.5,
            'unit': 'kg',
            'price_per_unit': 12000,
            'subtotal': 54000,
          },
        ],
        discount: 4000,
        paid: 50000,
        paymentMethod: 'cash',
      );

      // 3. 3 days ago - Done & Paid
      await insertDemoOrder(
        code: '0003',
        customerIdx: 2,
        daysAgo: 3,
        dueDaysOffset: -1,
        status: 'done',
        items: [
          {
            'service_name': 'Cuci Setrika Reguler',
            'quantity': 8.0,
            'unit': 'kg',
            'price_per_unit': 7000,
            'subtotal': 56000,
          },
          {
            'service_name': 'Sepatu',
            'quantity': 2.0,
            'unit': 'pasang',
            'price_per_unit': 25000,
            'subtotal': 50000,
          },
        ],
        discount: 6000,
        paid: 100000,
        paymentMethod: 'transfer',
      );

      // 4. 2 days ago - OVERDUE (Process, due yesterday!) -> triggers Overdue Banner
      await insertDemoOrder(
        code: '0004',
        customerIdx: 3,
        daysAgo: 3,
        dueDaysOffset: -1,
        status: 'process',
        items: [
          {
            'service_name': 'Cuci Setrika Reguler',
            'quantity': 5.0,
            'unit': 'kg',
            'price_per_unit': 7000,
            'subtotal': 35000,
          },
          {
            'service_name': 'Selimut',
            'quantity': 2.0,
            'unit': 'pcs',
            'price_per_unit': 15000,
            'subtotal': 30000,
          },
        ],
        paid: 30000,
        paymentMethod: 'cash',
        notes: 'Jangan pakai pemutih, ambil sore',
      );

      // 5. Yesterday - Ready for pickup (Siap Ambil)
      await insertDemoOrder(
        code: '0005',
        customerIdx: 0,
        daysAgo: 1,
        dueDaysOffset: 1,
        status: 'ready',
        items: [
          {
            'service_name': 'Cuci Setrika Express',
            'quantity': 5.0,
            'unit': 'kg',
            'price_per_unit': 12000,
            'subtotal': 60000,
          },
        ],
        discount: 6000,
        paid: 54000,
        paymentMethod: 'qris',
        notes: 'Promo pelanggan loyal 10%',
      );

      // 6. Today - Process (Dikerjakan hari ini)
      await insertDemoOrder(
        code: '0006',
        customerIdx: 2,
        daysAgo: 0,
        dueDaysOffset: 2,
        status: 'process',
        items: [
          {
            'service_name': 'Cuci Setrika Reguler',
            'quantity': 7.0,
            'unit': 'kg',
            'price_per_unit': 7000,
            'subtotal': 49000,
          },
        ],
        paid: 25000,
        paymentMethod: 'cash',
      );

      // 7. Today - Pending (Baru masuk hari ini)
      await insertDemoOrder(
        code: '0007',
        customerIdx: 1,
        daysAgo: 0,
        dueDaysOffset: 3,
        status: 'pending',
        items: [
          {
            'service_name': 'Cuci Lipat Reguler',
            'quantity': 4.0,
            'unit': 'kg',
            'price_per_unit': 5000,
            'subtotal': 20000,
          },
          {
            'service_name': 'Boneka Sedang',
            'quantity': 2.0,
            'unit': 'pcs',
            'price_per_unit': 15000,
            'subtotal': 30000,
          },
        ],
        paid: 0,
      );

      // 8. Yesterday - Cancelled (Void order example)
      await insertDemoOrder(
        code: '0008',
        customerIdx: 3,
        daysAgo: 1,
        dueDaysOffset: 2,
        status: 'cancelled',
        items: [
          {
            'service_name': 'Setrika Saja',
            'quantity': 3.0,
            'unit': 'kg',
            'price_per_unit': 4000,
            'subtotal': 12000,
          },
        ],
        paid: 0,
        notes: 'Dibatalkan karena pelanggan salah pilih paket',
      );

      // Seed operational expenses
      final demoExpenses = [
        {
          'title': 'Deterjen Cair Ultra 10L & Parfum Laundry',
          'category': 'bahan_baku',
          'amount': 85000,
          'daysAgo': 4,
          'notes': 'Stok bulanan [DEMO]',
        },
        {
          'title': 'Token Listrik & Tagihan Air PDAM',
          'category': 'utilitas',
          'amount': 65000,
          'daysAgo': 2,
          'notes': 'Operasional mingguan [DEMO]',
        },
        {
          'title': 'Plastik Packing Laundry & Hanger',
          'category': 'bahan_baku',
          'amount': 35000,
          'daysAgo': 1,
          'notes': 'Perlengkapan packing [DEMO]',
        },
      ];

      for (final exp in demoExpenses) {
        final expDate = now.subtract(Duration(days: exp['daysAgo'] as int));
        await txn.insert('expenses', {
          'title': exp['title'],
          'category': exp['category'],
          'amount': exp['amount'],
          'expense_date': expDate.toIso8601String(),
          'notes': exp['notes'],
          'created_by': 1,
          'created_at': expDate.toIso8601String(),
        });
      }
    });
  }
}
