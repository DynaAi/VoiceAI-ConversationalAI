# AgentStudio Intelligent Voice Call Android SDK

A lightweight real-time intelligent voice conversation SDK based on WebRTC, for quickly integrating high-quality voice interaction into Android applications.

## Product Overview

The AgentStudio Intelligent Voice Call Android SDK encapsulates low-level logic including server connection, audio capture/playback, and conversation control. Developers can integrate end-to-end real-time voice capabilities into Android apps in just 10 minutes.

Deeply integrated with AgentStudio platform agents, it is suitable for intelligent customer service, voice assistants, smart outbound calls and other scenarios.

## Key Features

- 🎤 **Out-of-the-box**: Encapsulates WebRTC, audio processing, connection management and other low-level details
- 🔐 **Credential Auth**: Secure access via `robotKey` + `robotToken`
- 🎙️ **Real-time Conversation**: Bidirectional streaming ASR & TTS with low latency
- 🛑 **Interruption Support**: Interrupt robot replies at any time for natural dialogue
- 🔇 **Audio Control**: Dynamically mute / unmute the local microphone, or mute the robot side independently
- 📡 **Complete Event System**: Rich events for session state, message flow and errors
- 📱 **Native Support**: Android 7.0+ compatible, supports mainstream ABIs

## Prerequisites

Before using this SDK:

1. Refer to [Voice Call Integration Preparation](https://docs-agentos.resultscloud.com/api-reference/agent/voice-prep) to create an Agent. After completing the API-based release, obtain the access credentials `robotKey` and `robotToken`.
2. Target Android 7.0 (API 24) or higher

> ⚠️ `robotKey` and `robotToken` are sensitive credentials. Keep them secure to avoid billing loss. Use server-side temporary tokens in production. **Never hardcode them in client code.** The demo ships with empty defaults — replace them with your own credentials.

## Quick Start

### 1. Import SDK

Download `DYNA_AI_Voice_RTC_x.x.x.aar` from this repo's [GitHub Releases](https://github.com/<your-org>/AgentStudio-Voice-Android/releases), then place it into your module's `libs/` directory and add the dependency in `build.gradle.kts`:

```kotlin
dependencies {
    implementation(files("libs/DYNA_AI_Voice_RTC_x.x.x.aar"))
}
```

> The AAR includes `consumer-rules.pro`. Rules are merged automatically when R8 / ProGuard is enabled.

### 2. Permissions

Basic permissions (network, audio) are declared inside the AAR's manifest. No duplicate declaration is required.

**Runtime Permission**:
Request microphone permission at runtime on Android 6.0+:

```xml
<!-- Required: Microphone -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

**Optional** (Android 12+, for Bluetooth audio routing):

```xml
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
```

> Built-in permissions: `INTERNET`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`

### 3. Basic Usage

```kotlin
import com.dyna.voice.ai.ChatClient
import com.dyna.voice.ai.event.ChatEvent
import com.dyna.voice.ai.model.ChannelMessage
import com.dyna.voice.ai.model.ErrorMessage

// 1. Create client after microphone permission is granted
val client = ChatClient(
    context = applicationContext,
    robotKey = "your_robot_key",      // from AgentStudio platform
    robotToken = "your_robot_token",  // from AgentStudio platform
    userName = "unique-user-id"       // unique user ID
)

// 2. Register event listeners
client.on(ChatEvent.SESSION_STARTED) { _, _ ->
    println("Session started")
}

client.on(ChatEvent.ROBOT_MESSAGE) { _, data ->
    if (data is ChannelMessage) {
        println("Robot: ${data.text}")
    }
}

client.on(ChatEvent.ERROR) { _, data ->
    if (data is ErrorMessage) {
        println("Error: ${data.code} - ${data.errMsg}")
    }
}

// 3. Start voice chat
client.startVoiceChat()

// 4. Release resources on destroy
client.stopVoiceChat()
client.removeAll()
```

## Advanced Usage

### Full Event Listening

```kotlin
val client = ChatClient(context, robotKey, robotToken, userName = "user-123")

// Session lifecycle
client.on(ChatEvent.SESSION_STARTED) { _, _ -> }
client.on(ChatEvent.SESSION_ENDED) { _, _ -> }

// Messages
client.on(ChatEvent.USER_MESSAGE) { _, data ->
    if (data is ChannelMessage) {
        // data.text, data.final, data.rawJson
        // data.role == "user", or use data.isFromUser
    }
}
client.on(ChatEvent.ROBOT_MESSAGE) { _, data ->
    if (data is ChannelMessage) {
        // robot reply, data.role == "llm", use data.isFromRobot
    }
}

// Audio state
client.on(ChatEvent.AUDIO_MUTED) { _, _ -> }
client.on(ChatEvent.AUDIO_UNMUTED) { _, _ -> }

// Agent join / leave
client.on(ChatEvent.ROBOT_JOINED) { _, _ -> }
client.on(ChatEvent.ROBOT_LEFT) { _, _ -> }

// Listen to all events (debug)
client.onAny { eventName, data ->
    println("[$eventName] $data")
}
```

### Conversation Control

```kotlin
// Interrupt current reply
client.interrupt()

// Mute local microphone
client.setAudioEnabled(false)
// Unmute
client.setAudioEnabled(true)

// Mute robot-side playback only (local mic unaffected)
client.setRobotAudioMuted(true)

// End conversation
client.stopVoiceChat()
```

### Complete Example (auto interrupt & end)

```kotlin
import com.dyna.voice.ai.ChatClient
import com.dyna.voice.ai.event.ChatEvent
import android.os.Handler
import android.os.Looper

val client = ChatClient(
    context = applicationContext,
    robotKey = BuildConfig.ROBOT_KEY,
    robotToken = BuildConfig.ROBOT_TOKEN,
    userName = "demo-user-1"
)

client.on(ChatEvent.SESSION_STARTED) { _, _ -> println("Session started") }
client.on(ChatEvent.ROBOT_MESSAGE) { _, data ->
    if (data is ChannelMessage) println("Robot: ${data.text}")
}
client.on(ChatEvent.ERROR) { _, data ->
    if (data is ErrorMessage) println("Error: ${data.errMsg}")
}

client.startVoiceChat()

// Interrupt after 5s, end after 10s
Handler(Looper.getMainLooper()).postDelayed({ client.interrupt() }, 5000)
Handler(Looper.getMainLooper()).postDelayed({
    client.stopVoiceChat()
    client.removeAll()
}, 10000)
```

## API Reference

### ChatClient

Main client class for session management and conversation control, located at `com.dyna.voice.ai.ChatClient`.

#### Constructor

```kotlin
ChatClient(
    context: Context,
    robotKey: String,
    robotToken: String,
    userName: String
)
```

**Parameters**

- `context: Context` – Application context (use `applicationContext` recommended)
- `robotKey: String` – Agent key from AgentStudio platform
- `robotToken: String` – Agent token from AgentStudio platform
- `userName: String` – Unique user identifier (required, must be unique per user)

#### Methods

| Method | Return | Description |
|--------|--------|-------------|
| `startVoiceChat()` | `Unit` | Start voice chat, establish RTC connection |
| `stopVoiceChat()` | `Unit` | End conversation and release resources |
| `interrupt()` | `Boolean` | Interrupt robot reply, returns `true` on success |
| `setAudioEnabled(enabled: Boolean)` | `Boolean` | Enable / disable local microphone capture |
| `setRobotAudioMuted(muted: Boolean)` | `Boolean` | Mute / unmute robot-side playback independently |
| `getSdkVersion()` | `String` | Get current SDK version |
| `on(event, listener)` | `Unit` | Register event listener |
| `onAny(listener)` | `Unit` | Register global event listener |
| `off(event, listener)` | `Unit` | Remove a specific listener for an event |
| `off(event)` | `Unit` | Remove all listeners for an event |
| `offAny(listener)` | `Unit` | Remove a specific `onAny` listener |
| `removeAll()` | `Unit` | Remove all event listeners |

### ChatEvent

Event enum constants, located at `com.dyna.voice.ai.event.ChatEvent`. Prefer the enum over hardcoded strings.

| Enum Value | Trigger | Data Type |
|------------|---------|-----------|
| `SESSION_STARTED` | Local side joined RTC channel | null |
| `SESSION_ENDED` | Session end process completed | null |
| `USER_MESSAGE` | User speech result (streaming) | `ChannelMessage` |
| `ROBOT_MESSAGE` | Robot reply (streaming) | `ChannelMessage` |
| `AUDIO_MUTED` | Microphone muted | null |
| `AUDIO_UNMUTED` | Microphone unmuted | null |
| `ROBOT_JOINED` | Remote agent joined | null |
| `ROBOT_LEFT` | Remote agent left | null |
| `ERROR` | Error occurred | `ErrorMessage` |

#### ChannelMessage

Located at `com.dyna.voice.ai.model.ChannelMessage`. Core fields:

- `text: String` – Message text
- `final: Boolean` – `true` = end of sentence, `false` = incremental
- `speakerId: String` – Speaker ID (assistant mode, prepended to the sentence)
- `role: String` – Speaker role, `"user"` for user, `"llm"` for robot
- `isFromUser: Boolean` – Whether from the user (`role == "user"`)
- `isFromRobot: Boolean` – Whether from the robot (`role == "llm"`)
- `isFinal: Boolean` – Convenience accessor for `final`
- `id / mimeType / topic / timestamp / encryptionType` – Channel metadata
- `rawJson: String` – Raw JSON string

#### ErrorMessage

Located at `com.dyna.voice.ai.model.ErrorMessage`:

- `code: Int` – Error code
- `errMsg: String` – Error message

## Error Codes

| Code | Description |
|------|-------------|
| 3001 | Parameter validation failed (`robotKey` / `robotToken` / `userName` / `roomName` empty or invalid) |
| 3002 | No available network detected before starting voice |
| 3003 | Start / stop session HTTP request exception (network interruption, non-2xx response) |
| 3004 | Microphone permission not granted (`RECORD_AUDIO`) |
| 3005 | SDK does not support it |
| 3006 | RTC engine initialization failed (e.g. `RtcEngine.create`) |
| 3007 | `joinChannel` returned non-zero synchronously, did not enter channel |
| 3008 | `leaveChannel` returned non-zero during stop flow |
| 3009 | `interrupt` or similar called while voice session is not connected |
| 3010 | Command JSON serialization failed |
| 3011 | `sendStreamMessage` returned non-zero (e.g. interrupt not sent) |
| 3012 | Engine not created when toggling audio or creating data stream |
| 3013 | `muteRecordingSignal` returned non-zero |
| 3014 | RTC `onError` callback after session is up |
| 3015 | Connection entered `Failed` / `Disconnected` during join |
| 3016 | Data stream receive error (e.g. `onStreamMessageError`) |
| 3017 | `createDataStream` failed after join |
| 3018 | No remote `onUserJoined` within 15s after local join success |
| 3019 | No remote `onUserJoined` again within 30s after `onUserOffline` |
| 3020 | API response or stream JSON parsing failed |
| 3021 | Call flow conflict (e.g. `start` called while a session is in progress) |

## Compatibility

| Item | Description |
|------|-------------|
| Android | minSdk 24 (Android 7.0+) |
| Language | Kotlin (dependencies bundled in AAR) |
| ABI | arm64-v8a, armeabi-v7a |
| Requirements | Microphone + network |

## Run Demo

The `Android/DynaVoiceRTCDemo` project includes a basic integration example page demonstrating credential input, session start/stop, interrupt, mute and message streaming.

Import the demo into Android Studio, fill in your real `robotKey` and `robotToken` in `MainActivity`, then run.
