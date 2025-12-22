import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:videoplayer/screens/categories/categories_movies_screen.dart';

import '../../models/categoris.dart';
import '../../services/api_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _api = ApiService();
  late Future<List<Categoris>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FreeFilms',
            style: GoogleFonts.unifrakturMaguntia(
              color: Colors.black,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            )),
      ),
      body: FutureBuilder<List<Categoris>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString()));
          }

          final categories = snap.data ?? const <Categoris>[];
          final unique = <String, Categoris>{};
          for (final c in categories) {
            // Deduplicate by slug; fall back to name.
            final key = c.slug.isNotEmpty ? c.slug : c.name;
            unique.putIfAbsent(key, () => c);
          }
          final list = unique.values.toList()
            ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final genre = list[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.local_movies_outlined),
                  title: Text(genre.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => CategoriesMoviesScreen(
                            slug: genre.slug, title: genre.name)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
