

class ProfitReportModel {
  final DateTime from;
  final DateTime to;
  final ProfitTotals totals;
  final InventorySummary closingInventory;
  final List<DailyProfitStat> daily;
  final List<TopProfitProduct> topProducts;

  const ProfitReportModel({
    required this.from,
    required this.to,
    required this.totals,
    required this.closingInventory,
    required this.daily,
    required this.topProducts,
  });

  factory ProfitReportModel.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>;
    return ProfitReportModel(
      from: DateTime.parse(period['from'] as String),
      to: DateTime.parse(period['to'] as String),
      totals: ProfitTotals.fromJson(json['totals'] as Map<String, dynamic>),
      // Safely handle missing closing inventory
      closingInventory: InventorySummary.fromJson(
        json['closingInventory'] as Map<String, dynamic>? ?? {},
      ),
      daily: (json['daily'] as List? ?? [])
          .map((d) => DailyProfitStat.fromJson(d as Map<String, dynamic>))
          .toList(),
      topProducts: (json['topProducts'] as List? ?? [])
          .map((p) => TopProfitProduct.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProfitTotals {
  final double revenue;
  final double cost;
  final double profit;
  final double margin;
  final int orders;
  final int itemsSold;
  final double totalDiscount;

  const ProfitTotals({
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.margin,
    required this.orders,
    required this.itemsSold,
    required this.totalDiscount,
  });

  factory ProfitTotals.fromJson(Map<String, dynamic> json) => ProfitTotals(
        revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
        cost: (json['cost'] as num?)?.toDouble() ?? 0,
        profit: (json['profit'] as num?)?.toDouble() ?? 0,
        margin: (json['margin'] as num?)?.toDouble() ?? 0,
        orders: (json['orders'] as num?)?.toInt() ?? 0,
        itemsSold: (json['itemsSold'] as num?)?.toInt() ?? 0,
        totalDiscount: (json['totalDiscount'] as num?)?.toDouble() ?? 0,
      );
}

// ★ Updated: Only contains what the new backend calculates
class InventorySummary {
  final double stockCostValue;
  final int totalItems;

  const InventorySummary({
    this.stockCostValue = 0,
    this.totalItems = 0,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> json) =>
      InventorySummary(
        stockCostValue: (json['stockCostValue'] as num?)?.toDouble() ?? 0,
        totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      );
}

class DailyProfitStat {
  final DateTime date;
  final double revenue;
  final double cost;
  final double profit;
  final int orders;
  final int items;
  final double discount;

  const DailyProfitStat({
    required this.date,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.orders,
    required this.items,
    required this.discount,
  });

  factory DailyProfitStat.fromJson(Map<String, dynamic> json) =>
      DailyProfitStat(
        date: DateTime.parse(json['date'] as String),
        revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
        cost: (json['cost'] as num?)?.toDouble() ?? 0,
        profit: (json['profit'] as num?)?.toDouble() ?? 0,
        orders: (json['orders'] as num?)?.toInt() ?? 0,
        items: (json['items'] as num?)?.toInt() ?? 0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
      );
}

class TopProfitProduct {
  final String productId;
  final String productName;
  final int quantity;
  final double revenue;
  final double cost;
  final double profit;

  const TopProfitProduct({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.revenue,
    required this.cost,
    required this.profit,
  });

  factory TopProfitProduct.fromJson(Map<String, dynamic> json) =>
      TopProfitProduct(
        productId: json['productId'] as String? ?? '',
        productName: json['productName'] as String? ?? 'Unknown',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
        cost: (json['cost'] as num?)?.toDouble() ?? 0,
        profit: (json['profit'] as num?)?.toDouble() ?? 0,
      );
}