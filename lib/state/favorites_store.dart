import 'package:flutter/foundation.dart';

class FavoritesStore extends ChangeNotifier {
  final Set<String> _ids = <String>{};

  bool isFavorite(String movieId) => _ids.contains(movieId);

  Set<String> get ids => Set.unmodifiable(_ids);

  void toggle(String movieId) {
    if (_ids.contains(movieId)) {
      _ids.remove(movieId);
    } else {
      _ids.add(movieId);
    }
    notifyListeners();
  }

  void clear() {
    _ids.clear();
    notifyListeners();
  }
}
