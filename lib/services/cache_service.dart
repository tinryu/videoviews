import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

/// Cache service for storing movie data with expiration
class MovieCacheService {
  static const String _cachePrefix = 'movies_cache_';
  static const String _timestampPrefix = 'cache_timestamp_';
  static const Duration _cacheExpiration = Duration(hours: 2);

  static final MovieCacheService _instance = MovieCacheService._internal();
  factory MovieCacheService() => _instance;
  MovieCacheService._internal();

  SharedPreferences? _prefs;

  /// Initialize the cache service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get cached movies for a slug
  /// Returns null if not cached or expired
  Future<List<Movie>?> getCachedMovies(String slug) async {
    await init();

    final timestamp = _prefs!.getInt('$_timestampPrefix$slug');
    if (timestamp == null) return null;

    // Check if cache is expired
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(cacheTime) > _cacheExpiration) {
      // Cache expired, remove it
      await clearCache(slug);
      return null;
    }

    // Get cached data
    final jsonString = _prefs!.getString('$_cachePrefix$slug');
    if (jsonString == null) return null;

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Movie.fromJson(json)).toList();
    } catch (e) {
      // If parsing fails, clear corrupted cache
      await clearCache(slug);
      return null;
    }
  }

  /// Cache movies for a slug
  Future<void> cacheMovies(String slug, List<Movie> movies) async {
    await init();

    try {
      // Convert movies to JSON
      final jsonList = movies.map((movie) => movie.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      // Save to cache with timestamp
      await _prefs!.setString('$_cachePrefix$slug', jsonString);
      await _prefs!.setInt(
        '$_timestampPrefix$slug',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // If caching fails, just log and continue
      // Don't crash the app
      // ignore: avoid_print
      print('Failed to cache movies for $slug: $e');
    }
  }

  /// Check if cache exists and is valid for a slug
  Future<bool> hasCachedMovies(String slug) async {
    final movies = await getCachedMovies(slug);
    return movies != null && movies.isNotEmpty;
  }

  /// Clear cache for a specific slug
  Future<void> clearCache(String slug) async {
    await init();
    await _prefs!.remove('$_cachePrefix$slug');
    await _prefs!.remove('$_timestampPrefix$slug');
  }

  /// Clear all movie caches
  Future<void> clearAllCache() async {
    await init();
    final keys = _prefs!.getKeys();

    for (final key in keys) {
      if (key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)) {
        await _prefs!.remove(key);
      }
    }
  }

  /// Get cache age for a slug
  Future<Duration?> getCacheAge(String slug) async {
    await init();
    final timestamp = _prefs!.getInt('$_timestampPrefix$slug');
    if (timestamp == null) return null;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime);
  }

  /// Check if cache is stale (older than 30 minutes but not expired)
  Future<bool> isCacheStale(String slug) async {
    final age = await getCacheAge(slug);
    if (age == null) return true;

    return age > const Duration(minutes: 30);
  }
}
