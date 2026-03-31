# AI Coach - Frontend (Flutter)

A cross-platform app that enables teachers to record classroom lessons and receive AI-powered analysis based on the World Bank's TEACH Primary observation framework.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)

## Screenshots

<!-- Add your screenshots here. You can replace the placeholder paths with your actual screenshots -->
| Home Screen | Recording Screen | Coaching Feedback |
| :---: | :---: | :---: |
| <img src="screenshot_home.png" width="250"/> | <img src="screenshot_recording.png" width="250"/> | <img src="screenshot_feedback.png" width="250"/> |

## Features
*   **Audio Recording**: Record lessons directly in the app with pause/resume functionality.
*   **Progress Tracking**: Track improvement over time.
*   **Coaching Chat**: Chat with an AI coach about the specific lesson.

## Run Instructions

1.  Ensure the backend service is running and configured correctly.
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the application:
    ```bash
    # For Web (Chrome)
    flutter run -d chrome

    # For Desktop (Windows)
    flutter run -d windows
    
    # For Android Emulator
    flutter run -d emulator-id
    ```

## Configuration

To connect to a backend running on a different machine (or if using a physical device), update `lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = 'http://<YOUR_IP>:8080';
```
