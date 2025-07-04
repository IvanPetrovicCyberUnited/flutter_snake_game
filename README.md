# Cyber Snake

A simple cyber-themed Snake game built with Flutter. The game targets both mobile and desktop including the web.

## Features
- Smoothly animated snake movement using `CustomPaint`.
- Special frog item spawns every 10 seconds and grows the snake by five segments with a random color.
- Self-collision trims the snake instead of ending the game.
- Wall collisions end the game.
- Win when the snake reaches a length of 100 segments.

## Controls
- **Keyboard:** Arrow keys or WASD.
- **Touch:** Swipe in the desired direction.

## Building for Web
Ensure you have Flutter installed and run:

```bash
flutter build web --web-renderer canvaskit
```

The generated build can be found in `build/web`.
