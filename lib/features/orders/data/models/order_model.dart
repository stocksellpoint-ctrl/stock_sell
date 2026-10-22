




import 'order_item_model.dart';

class OrderModel {
  final String? id;
  final String customerId;
  final String customerName;
  final String customerPhone; // ★ NEW: Added for invoice
  final List<OrderItemModel> items;

  final double subtotal;
  final double discountAmount;
  final double total;

  final String status;
  final DateTime createdAt;
  final String? notes;

  const OrderModel({
    this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhone = '', // Default to empty for old orders
    required this.items,

    this.subtotal = 0,
    this.discountAmount = 0,
    required this.total,

    this.status = 'pending',
    required this.createdAt,
    this.notes,
  });

  bool get hasDiscount => discountAmount > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'discountAmount': discountAmount,
        'total': total,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };

  Map<String, dynamic> toApiJson() => {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((i) => i.toApiJson()).toList(),
      // total is sent but backend re-calculates it from items
      'total': total,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id']?.toString(),
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        customerPhone: json['customerPhone'] as String? ?? '',
        items: (json['items'] as List)
            .map((j) => OrderItemModel.fromJson(j as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num).toDouble(),
        status: json['status'] as String? ?? 'pending',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        notes: json['notes'] as String?,
      );

  factory OrderModel.fromApiJson(Map<String, dynamic> json) => OrderModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String? ?? '',
      items: (json['items'] as List)
          .map((i) => OrderItemModel.fromApiJson(i as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      notes: json['notes'] as String?,
    );
}