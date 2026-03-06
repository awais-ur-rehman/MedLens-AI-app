# MedLens AI — Mobile

> **See it. Speak it. Save it.**
> Flutter companion app for real-time voice-and-vision first aid guidance.

## What It Does

MedLens AI connects you to Dr. Muhammad — an AI first aid agent powered by Gemini Live. Open the app, describe or show your injury, and Dr. Muhammad talks you through exactly what to do, step by step, in real time.

- **Listens** to your voice continuously (full-duplex audio)
- **Sees** your injury through the camera on demand
- **Guides** with spoken instructions + visual overlays on the camera feed
- **Remembers** with a structured care summary saved to your device after each session
- **Offline reference** with the built-in First Aid Guide (12 critical scenarios)

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Flutter App                               │
│                                                                  │
│  HomeScreen ──────────────────────────────────────────────────   │
│     ├── Start Session → SessionScreen                            │
│     ├── First Aid Guide → GuideScreen → GuideDetailScreen        │
│     ├── Find Hospitals → HospitalsScreen                         │
│     └── History icon → HistoryScreen → SummaryScreen             │
│                                                                  │
│  SessionScreen                                                   │
│     ├── TranscriptPanel (chat bubbles + photo bubbles)           │
│     ├── CameraOverlay (preview + OverlayPainter)                 │
│     ├── PulseMicButton (barge-in)                                │
│     └── PhotoToast (confirmation)                                │
│                                                                  │
│  BLoC Layer                                                      │
│     ├── SessionBloc  ←→  WebSocketService + AudioService         │
│     │                         + CameraService                    │
│     ├── SummaryBloc  ←→  LocalStorageService (Hive)             │
│     └── HistoryBloc  ←→  LocalStorageService (Hive)             │
└──────────────────────────────────────────────────────────────────┘
                              │
                    WebSocket (wss://)
                    Binary: PCM audio
                    JSON: messages
                              │
                     FastAPI Backend
                              │
                    Gemini Live API
```

## Project Structure

```
mobile/lib/
├── main.dart                            # Entry point — Hive init, runApp
├── app.dart                             # MaterialApp.router + MultiBlocProvider
├── config/
│   ├── env.dart                         # --dart-define env vars
│   ├── router.dart                      # GoRouter (7 named routes)
│   └── theme.dart                       # MedLensTheme — dark navy palette, Inter font
│
├── models/
│   ├── assessment_model.dart            # Injury severity + triage assessment
│   ├── care_summary_model.dart          # Post-session structured summary
│   ├── citation_model.dart              # Google Search grounding source
│   ├── guide_entry.dart                 # First Aid Guide entry (steps, do-not list)
│   ├── message_model.dart               # Transcript message (text or photo)
│   └── overlay_model.dart              # Camera visual annotation (x/y/label/severity)
│
├── services/
│   ├── audio_service.dart               # flutter_sound — 16 kHz record / 24 kHz play
│   ├── camera_service.dart              # Capture JPEG + live stream at 1 FPS
│   ├── websocket_service.dart           # JSON stream + binary stream from WS
│   └── local_storage_service.dart       # Hive — save/load CareSummaryModel list
│
└── features/
    ├── home/
    │   └── view/home_screen.dart        # Hero text, action grid, recent sessions
    │
    ├── guide/
    │   ├── data/guide_data.dart         # 12 first-aid entries (full medical content)
    │   └── view/
    │       ├── guide_screen.dart        # 2-column grid, severity filter chips
    │       └── guide_detail_screen.dart # Steps, do-not list, 911 button
    │
    ├── hospitals/
    │   └── view/hospitals_screen.dart   # 911 call + Google Maps url_launcher
    │
    ├── session/
    │   ├── bloc/
    │   │   ├── session_bloc.dart        # Session orchestrator (590 lines)
    │   │   ├── session_event.dart       # All session events
    │   │   └── session_state.dart       # Status, mode, transcript, overlays, camera
    │   ├── view/session_screen.dart     # Camera overlay + transcript + controls
    │   └── widgets/
    │       ├── dr_muhammad_avatar.dart  # Animated avatar (pulses when speaking)
    │       ├── citation_chip.dart       # Tappable Google Search citation
    │       ├── overlay_painter.dart     # CustomPainter — highlight/arrow/label
    │       ├── pulse_mic_button.dart    # Sonar-pulse mic button (barge-in capable)
    │       ├── severity_badge.dart      # Colour-coded severity pill
    │       └── transcript_panel.dart   # Chat bubbles + photo thumbnails
    │
    ├── summary/
    │   ├── bloc/summary_bloc.dart       # Loads summary + persists to Hive
    │   └── view/summary_screen.dart     # Cards: what happened, steps, warnings, share
    │
    └── history/
        ├── bloc/history_bloc.dart       # Load/delete summaries from Hive
        ├── view/history_screen.dart     # Past sessions list (swipe-to-delete)
        └── widgets/session_tile.dart    # Session card with severity badge
```

## Screens

| Screen | Route | Description |
|--------|-------|-------------|
| **Home** | `/` | Dark gradient hero, action grid (Start Session / Guide / Hospitals), recent sessions panel |
| **Session** | `/session` | Live session — camera preview with overlays, transcript, pulsing mic, photo toast |
| **Summary** | `/summary` | Post-session care summary — injury type, steps taken, follow-up, warning signs, share |
| **History** | `/history` | All past sessions with severity badges, swipe-to-delete, tap to re-open summary |
| **First Aid Guide** | `/guide` | 12 scenario cards (cardiac arrest, stroke, anaphylaxis...) with severity filter |
| **Guide Detail** | `/guide/:id` | Full step-by-step guide, do-not list, 911 call, "Start Session" button |
| **Find Hospitals** | `/hospitals` | 911 call button, Google Maps for nearby hospitals, international emergency numbers |

## State Management

Three BLoCs provided globally via `MultiBlocProvider` in `app.dart`:

### SessionBloc
The main orchestrator. Owns the WebSocket, audio, and camera services.

| Event | Effect |
|-------|--------|
| `SessionStarted` | Connect WS, send `start_session`, start mic recording |
| `AudioChunkReceived` | Forward 16 kHz PCM to backend (always — no gate) |
| `ServerMessageReceived` | Route `transcript / overlay / citation / care_summary / ...` |
| `CameraRequested` | Set `cameraButtonPulsing = true` (pulsing ring on camera button) |
| `CameraOpened` | `_camera.initialize()` → emit `captureReady` |
| `PhotoCaptured` | Add photo bubble, send `image_frame` + auto text prompt to Gemini |
| `LiveStreamStarted` | `_camera.startLiveStream()` at 1 FPS, auto-stop after `durationSeconds` |
| `MicTapped` | Barge-in / end-of-turn / activity-start depending on current mode |
| `BargeInTriggered` | Stop playback, clear audio buffer, send `barge_in` to backend |
| `OverlaysCleared` | Clear `state.overlays` (auto-fired 8 s after any overlay arrives) |

### SummaryBloc
Receives `CareSummaryModel` from `SessionBloc` and persists to Hive. Also used by `HistoryScreen` to re-open old summaries.

### HistoryBloc
Loads all summaries from Hive on `HistoryLoaded`. Handles `HistoryItemDeleted`.

## Session Mode State Machine

```
          idle
          / \
    tap mic   Dr. Muhammad speaks
        /         \
  userSpeaking   doctorSpeaking
        \         /
    tap mic     audio finishes
        \         /
        thinking
          |
      agent responds
          |
         idle
```

## Camera Flow

```
cameraButtonPulsing = true   ← Dr. Muhammad calls request_camera tool
        ↓
user taps pulsing camera button
        ↓
cameraInitializing = true  → spinner shown
        ↓
_camera.initialize() completes
        ↓
cameraMode = captureReady  → live preview shown
        ↓
user taps shutter
        ↓
JPEG captured → photo bubble in transcript
image_frame JSON → backend
text prompt → "Please analyze it..."
sessionMode = thinking
        ↓
Dr. Muhammad responds (may include [[OVERLAY:...]])
        ↓
overlay rendered on camera preview → auto-clears after 8 s
```

## Audio Flow

```
Mic (flutter_sound)
  → 16 kHz PCM chunks
  → SessionBloc (AudioChunkReceived)
  → WebSocketService.sendBinary()
  → Backend → Gemini Live

Gemini Live
  → 24 kHz PCM chunks
  → WebSocketService.audioStream
  → SessionBloc (ServerAudioReceived)
  → Buffered in _turnAudioBuffer
  → Played as WAV on turn_complete
  → AudioService.playWavBuffer()
  → Speaker
```

## Setup

### Prerequisites

- Flutter SDK ≥ 3.10
- Dart SDK ≥ 3.10
- Xcode 15+ (iOS) or Android Studio (Android)
- Backend URL (local or Cloud Run)

### Install

```bash
cd mobile
flutter pub get
```

### Run against local backend

```bash
flutter run \
  --dart-define=BACKEND_WS_URL=ws://localhost:8080 \
  --dart-define=BACKEND_HTTP_URL=http://localhost:8080
```

### Run against deployed Cloud Run backend

```bash
flutter run \
  --dart-define=BACKEND_WS_URL=wss://medlens-backend-nw7kauj2aa-uc.a.run.app \
  --dart-define=BACKEND_HTTP_URL=https://medlens-backend-nw7kauj2aa-uc.a.run.app
```

### Permissions

| Platform | File | Permissions required |
|----------|------|---------------------|
| iOS | `ios/Runner/Info.plist` | `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` |
| Android | `android/app/src/main/AndroidManifest.xml` | `CAMERA`, `RECORD_AUDIO`, `INTERNET` |

## Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_bloc` | ^8.1.6 | BLoC state management |
| `go_router` | ^14.8.0 | Declarative navigation |
| `camera` | ^0.11.0 | Camera preview + JPEG capture |
| `flutter_sound` | ^9.16.3 | PCM audio recording and playback |
| `web_socket_channel` | ^3.0.1 | WebSocket client |
| `hive_flutter` | ^1.1.0 | Local session history (NoSQL) |
| `permission_handler` | ^11.3.1 | Camera and mic permission flow |
| `google_fonts` | ^6.2.1 | Inter typeface |
| `share_plus` | ^10.1.4 | Share care summary as text |
| `url_launcher` | ^6.3.0 | 911 call + Google Maps from Hospitals screen |
| `equatable` | ^2.0.7 | BLoC state equality |
| `uuid` | ^4.5.1 | Session ID generation |
| `intl` | ^0.19.0 | Date formatting in history/summary |
| `image` | ^4.3.0 | JPEG compression for camera frames |

## Theme

`MedLensTheme` in `lib/config/theme.dart` — dark navy design system:

| Token | Value | Use |
|-------|-------|-----|
| `background` | `#080C18` | Scaffold background |
| `surface` | `#0F1629` | Cards, overlays |
| `surfaceElev` | `#151E35` | Input fields, bottom sheets |
| `primary` | `#4F6EF7` | Buttons, links, active state |
| `accent` | `#7C3AED` | Gradient end, chip selected |
| `secondary` | `#10B981` | Success, low severity |
| `warning` | `#F59E0B` | Medium severity |
| `error` | `#EF4444` | High severity, do-not list |
| `textPrimary` | `#F1F5FF` | Headings, body text |
| `textSecondary` | `#8899CC` | Subtitles, descriptions |
| `textHint` | `#445077` | Placeholders, timestamps |

## First Aid Guide

12 built-in scenarios with full medical content (no internet required):

| Scenario | Severity | Quick Action |
|----------|----------|-------------|
| Cardiac Arrest | Critical | CPR → AED → 911 |
| Anaphylaxis | Critical | EpiPen → 911 |
| Choking | Critical | Heimlich → CPR |
| Stroke (FAST) | Critical | FAST → 911 |
| Head Injury | Critical | Still → 911 → Watch |
| Near-Drowning | Critical | Rescue → Airway → CPR |
| Heat Stroke | Critical | Cool Fast → 911 |
| Poisoning/Overdose | Critical | Poison Control → 911 |
| Snake Bite | Critical | Still → 911 → Note |
| Severe Bleeding | High | Pressure → Tourniquet |
| Seizure | High | Protect → Time → Recovery |
| Eye Injury | High | Flush → Cover → ER |
