// Add to your search_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/movie.dart';
import '../../services/api_service.dart';
import '../../widgets/movie_card.dart';
import '../movies/movie_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = ApiService();
  final _debouncer = Debouncer(milliseconds: 500);
  final _searchController = TextEditingController();
  final _recentSearches = <String>[];

  List<Movie> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    // Load recent searches from shared preferences
    // final prefs = await SharedPreferences.getInstance();
    // setState(() {
    //   _recentSearches = prefs.getStringList('recent_searches') ?? [];
    // });
  }

  Future<void> _saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _recentSearches
          .removeWhere((q) => q.toLowerCase() == query.toLowerCase());
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    });

    // Save to shared preferences
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setStringList('recent_searches', _recentSearches);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _api.fetchMovieSearchById(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
      await _saveSearchQuery(query);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSearchResults(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          SearchBar(
            controller: _searchController,
            hintText: 'Search movies...',
            leading: const Icon(Icons.search),
            trailing: _searchController.text.isNotEmpty
                ? [
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _error = null;
                        });
                      },
                    ),
                  ]
                : null,
            onChanged: (value) {
              _debouncer.run(() => _search(value));
            },
          ),
          if (_recentSearches.isNotEmpty && _searchController.text.isEmpty)
            _buildRecentSearches(),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            'Recent Searches',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        ..._recentSearches.map(
          (query) => ListTile(
            leading: const Icon(Icons.history, size: 20),
            title: Text(query),
            onTap: () {
              _searchController.text = query;
              _search(query);
            },
          ),
        )
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _search(_searchController.text),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return const Expanded(
        child: Center(
          child: Text('No results found'),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('Search for movies to see results'),
        ),
      );
    }

    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final movie = _searchResults[index];
          return MovieCard(
            movie: movie,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MovieDetailScreen(movieId: movie.id),
              ),
            ),
          );
        },
      ),
    );
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
