class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? parentId;
  final List<CategoryModel> children;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.parentId,
    this.children = const [],
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? parentId,
    List<CategoryModel>? children,
  }) => CategoryModel(
    id: id ?? this.id,
    name: name ?? this.name,
    slug: slug ?? this.slug,
    description: description ?? this.description,
    parentId: parentId ?? this.parentId,
    children: children ?? this.children,
  );

  bool get isParent => parentId == null || parentId!.isEmpty;
  bool get hasChildren => children.isNotEmpty;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
    name: json['name'] as String,
    slug: json['slug'] as String? ?? '',
    description: json['description'] as String?,
    parentId: json['parentId']?.toString(),
    children:
        (json['children'] as List?)
            ?.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    if (parentId != null) 'parentId': parentId,
  };
}
