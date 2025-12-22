import 'package:flutter/material.dart';
import 'package:videoplayer/widgets/movie_carousel.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/movie.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import '../movies/movie_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  final _cache = MovieCacheService();
  final Map<String, List<Movie>> _moviesBySlug = {};
  final Map<String, bool> _loadingBySlug = {};

  final List<String> _listSlug = [
    'phim-moi',
    'phim-bo',
    'phim-le',
    'tv-shows',
    'hoat-hinh',
    'phim-vietsub',
    'phim-thuyet-minh',
    'phim-long-tien',
    'phim-bo-dang-chieu',
    'phim-bo-hoan-thanh',
    'phim-sap-chieu',
    'subteam',
    'phim-chieu-rap',
  ];

  // Friendly names for each slug
  final Map<String, String> _slugTitles = {
    'phim-moi': 'New Movies',
    'phim-bo': 'TV Series',
    'phim-le': 'Movies',
    'tv-shows': 'TV Shows',
    'hoat-hinh': 'Animation',
    'phim-vietsub': 'Subtitled Movies',
    'phim-thuyet-minh': 'Dubbed Movies',
    'phim-long-tien': 'Premium Movies',
    'phim-bo-dang-chieu': 'Ongoing Series',
    'phim-bo-hoan-thanh': 'Completed Series',
    'phim-sap-chieu': 'Coming Soon',
    'subteam': 'Subteam',
    'phim-chieu-rap': 'Theater Movies',
  };

  @override
  void initState() {
    super.initState();
    _loadAllMovies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadAllMovies() async {
    // Optimized loading strategy:
    // 1. Load first 3 categories in parallel (immediate content)
    // 2. Then load remaining categories in batches of 3

    // Load first batch (priority content) in parallel
    const priorityCount = 3;
    final prioritySlugs = _listSlug.take(priorityCount).toList();

    await Future.wait(
      prioritySlugs.map((slug) => _loadMoviesBySlug(slug)),
    );

    // Load remaining slugs in background (batches of 3 for better performance)
    final remainingSlugs = _listSlug.skip(priorityCount).toList();

    // Load in batches to avoid overwhelming the API
    for (var i = 0; i < remainingSlugs.length; i += 3) {
      final batch = remainingSlugs.skip(i).take(3);
      await Future.wait(
        batch.map((slug) => _loadMoviesBySlug(slug)),
      );
      // Small delay between batches to prevent rate limiting
      if (i + 3 < remainingSlugs.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> _loadMoviesBySlug(String slug) async {
    if (_loadingBySlug[slug] == true) return;

    setState(() {
      _loadingBySlug[slug] = true;
    });

    try {
      // STEP 1: Check cache first (instant display)
      final cachedMovies = await _cache.getCachedMovies(slug);

      if (cachedMovies != null && cachedMovies.isNotEmpty) {
        // Show cached data immediately
        if (!mounted) return;

        setState(() {
          _moviesBySlug[slug] = cachedMovies;
          _loadingBySlug[slug] = false;
        });

        // STEP 2: Check if cache is stale, refresh in background if needed
        final isStale = await _cache.isCacheStale(slug);
        if (!isStale) {
          // Cache is fresh, no need to fetch
          return;
        }
        // Cache is stale, continue to fetch fresh data below
        // But keep showing cached data (stale-while-revalidate pattern)
      }

      // STEP 3: Fetch fresh data from API
      final movies = await _api.fetchMovieBySlug(slug);

      if (!mounted) return;

      // STEP 4: Update UI and cache with fresh data
      setState(() {
        _moviesBySlug[slug] = movies;
        _loadingBySlug[slug] = false;
      });

      // STEP 5: Save to cache
      await _cache.cacheMovies(slug, movies);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingBySlug[slug] = false;
      });

      // Only show error for priority categories to avoid spam
      // And only if we don't have cached data
      if (_listSlug.indexOf(slug) < 3 &&
          (_moviesBySlug[slug]?.isEmpty ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load $slug: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _refresh() async {
    // Clear all caches to force fresh data
    await _cache.clearAllCache();

    setState(() {
      _moviesBySlug.clear();
      _loadingBySlug.clear();
    });

    await _loadAllMovies();
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
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
          onRefresh: _refresh,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
            ),
            child: _moviesBySlug.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _listSlug.length,
                    itemBuilder: (context, index) {
                      return _buildMovieCarouselForSlug(_listSlug[index]);
                    },
                  ),
          )),
    );
  }

  Widget _buildMovieCarouselForSlug(String slug) {
    final movies = _moviesBySlug[slug] ?? [];
    final isLoading = _loadingBySlug[slug] ?? false;
    final title = _slugTitles[slug] ?? slug;

    // Skip rendering if no movies and not loading
    if (movies.isEmpty && !isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        if (isLoading && movies.isEmpty)
          const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          )
        else
          MovieCarousel(
            movies: movies,
            hasMore: false, // No pagination for slug-based loading
            isLoading: false,
            onLoadMore: () {}, // Not used for slug-based loading
            onMovieTap: (movie) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MovieDetailScreen(movieId: movie.id),
              ),
            ),
          ),
      ],
    );
  }
}
