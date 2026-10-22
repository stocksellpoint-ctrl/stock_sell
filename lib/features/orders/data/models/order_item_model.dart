


class OrderItemModel {
  final String productId;
  final String productName;
  final String categoryId;
  final int quantity;
  
  // ★ The actual price sold at the time of sale
  final double sellingPrice;
  
  // ★ The cost at the time of sale
  final double costPrice; 

  final String discountType; // 'none' | 'amount' | 'percent'
  final double discountValue; // user input (AED or %)
  final double discountAmount; // computed per-unit discount in AED

  const OrderItemModel({
    required this.productId,
    required this.productName,
    this.categoryId = '',
    required this.quantity,
    required this.sellingPrice,
    this.costPrice = 0,
    this.discountType = 'none',
    this.discountValue = 0,
    this.discountAmount = 0,
  });

  double get lineSubtotal => sellingPrice * quantity;
  double get lineDiscount => discountAmount * quantity;
  double get lineTotal => lineSubtotal - lineDiscount;
  bool get hasDiscount => discountAmount > 0;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'categoryId': categoryId,
    'quantity': quantity,
    'sellingPrice': sellingPrice,
    'costPrice': costPrice,
    'discountType': discountType,
    'discountValue': discountValue,
  };

  Map<String, dynamic> toApiJson() => {
    'productId': productId,
    'productName': productName,
    'categoryId': categoryId,
    'quantity': quantity,
    'sellingPrice': sellingPrice,
    'costPrice': costPrice,
    'discountType': discountType,
    'discountValue': discountValue,
  };

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    categoryId: json['categoryId'] as String? ?? '',
    quantity: (json['quantity'] as num).toInt(),
    sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
    costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
    discountType: json['discountType'] as String? ?? 'none',
    discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
    discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
  );

  factory OrderItemModel.fromApiJson(Map<String, dynamic> json) =>
      OrderItemModel(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        categoryId: json['categoryId'] as String? ?? '',
        quantity: (json['quantity'] as num).toInt(),
        sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
        costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
        discountType: json['discountType'] as String? ?? 'none',
        discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
        discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      );
}