import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/movie.dart';
// import '../../services/api_service.dart';
import '../../state/favorites_store.dart';
import '../../widgets/movie_card.dart';
import '../movies/movie_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // final _api = ApiService();
  late Future<List<Movie>> _future;

  @override
  void initState() {
    super.initState();
    // _future = _api.fetchMovies();
  }

  @override
  Widget build(BuildContext context) {
    final favIds = context.watch<FavoritesStore>().ids;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          if (favIds.isNotEmpty)
            IconButton(
              tooltip: 'Clear favorites',
              onPressed: () => context.read<FavoritesStore>().clear(),
              icon: const Icon(Icons.delete_outline),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => () {},
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Movie>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString()));
          }

          final movies = snap.data ?? const <Movie>[];
          final favMovies = movies.where((m) => favIds.contains(m.id)).toList();

          if (favIds.isEmpty) {
            return const Center(
                child: Text('No favorites yet. Tap the heart on a movie.'));
          }
          if (favMovies.isEmpty) {
            return const Center(
                child: Text('Favorites not found in current movie list.'));
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              itemCount: favMovies.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, i) {
                final movie = favMovies[i];
                return MovieCard(
                  movie: movie,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => MovieDetailScreen(movieId: movie.id)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
