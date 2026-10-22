import '../features/inventory/data/models/product_model.dart';
import '../features/customers/data/models/customer_model.dart';
import '../features/orders/data/models/order_model.dart';
import '../features/orders/data/models/order_item_model.dart';
import '../features/categories/data/models/category_model.dart';

class MockData {
  MockData._();

  // ═══════════════════════════════════════════════════════════
  // Categories
  // ═══════════════════════════════════════════════════════════

  static final List<CategoryModel> categories = [
    const CategoryModel(
      id: 'cat-electronics',
      name: 'Electronics',
      slug: 'electronics',
      description: 'Electronic devices',
    ),
    const CategoryModel(
      id: 'cat-accessories',
      name: 'Accessories',
      slug: 'accessories',
      description: 'Cables, stands, and add-ons',
    ),
    const CategoryModel(
      id: 'cat-laptops',
      name: 'Laptops',
      slug: 'laptops',
      parentId: 'cat-electronics',
    ),
    const CategoryModel(
      id: 'cat-audio',
      name: 'Audio',
      slug: 'audio',
      parentId: 'cat-electronics',
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // Products (Using Cost Price only)
  // ═══════════════════════════════════════════════════════════

  static final List<ProductModel> products = [
    // Electronics (top-level)
    const ProductModel(
      id: 'p1',
      name: 'Wireless Mouse',
      sku: 'WM-001',
      categoryId: 'cat-electronics',
      costPrice: 15.50, // Cost to shop
      quantity: 45,
    ),
    const ProductModel(
      id: 'p5',
      name: 'Webcam HD',
      sku: 'WC-005',
      categoryId: 'cat-electronics',
      costPrice: 40.00,
      quantity: 22,
    ),
    const ProductModel(
      id: 'p7',
      name: 'Bluetooth Speaker',
      sku: 'BS-007',
      categoryId: 'cat-audio',
      costPrice: 30.00,
      quantity: 3,
    ),

    // Accessories
    const ProductModel(
      id: 'p3',
      name: 'USB-C Cable',
      sku: 'UC-003',
      categoryId: 'cat-accessories',
      costPrice: 5.00,
      quantity: 120,
    ),
    const ProductModel(
      id: 'p4',
      name: 'Laptop Stand',
      sku: 'LS-004',
      categoryId: 'cat-accessories',
      costPrice: 20.00,
      quantity: 5,
    ),
    const ProductModel(
      id: 'p6',
      name: 'HDMI Cable 2m',
      sku: 'HC-006',
      categoryId: 'cat-accessories',
      costPrice: 8.00,
      quantity: 87,
    ),

    // Laptops (sub-category of Electronics)
    const ProductModel(
      id: 'p2',
      name: 'Mechanical Keyboard',
      sku: 'MK-002',
      categoryId: 'cat-laptops',
      costPrice: 60.00,
      quantity: 8,
      description: 'Compact mechanical keyboard with backlight',
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // Customers
  // ═══════════════════════════════════════════════════════════

  static final List<CustomerModel> customers = [
    CustomerModel(
      id: 'c1',
      name: 'John Doe',
      phone: '+1 555 0101',
      email: 'john@example.com',
      address: '123 Main St',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    CustomerModel(
      id: 'c2',
      name: 'Jane Smith',
      phone: '+1 555 0102',
      email: 'jane@example.com',
      address: '456 Oak Ave',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    CustomerModel(
      id: 'c3',
      name: 'Bob Wilson',
      phone: '+1 555 0103',
      email: 'bob@example.com',
      address: '789 Elm Blvd',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    CustomerModel(
      id: 'c4',
      name: 'Alice Brown',
      phone: '+1 555 0104',
      email: 'alice@example.com',
      address: '321 Pine Rd',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // Orders (Using Selling Price)
  // ═══════════════════════════════════════════════════════════

  static final List<OrderModel> orders = [
    OrderModel(
      id: 'o1',
      customerId: 'c1',
      customerName: 'John Doe',
      customerPhone: '+1 555 0101',
      items: const [
        OrderItemModel(
          productId: 'p1',
          productName: 'Wireless Mouse',
          quantity: 2,
          sellingPrice: 25.99, // Actual selling price
          costPrice: 15.50,    // Cost at time of sale
        ),
        OrderItemModel(
          productId: 'p3',
          productName: 'USB-C Cable',
          quantity: 1,
          sellingPrice: 12.00,
          costPrice: 5.00,
        ),
      ],
      subtotal: 63.98,
      discountAmount: 0,
      total: 63.98,
      status: 'completed',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    OrderModel(
      id: 'o2',
      customerId: 'c2',
      customerName: 'Jane Smith',
      customerPhone: '+1 555 0102',
      items: const [
        OrderItemModel(
          productId: 'p2',
          productName: 'Mechanical Keyboard',
          quantity: 1,
          sellingPrice: 89.50,
          costPrice: 60.00,
        ),
      ],
      subtotal: 89.50,
      discountAmount: 0,
      total: 89.50,
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    OrderModel(
      id: 'o3',
      customerId: 'c3',
      customerName: 'Bob Wilson',
      customerPhone: '+1 555 0103',
      items: const [
        OrderItemModel(
          productId: 'p5',
          productName: 'Webcam HD',
          quantity: 1,
          sellingPrice: 59.99,
          costPrice: 40.00,
        ),
        OrderItemModel(
          productId: 'p6',
          productName: 'HDMI Cable 2m',
          quantity: 2,
          sellingPrice: 15.50,
          costPrice: 8.00,
        ),
      ],
      subtotal: 90.99,
      discountAmount: 0,
      total: 90.99,
      status: 'processing',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}