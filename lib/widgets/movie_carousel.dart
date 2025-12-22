// Alternative approach if the above doesn't work
import 'package:carousel_slider/carousel_slider.dart' as carousel_slider;
import 'package:flutter/material.dart';

import '../models/movie.dart';
import 'movie_card.dart';

class MovieCarousel extends StatefulWidget {
  final List<Movie> movies;
  final bool hasMore;
  final bool isLoading;
  final VoidCallback onLoadMore;
  final ValueChanged<Movie>? onMovieTap;

  const MovieCarousel({
    super.key,
    required this.movies,
    required this.hasMore,
    required this.isLoading,
    required this.onLoadMore,
    this.onMovieTap,
  });

  @override
  State<MovieCarousel> createState() => _MovieCarouselState();
}

class _MovieCarouselState extends State<MovieCarousel> {
  final carousel_slider.CarouselSliderController _carouselController =
      carousel_slider.CarouselSliderController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        carousel_slider.CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: widget.movies.length + (widget.hasMore ? 1 : 0),
          options: carousel_slider.CarouselOptions(
            height: MediaQuery.of(context).size.height * 0.5,
            aspectRatio: 16 / 9,
            viewportFraction: 0.7,
            initialPage: 1,
            enableInfiniteScroll: false,
            enlargeCenterPage: true,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
              // Load more when we're near the end
              if (index >= widget.movies.length - 3 &&
                  !widget.isLoading &&
                  widget.hasMore) {
                widget.onLoadMore();
              }
            },
          ),
          itemBuilder: (context, index, realIndex) {
            if (index >= widget.movies.length) {
              if (!widget.isLoading) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => widget.onLoadMore());
              }
              return const Center(child: CircularProgressIndicator());
            }

            final movie = widget.movies[index];
            return GestureDetector(
              onTap: () => widget.onMovieTap?.call(movie),
              child: MovieCard(
                movie: movie,
                isActive: index == _currentIndex,
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    _carouselController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                    setState(() {
                      _currentIndex = index;
                    });
                  }
                },
              ),
            );
          },
        ),
        // const SizedBox(height: 16),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: widget.movies.asMap().entries.map((entry) {
        //     return Container(
        //       width: 8.0,
        //       height: 8.0,
        //       margin: const EdgeInsets.symmetric(horizontal: 4.0),
        //       decoration: BoxDecoration(
        //         shape: BoxShape.circle,
        //         color: _currentIndex == entry.key
        //             ? Theme.of(context).colorScheme.primary
        //             : Colors.grey[400],
        //       ),
        //     );
        //   }).toList(),
        // ),
      ],
    );
  }
}
