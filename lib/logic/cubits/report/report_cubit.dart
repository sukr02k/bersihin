import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_laundry_offline_app/data/models/expense.dart';
import 'package:flutter_laundry_offline_app/data/repositories/expense_repository.dart';
import 'package:flutter_laundry_offline_app/data/repositories/report_repository.dart';
import 'package:flutter_laundry_offline_app/core/services/export_service.dart';
import 'package:flutter_laundry_offline_app/logic/cubits/report/report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  final ReportRepository _reportRepository;
  final ExpenseRepository _expenseRepository;
  final ExportService _exportService;

  ReportCubit({
    ReportRepository? reportRepository,
    ExpenseRepository? expenseRepository,
    ExportService? exportService,
  })  : _reportRepository = reportRepository ?? ReportRepository(),
        _expenseRepository = expenseRepository ?? ExpenseRepository(),
        _exportService = exportService ?? ExportService(),
        super(const ReportInitial());

  /// Load report data
  Future<void> loadReport(DateTime startDate, DateTime endDate) async {
    emit(const ReportLoading());

    try {
      final data = await _reportRepository.getReportData(startDate, endDate);
      final orders =
          await _reportRepository.getOrdersByDateRange(startDate, endDate);

      emit(ReportLoaded(data: data, orders: orders));
    } catch (e) {
      emit(ReportError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Add new expense and refresh report
  Future<void> addExpense({
    required String title,
    required ExpenseCategory category,
    required int amount,
    required DateTime expenseDate,
    String? notes,
    int? createdBy,
    required DateTime currentStartDate,
    required DateTime currentEndDate,
  }) async {
    try {
      await _expenseRepository.createExpense(
        Expense(
          title: title,
          category: category,
          amount: amount,
          expenseDate: expenseDate,
          notes: notes,
          createdBy: createdBy,
        ),
      );
      await loadReport(currentStartDate, currentEndDate);
    } catch (e) {
      emit(ReportError('Gagal menyimpan pengeluaran: $e'));
    }
  }

  /// Delete an expense and refresh report
  Future<void> deleteExpense({
    required int id,
    required DateTime currentStartDate,
    required DateTime currentEndDate,
  }) async {
    try {
      await _expenseRepository.deleteExpense(id);
      await loadReport(currentStartDate, currentEndDate);
    } catch (e) {
      emit(ReportError('Gagal menghapus pengeluaran: $e'));
    }
  }

  /// Export report to Excel
  Future<void> exportToExcel() async {
    final currentState = state;
    if (currentState is! ReportLoaded) return;

    emit(const ReportExporting());

    try {
      final filePath = await _exportService.exportOrdersToExcel(
        currentState.orders,
        currentState.data,
      );

      // Share the file
      await _exportService.shareFile(filePath);

      emit(ReportExported(
        filePath: filePath,
        message: 'Laporan berhasil di-export',
      ));

      // Restore previous state
      emit(currentState);
    } catch (e) {
      emit(ReportError(e.toString().replaceAll('Exception: ', '')));
      emit(currentState);
    }
  }
}
