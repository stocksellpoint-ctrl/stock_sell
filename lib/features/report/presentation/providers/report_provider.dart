import 'package:flutter/material.dart';

import '../../data/datasources/report_remote_datasource.dart';
import '../../data/models/inventory_report_model.dart';
import '../../data/models/profit_report_model.dart';

enum ReportTab { inventory, profit }

enum ProfitPeriod { daily, weekly, fortnightly, monthly, custom }

class ReportProvider extends ChangeNotifier {
  final ReportRemoteDataSource _api = ReportRemoteDataSource();

  ReportTab _tab = ReportTab.inventory;
  InventoryReportModel? _inventoryReport;
  ProfitReportModel? _profitReport;

  ProfitPeriod _profitPeriod = ProfitPeriod.daily;
  DateTimeRange? _customRange;

  bool _isLoading = false;
  String? _error;

  // Getters
  ReportTab get tab => _tab;
  InventoryReportModel? get inventoryReport => _inventoryReport;
  ProfitReportModel? get profitReport => _profitReport;
  ProfitPeriod get profitPeriod => _profitPeriod;
  DateTimeRange? get customRange => _customRange;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Tab switching ──────────────────────────────────────
  Future<void> setTab(ReportTab tab) async {
    _tab = tab;
    notifyListeners();

    if (tab == ReportTab.inventory && _inventoryReport == null) {
      await loadInventory();
    } else if (tab == ReportTab.profit && _profitReport == null) {
      await loadProfit();
    }
  }

  // ── Inventory ──────────────────────────────────────────
  Future<void> loadInventory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _inventoryReport = await _api.inventoryReport();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Profit ─────────────────────────────────────────────
  Future<void> setProfitPeriod(ProfitPeriod period) async {
    _profitPeriod = period;
    if (period == ProfitPeriod.custom && _customRange == null) {
      notifyListeners();
      return;
    }
    await loadProfit();
  }

  Future<void> setCustomRange(DateTimeRange range) async {
    _customRange = range;
    _profitPeriod = ProfitPeriod.custom;
    await loadProfit();
  }

  Future<void> loadProfit() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final range = _resolveRange();
      _profitReport = await _api.profitReport(
        from: range.start,
        to: range.end,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DateTimeRange _resolveRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_profitPeriod) {
      case ProfitPeriod.daily:
        return DateTimeRange(start: today, end: today);

      case ProfitPeriod.weekly:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );

      case ProfitPeriod.fortnightly:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 13)),
          end: today,
        );

      case ProfitPeriod.monthly:
        // Start of current month → today
        return DateTimeRange(
          start: DateTime(today.year, today.month, 1),
          end: today,
        );

      case ProfitPeriod.custom:
        return _customRange ??
            DateTimeRange(start: today, end: today);
    }
  }

  String get profitPeriodLabel {
    switch (_profitPeriod) {
      case ProfitPeriod.daily:
        return 'Today';
      case ProfitPeriod.weekly:
        return 'Last 7 days';
      case ProfitPeriod.fortnightly:
        return 'Last 14 days';
      case ProfitPeriod.monthly:
        final now = DateTime.now();
        return 'This month (${now.year}-${now.month.toString().padLeft(2, '0')})';
      case ProfitPeriod.custom:
        final r = _customRange;
        if (r == null) return 'Custom range';
        return '${_short(r.start)} – ${_short(r.end)}';
    }
  }

  String _short(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}