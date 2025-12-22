# Video Player (Movies from API)

This Flutter app shows a **home collection of movies** loaded from an API, lets users open a **movie detail** page, and **watch** the movie via `video_player` + `chewie`.

If `API_BASE_URL` is not provided, it uses the bundled mock data: `assets/mock/movies.json`.

## Quick start

1) Install Flutter and make sure `flutter` is on PATH.

2) If this folder does not have the usual Flutter platform folders yet (android/ios/web/windows), generate them:

```bash
flutter create .
```

3) Get packages:

```bash
flutter pub get
```

4) Run (mock mode):

```bash
flutter run
```

## Use your real API

Run with:

```bash
flutter run --dart-define=API_BASE_URL=https://your-domain.com/api
```

The app will request:
- `GET {API_BASE_URL}/movies` → array of movies
- `GET {API_BASE_URL}/movies/{id}` → single movie object

### Expected JSON shape

```json
{
  "id": "123",
  "title": "My Movie",
  "posterUrl": "https://cdn.example.com/posters/123.jpg",
  "videoUrl": "https://cdn.example.com/videos/123.mp4",
  "description": "Plot summary...",
  "year": 2025,
  "genres": ["Action", "Drama"]
}
```

If your endpoints differ, update `lib/config/app_config.dart`.

## App pages included

- Home: movie collection grid
- Search: search by title
- Categories: browse by genre
- Favorites: simple in-memory favorites
- Profile: shows current API base URL and suggested next pages

## Suggested next pages/features

- Continue Watching (resume position)
- Watch History
- Downloads / Offline cache
- Login + Profiles
- Subscriptions / Plans
- Notifications
- Video quality selector + subtitles
- Admin (add/edit movies)


