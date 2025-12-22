import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/episode.dart';
import '../../models/movie.dart';
import '../../services/api_service.dart';
import '../../state/favorites_store.dart';
import '../player/player_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final String movieId;
  const MovieDetailScreen({super.key, required this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _api = ApiService();
  late Future<Movie> _future;
  var isExpanded = false;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchMovieById(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Movie>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorState(
              message: snap.error.toString(),
              onBack: () => Navigator.of(context).maybePop(),
              onRetry: () =>
                  setState(() => _future = _api.fetchMovieById(widget.movieId)),
            );
          }
          final movie = snap.data;
          if (movie == null) {
            return _ErrorState(
              message: 'Movie not found.',
              onBack: () => Navigator.of(context).maybePop(),
              onRetry: () =>
                  setState(() => _future = _api.fetchMovieById(widget.movieId)),
            );
          }

          final isFav = context.watch<FavoritesStore>().isFavorite(movie.id);
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(movie.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                actions: [
                  IconButton(
                    tooltip:
                        isFav ? 'Remove from favorites' : 'Add to favorites',
                    onPressed: () =>
                        context.read<FavoritesStore>().toggle(movie.id),
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroPoster(url: movie.posterUrl),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (movie.year != null)
                            Chip(label: Text('${movie.year}')),
                          ...movie.genres.map((g) => Chip(label: Text(g))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ExpansionTile(
                        expandedAlignment: Alignment.topLeft,
                        showTrailingIcon: false,
                        initiallyExpanded: isExpanded,
                        shape: Border.all(width: 0, color: Colors.transparent),
                        minTileHeight: 0.25,
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        onExpansionChanged: (val) =>
                            setState(() => isExpanded = val),
                        title: Text(
                          '${movie.description.substring(0, movie.description.length > 100 ? 100 : movie.description.length)} ${(movie.description.length > 100 && !isExpanded) ? '...' : ''}',
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 12),
                        ),
                        children: [
                          movie.description.length > 100
                              ? Text(movie.description.substring(100),
                                  textAlign: TextAlign.justify,
                                  style: TextStyle(fontSize: 12))
                              : const SizedBox.shrink(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: movie.videoUrl.trim().isEmpty
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          PlayerScreen(movie: movie)),
                                ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Watch'),
                      ),
                      if (movie.episodes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Episodes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _EpisodePicker(movie: movie),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        movie.videoUrl.trim().isEmpty
                            ? 'This movie has no videoUrl.'
                            : 'Video URL loaded from API.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroPoster extends StatelessWidget {
  final String url;
  const _HeroPoster({required this.url});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            image: url.trim().isEmpty
                ? null
                : DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.contain,
                  ),
          ),
          child: url.trim().isEmpty
              ? const Center(child: Icon(Icons.movie, size: 56))
              : null,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const _ErrorState(
      {required this.message, required this.onBack, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 44),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodePicker extends StatefulWidget {
  final Movie movie;
  const _EpisodePicker({required this.movie});

  @override
  State<_EpisodePicker> createState() => _EpisodePickerState();
}

class _EpisodePickerState extends State<_EpisodePicker> {
  int _serverIndex = 0;

  @override
  Widget build(BuildContext context) {
    final servers = widget.movie.episodes;
    if (servers.isEmpty) return const SizedBox.shrink();

    _serverIndex = _serverIndex.clamp(0, servers.length - 1);
    final server = servers[_serverIndex];
    final sources = server.serverData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (servers.length > 1)
          DropdownButtonFormField<int>(
            // ignore: deprecated_member_use
            value: _serverIndex,
            decoration: const InputDecoration(
              labelText: 'Server',
              border: OutlineInputBorder(),
            ),
            items: [
              for (var i = 0; i < servers.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(servers[i].serverName.isEmpty
                      ? 'Server ${i + 1}'
                      : servers[i].serverName),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _serverIndex = v);
            },
          ),
        if (servers.length > 1) const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final ep in sources)
              _EpisodeChip(
                  serverName: server.serverName, ep: ep, movie: widget.movie),
          ],
        ),
      ],
    );
  }
}

class _EpisodeChip extends StatelessWidget {
  final String serverName;
  final EpisodeSource ep;
  final Movie movie;

  const _EpisodeChip(
      {required this.serverName, required this.ep, required this.movie});

  @override
  Widget build(BuildContext context) {
    final label = ep.name.trim().isEmpty
        ? (ep.slug.isEmpty ? 'Episode' : ep.slug)
        : ep.name;
    return OutlinedButton(
      onPressed: ep.bestUrl.trim().isEmpty
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(
                    movie: movie,
                    videoUrlOverride: ep.bestUrl,
                    episodeLabel:
                        serverName.isEmpty ? label : '$serverName • $label',
                  ),
                ),
              ),
      child: Text(label),
    );
  }
}
