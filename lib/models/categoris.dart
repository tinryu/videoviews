class Categoris {
  final String id;
  final String name;
  final String slug;

  const Categoris({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory Categoris.fromJson(Map<String, dynamic> json) {
    return Categoris(
      id: json['_id'].toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }
}
