import 'episode.dart';

class Movie {
  final String id;
  final String title;
  final String posterUrl;
  final String videoUrl;
  final String description;
  final int? rating;
  final int? year;
  final List<String> genres;
  final List<EpisodeServer> episodes;

  const Movie({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.videoUrl,
    required this.description,
    required this.genres,
    this.rating,
    this.year,
    this.episodes = const [],
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    final genresRaw = json['genres'];
    final genres = (genresRaw is List)
        ? genresRaw.map((e) => e.toString()).toList()
        : <String>[];

    final episodesRaw = json['episodes'];
    final episodes = (episodesRaw is List)
        ? episodesRaw
            .whereType<Map>()
            .map((e) => EpisodeServer.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <EpisodeServer>[];

    return Movie(
      id: json['id'].toString(),
      title: (json['title'] ?? '').toString(),
      posterUrl: (json['posterUrl'] ?? '').toString(),
      videoUrl: (json['videoUrl'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      year: json['year'] is int
          ? json['year'] as int
          : int.tryParse('${json['year']}'),
      genres: genres,
      rating: json['rating'] is int
          ? json['rating'] as int
          : int.tryParse('${json['rating']}'),
      episodes: episodes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'posterUrl': posterUrl,
      'videoUrl': videoUrl,
      'description': description,
      'rating': rating,
      'year': year,
      'genres': genres,
      'episodes': episodes.map((e) => e.toJson()).toList(),
    };
  }
}
