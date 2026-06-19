class ProjectSite {
  final String id;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdByName;

  ProjectSite({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdByName,
  });

  factory ProjectSite.fromJson(Map<String, dynamic> json) {
    return ProjectSite(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
      createdByName: json['createdByName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdByName': createdByName,
    };
  }
}
