import 'package:flutter_laundry_offline_app/data/database/database_helper.dart';
import 'package:flutter_laundry_offline_app/data/models/expense.dart';

class ExpenseRepository {
  final DatabaseHelper _databaseHelper;

  ExpenseRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  /// Get all expenses within a date range
  Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final result = await db.query(
      'expenses',
      where: 'expense_date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'expense_date DESC, id DESC',
    );

    return result.map((map) => Expense.fromMap(map)).toList();
  }

  /// Create a new operational expense
  Future<Expense> createExpense(Expense expense) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();

    final id = await db.insert('expenses', {
      'title': expense.title,
      'category': expense.category.value,
      'amount': expense.amount,
      'expense_date': expense.expenseDate.toIso8601String(),
      'notes': expense.notes,
      'created_by': expense.createdBy,
      'created_at': now.toIso8601String(),
    });

    return expense.copyWith(id: id, createdAt: now);
  }

  /// Delete an expense by ID
  Future<void> deleteExpense(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
