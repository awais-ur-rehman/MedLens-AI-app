# MedLens AI — Mobile

Flutter app for real-time first-aid guidance. Streams camera + mic to the backend, receives audio responses from Dr. Muhammad, and displays injury overlays and care summaries.

## Architecture

```
┌─────────────────────────────────────────┐
│              Flutter App                │
│                                         │
│  HomeScreen → SessionScreen → Summary   │
│       │             │            │      │
│       │        ┌────┴────┐       │      │
│       │     Camera    Audio      │      │
│       │     Service   Service    │      │
│       │        └────┬────┘       │      │
│       │        WebSocket         │      │
│       │        Service           │      │
│       │             │            │      │
│       └─── BLoC State Mgmt ─────┘      │
│             │       │       │           │
│          Session  Summary  History      │
│           Bloc     Bloc     Bloc        │
│                              │          │
│                         Hive Storage    │
└─────────────────────────────────────────┘
                    │
              WebSocket (ws)
                    │
            FastAPI Backend
```

## Project Structure

```
mobile/lib/
├── main.dart                          # Entry point (Hive init)
├── app.dart                           # MaterialApp.router + MultiBlocProvider
├── config/
│   ├── router.dart                    # GoRouter (home/session/summary/history)
│   └── theme.dart                     # MedLensTheme (Inter font, brand palette)
├── models/
│   ├── assessment_model.dart          # Injury assessment from Visual Assessor
│   ├── care_summary_model.dart        # Post-session care summary
│   ├── citation_model.dart            # Source citations
│   ├── message_model.dart             # Transcript messages
│   ├── overlay_model.dart             # Camera overlay annotations
│   └── session_model.dart             # Session metadata
├── services/
│   ├── audio_service.dart             # flutter_sound — 16kHz record / 24kHz play
│   ├── camera_service.dart            # Camera capture + JPEG compression
│   ├── websocket_service.dart         # WebSocket client (JSON + binary streams)
│   └── local_storage_service.dart     # Hive — session history persistence
├── features/
│   ├── home/
│   │   └── view/home_screen.dart      # Landing — logo, Start Session, permissions
│   ├── session/
│   │   ├── bloc/session_bloc.dart     # Live session state management
│   │   ├── view/session_screen.dart   # Camera preview + overlays + transcript
│   │   └── widgets/
│   │       ├── dr_muhammad_avatar.dart    # Animated avatar (pulses when speaking)
│   │       ├── severity_badge.dart        # Coloured pill (Low/Moderate/Seek Help)
│   │       ├── citation_chip.dart         # Tappable source citation
│   │       ├── pulse_mic_button.dart      # Sonar-pulse mic (barge-in)
│   │       ├── transcript_panel.dart      # Auto-scrolling chat transcript
│   │       └── overlay_painter.dart       # CustomPainter for injury annotations
│   ├── summary/
│   │   ├── bloc/summary_bloc.dart     # Care summary state
│   │   └── view/summary_screen.dart   # Cards: steps, warnings, share button
│   └── history/
│       ├── bloc/history_bloc.dart     # Load/delete from Hive
│       ├── view/history_screen.dart   # Past sessions list
│       └── widgets/session_tile.dart  # Swipe-to-delete session card
└── utils/
```

## Setup

### Prerequisites

- Flutter SDK ≥ 3.10
- Xcode (iOS) or Android Studio (Android)
- Backend running at `localhost:8080`

### Install

```bash
cd mobile
flutter pub get
```

### Run

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

### Permissions

The app requires **camera** and **microphone** access. These are configured in:

- **iOS:** `ios/Runner/Info.plist` — `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`
- **Android:** `android/app/src/main/AndroidManifest.xml` — `CAMERA`, `RECORD_AUDIO`, `INTERNET`

## Screens

| Screen | Route | Purpose |
|---|---|---|
| **Home** | `/` | Landing page — branding, Start Session (with permissions check), View History |
| **Session** | `/session` | Live session — camera preview, overlays, transcript, mic button |
| **Summary** | `/summary` | Post-session — care summary cards, share, start new session |
| **History** | `/history` | Past sessions — list with swipe-to-delete, tap to view summary |

## State Management

Three BLoCs provided globally via `MultiBlocProvider`:

| BLoC | Key Events | State |
|---|---|---|
| `SessionBloc` | `SessionStarted`, `AudioChunkReceived`, `CameraFrameCaptured`, `BargeInTriggered` | Status, agent speaking state, transcript, overlays, assessment |
| `SummaryBloc` | `SummaryLoaded`, `SummaryCleared` | `CareSummaryModel` |
| `HistoryBloc` | `HistoryLoaded`, `HistoryItemDeleted` | List of past summaries from Hive |

## Audio Notes

| Direction | Sample Rate | Format |
|---|---|---|
| Recording (mic → backend) | 16 kHz | 16-bit PCM LE, mono |
| Playback (backend → speaker) | 24 kHz | 16-bit PCM LE, mono |

## Key Dependencies

| Package | Purpose |
|---|---|
| `flutter_bloc` | State management |
| `go_router` | Declarative routing |
| `camera` | Camera preview + frame capture |
| `flutter_sound` | PCM audio recording + playback |
| `web_socket_channel` | WebSocket communication |
| `hive_flutter` | Local session history storage |
| `permission_handler` | Camera/mic permission flow |
| `google_fonts` | Inter typography |
| `share_plus` | Share care summary as text |
| `image` | JPEG compression for camera frames |
