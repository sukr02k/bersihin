import 'package:equatable/equatable.dart';

enum ExpenseCategory {
  bahanBaku,
  operasional,
  gaji,
  perawatan,
  lainnya,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get value {
    switch (this) {
      case ExpenseCategory.bahanBaku:
        return 'bahan_baku';
      case ExpenseCategory.operasional:
        return 'operasional';
      case ExpenseCategory.gaji:
        return 'gaji';
      case ExpenseCategory.perawatan:
        return 'perawatan';
      case ExpenseCategory.lainnya:
        return 'lainnya';
    }
  }

  String get displayName {
    switch (this) {
      case ExpenseCategory.bahanBaku:
        return 'Bahan Baku & Deterjen';
      case ExpenseCategory.operasional:
        return 'Listrik, Air & Gas';
      case ExpenseCategory.gaji:
        return 'Gaji Karyawan';
      case ExpenseCategory.perawatan:
        return 'Perawatan Mesin';
      case ExpenseCategory.lainnya:
        return 'Operasional Lainnya';
    }
  }

  static ExpenseCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'bahan_baku':
        return ExpenseCategory.bahanBaku;
      case 'operasional':
        return ExpenseCategory.operasional;
      case 'gaji':
        return ExpenseCategory.gaji;
      case 'perawatan':
        return ExpenseCategory.perawatan;
      default:
        return ExpenseCategory.lainnya;
    }
  }
}

class Expense extends Equatable {
  final int? id;
  final String title;
  final ExpenseCategory category;
  final int amount;
  final DateTime expenseDate;
  final String? notes;
  final int? createdBy;
  final DateTime? createdAt;

  const Expense({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: ExpenseCategoryExtension.fromString(map['category'] as String),
      amount: map['amount'] as int,
      expenseDate: DateTime.parse(map['expense_date'] as String),
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'category': category.value,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String(),
      'notes': notes,
      'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Expense copyWith({
    int? id,
    String? title,
    ExpenseCategory? category,
    int? amount,
    DateTime? expenseDate,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        amount,
        expenseDate,
        notes,
        createdBy,
        createdAt,
      ];
}
