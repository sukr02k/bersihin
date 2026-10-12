import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_laundry_offline_app/core/utils/currency_formatter.dart';
import 'package:flutter_laundry_offline_app/core/utils/password_helper.dart';
import 'package:flutter_laundry_offline_app/core/utils/thousand_separator_formatter.dart';
import 'package:flutter_laundry_offline_app/data/models/expense.dart';
import 'package:flutter_laundry_offline_app/data/models/order.dart';
import 'package:flutter_laundry_offline_app/logic/cubits/report/report_state.dart';

void main() {
  group('Order Model & Workflow Tests', () {
    final baseOrder = Order(
      id: 1,
      invoiceNo: 'BRSH-261012-0001',
      customerName: 'Budi Santoso',
      customerPhone: '081234567890',
      orderDate: DateTime(2026, 10, 12),
      dueDate: DateTime(2026, 10, 15),
      status: OrderStatus.pending,
      totalItems: 3,
      totalWeight: 5.5,
      totalPrice: 55000,
      paid: 20000,
    );

    test('calculates remainingPayment, hasDeposit, and isPaid accurately', () {
      expect(baseOrder.remainingPayment, 35000);
      expect(baseOrder.hasDeposit, isTrue);
      expect(baseOrder.isPaid, isFalse);

      final paidOrder = baseOrder.copyWith(paid: 55000);
      expect(paidOrder.remainingPayment, 0);
      expect(paidOrder.hasDeposit, isFalse);
      expect(paidOrder.isPaid, isTrue);
    });

    test('normalizes Indonesian phone number to WhatsApp format (62...)', () {
      expect(baseOrder.whatsappNumber, '6281234567890');
    });

    test('validates order status transitions including cancelled status', () {
      expect(baseOrder.getNextStatusOptions(), [OrderStatus.process]);

      final processOrder = baseOrder.copyWith(status: OrderStatus.process);
      expect(
        processOrder.getNextStatusOptions(),
        [OrderStatus.ready, OrderStatus.done],
      );

      final doneOrder = baseOrder.copyWith(status: OrderStatus.done);
      expect(doneOrder.getNextStatusOptions(), isEmpty);

      final cancelledOrder = baseOrder.copyWith(status: OrderStatus.cancelled);
      expect(cancelledOrder.getNextStatusOptions(), isEmpty);
      expect(cancelledOrder.isOverdue, isFalse);
      expect(cancelledOrder.remainingPayment, 0);
      expect(cancelledOrder.isPaid, isFalse);
      expect(cancelledOrder.hasDeposit, isFalse);
    });

    test('calculates subtotal and discount accurately', () {
      final discountedOrder = baseOrder.copyWith(
        discount: 5000,
        totalPrice: 50000,
      );
      expect(discountedOrder.discount, 5000);
      expect(discountedOrder.totalPrice, 50000);
      expect(discountedOrder.subtotal, 55000);
    });

    test('serializes and deserializes Order toMap/fromMap', () {
      final discounted = baseOrder.copyWith(discount: 5000, totalPrice: 50000);
      final map = discounted.toMap();
      final restored = Order.fromMap(map);
      expect(restored, equals(discounted));
      expect(restored.discount, 5000);
    });
  });

  group('Expense Model & Report Net Profit Tests', () {
    test('serializes and deserializes Expense model accurately', () {
      final expense = Expense(
        id: 10,
        title: 'Beli Deterjen Cair 5L',
        category: ExpenseCategory.bahanBaku,
        amount: 75000,
        expenseDate: DateTime(2026, 10, 12),
        notes: 'Stok bulanan',
      );

      final map = expense.toMap();
      final fromMap = Expense.fromMap(map);

      expect(fromMap.id, 10);
      expect(fromMap.title, 'Beli Deterjen Cair 5L');
      expect(fromMap.category, ExpenseCategory.bahanBaku);
      expect(fromMap.category.displayName, 'Bahan Baku & Deterjen');
      expect(fromMap.amount, 75000);
      expect(fromMap.notes, 'Stok bulanan');
    });

    test('calculates netProfit and netCashflow in ReportData', () {
      final report = ReportData(
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 31),
        totalOrders: 25,
        completedOrders: 20,
        pendingOrders: 5,
        totalRevenue: 1500000,
        totalPaid: 1200000,
        totalUnpaid: 300000,
        totalExpenses: 450000,
        ordersByStatus: const {
          OrderStatus.done: 20,
          OrderStatus.process: 5,
        },
        dailyRevenue: const [],
        topServices: const [],
      );

      expect(report.netProfit, 1050000); // 1.500.000 - 450.000
      expect(report.netCashflow, 750000); // 1.200.000 - 450.000
    });
  });

  group('Security & Formatter Utility Tests', () {
    test('PasswordHelper hashes with unique salt and verifies password', () {
      const rawPassword = 'superSecretPassword123';
      final hash1 = PasswordHelper.hashPassword(rawPassword);
      final hash2 = PasswordHelper.hashPassword(rawPassword);

      // Unique salt per call ensures two hashes of same password differ
      expect(hash1, isNot(equals(hash2)));
      expect(PasswordHelper.verifyPassword(rawPassword, hash1), isTrue);
      expect(PasswordHelper.verifyPassword(rawPassword, hash2), isTrue);
      expect(PasswordHelper.verifyPassword('wrongPassword', hash1), isFalse);
    });

    test('CurrencyFormatter and ThousandSeparatorFormatter format & parse IDR', () {
      expect(CurrencyFormatter.parse('Rp 125.000'), 125000);
      expect(ThousandSeparatorFormatter.format(1250000), '1.250.000');
      expect(ThousandSeparatorFormatter.parseToInt('1.250.000'), 1250000);
    });
  });
}
