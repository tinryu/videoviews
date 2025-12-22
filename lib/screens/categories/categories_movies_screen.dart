import 'package:flutter/material.dart';
import '../../models/movie.dart';
import '../../services/api_service.dart';
import '../../widgets/movie_card.dart';
import '../movies/movie_detail_screen.dart';

class CategoriesMoviesScreen extends StatefulWidget {
  const CategoriesMoviesScreen({
    super.key,
    required this.slug,
    required this.title,
  });

  final String slug;
  final String title;

  @override
  State<CategoriesMoviesScreen> createState() => _CategoriesMoviesScreenState();
}

class _CategoriesMoviesScreenState extends State<CategoriesMoviesScreen> {
  final _api = ApiService();
  final ScrollController _scrollController = ScrollController();
  final List<Movie> _movies = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _api.fetchMovieCategoryById(
        widget.slug,
        page: _currentPage,
        limit: _itemsPerPage,
      );

      setState(() {
        _movies.addAll(response.items);
        _hasMore = !response.hasReachedMax;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load movies: $e')),
        );
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMovies();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _movies.clear();
      _currentPage = 1;
      _hasMore = true;
    });
    await _loadMovies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _movies.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _movies.isEmpty
              ? _ErrorState(
                  message: 'No movies found in this category.',
                  onRetry: _refresh,
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final width = c.maxWidth;
                      final crossAxisCount = width >= 900
                          ? 5
                          : width >= 700
                              ? 4
                              : width >= 520
                                  ? 3
                                  : 2;

                      return GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 9 / 16,
                        ),
                        itemCount: _movies.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _movies.length) {
                            if (!_isLoading) {
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _loadMovies(),
                              );
                            }
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final movie = _movies[index];
                          return MovieCard(
                            movie: movie,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MovieDetailScreen(
                                  movieId: movie.id,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
