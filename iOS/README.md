# Dyna Intelligent Voice Call iOS SDK

English

A lightweight real-time intelligent voice conversation SDK based on WebRTC, for quickly integrating high-quality voice interaction into iOS applications.

## Product Overview
The Dyna Intelligent Voice Call iOS SDK encapsulates low-level logic including server connection, audio capture/playback, and conversation control. Developers can integrate end-to-end real-time voice capabilities into iOS apps in just 10 minutes.

Deeply integrated with Dyna platform agents, it is suitable for intelligent customer service, voice assistants, smart outbound calls and other scenarios.

## Key Features
- 🎤 **Out-of-the-box**: Encapsulates WebRTC, audio processing, connection management and other low-level details
- 🔐 **Credential Auth**: Secure access via `robotKey` + `robotToken`
- 🎙️ **Real-time Conversation**: Bidirectional streaming ASR & TTS with low latency
- 🛑 **Interruption Support**: Interrupt robot replies at any time for natural dialogue
- 🔇 **Audio Control**: Dynamically mute / unmute the microphone
- 📡 **Complete Delegate System**: Rich delegate callbacks for session state, message flow and errors
- 📱 **Native Support**: iOS 13.0+, universal binary (arm64 device + x86_64 simulator)

## Prerequisites
Before using this SDK:

1. Refer to [Voice Call Integration Preparation](https://docs.agent.dyna.ai/api-reference/agent/voice-prep) to create an Agent. After completing the API-based release, obtain the access credentials `robotKey` and `robotToken`.
2. Target iOS 13.0 or higher; supports real devices and the simulator

> ⚠️ `robotKey` and `robotToken` are sensitive credentials. Keep them secure to avoid billing loss. Use server-side temporary tokens in production. **Never hardcode them in client code.**

## Quick Start

### 1. Import SDK into Project

**Method A: CocoaPods (Recommended)**

Add to your `Podfile`:

```ruby
platform :ios, '13.0'
use_frameworks!

target 'YourTarget' do
  pod 'DYNAVoiceRTCKit', :podspec => 'https://git.dyna.tech/pd_eng/rtc/voice_ios_sdk_demo/-/raw/main/DYNAVoiceRTCKit.podspec'
end
```

Then run `pod install` and open the generated `.xcworkspace`.

> The underlying Agora RTC frameworks are already nested inside `DYNAVoiceRTCKit.framework` and pre-signed — you don't need to add them separately.

**Method B: Manual Integration**

1. Download and extract the SDK package from this repo's [Releases](https://git.dyna.tech/pd_eng/rtc/voice_ios_sdk_demo/-/releases) to get `DYNAVoiceRTCKit.framework`
2. Open your Xcode project, right-click the project name and select **Add Files to "ProjectName"…**
3. Select `DYNAVoiceRTCKit.framework`, check **Copy items if needed**, select your target in Add to targets, then click Add

### 2. Configure Framework Dependency
1. In Xcode, select your project target and go to the **General** tab
2. Find the **Frameworks, Libraries, and Embedded Content** section
3. Set the embed mode of `DYNAVoiceRTCKit.framework` to **Embed & Sign**

### 3. Configure System Permissions
The SDK requires microphone permission for audio capture. Add the following entry to your `Info.plist`:
- Right-click Info.plist and select **Add Row**
- Key: `Privacy - Microphone Usage Description`
- Value: Usage description (e.g. "Microphone access is required for voice interaction with the agent")

### 4. Basic Usage

```objc
#import <DYNAVoiceRTCKit/DYNAVoiceRTCKit.h>

@interface YourViewController () <DYNAVoiceRTCManagerDelegate>
@property (nonatomic, strong) DYNAVoiceRTCManager *rtcManager;
@end

@implementation YourViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize voice manager
    self.rtcManager = [[DYNAVoiceRTCManager alloc] initAIVoiceRTCWithKey:@"your_robot_key"
                                                                  token:@"your_robot_token"
                                                               userName:@"unique-user-id"];
    self.rtcManager.delegate = self;
}

// Start voice chat
- (void)startVoiceChat {
    [self.rtcManager startVoiceChatCompleteCallBack:^(BOOL isSuccess, DYNAVoiceRTCError * _Nullable error) {
        if (isSuccess) {
            NSLog(@"Voice chat started successfully");
        } else {
            NSLog(@"Start failed: %@", error.errorMessage);
        }
    }];
}

// Stop voice chat
- (void)stopVoiceChat {
    [self.rtcManager stopVoiceChatCompleteCallBack:^(BOOL isSuccess, DYNAVoiceRTCError * _Nullable error) {
        if (isSuccess) {
            NSLog(@"Voice chat stopped successfully");
        } else {
            NSLog(@"Stop failed: %@", error.errorMessage);
        }
    }];
}

#pragma mark - DYNAVoiceRTCManagerDelegate
// Receive stream messages
- (void)onVoiceRTCReceiveStreamMessage:(NSString *)text fromRole:(DYNAVoiceRTCStreamMessageRole)fromRole raw:(NSString *)raw {
    if (fromRole == DYNAVoiceRTCStreamMessageRoleRobot) {
        NSLog(@"Robot: %@", text);
    }
}

// Runtime error
- (void)onVoiceRTCRuntimeError:(DYNAVoiceRTCError *)error {
    NSLog(@"Error: %ld - %@", (long)error.errorCode, error.errorMessage);
}

@end
```

## Advanced Usage

### Full Delegate Callbacks

```objc
#pragma mark - DYNAVoiceRTCManagerDelegate

// Interrupt result callback
- (void)onVoiceRTCInterruptResult:(BOOL)isSuccess error:(DYNAVoiceRTCError *)error {
    if (isSuccess) {
        NSLog(@"Interrupt succeeded");
    } else {
        NSLog(@"Interrupt failed: %@", error.errorMessage);
    }
}

// Microphone state result callback
- (void)onVoiceRTCSetAudioEnableResult:(BOOL)isSuccess enable:(BOOL)enable error:(DYNAVoiceRTCError *)error {
    NSLog(@"Microphone %@: %@", enable ? @"enabled" : @"disabled", isSuccess ? @"success" : error.errorMessage);
}

// Runtime exception callback
- (void)onVoiceRTCRuntimeError:(DYNAVoiceRTCError *)error {
    // Handle underlying exceptions not covered by other callbacks
}

// RTC data stream callback
- (void)onVoiceRTCReceiveStreamMessage:(NSString *)text fromRole:(DYNAVoiceRTCStreamMessageRole)fromRole raw:(NSString *)raw {
    // fromRole: User / Robot / Unknown
    // raw: raw JSON string for custom parsing
}

// Remote user joined channel callback
- (void)onVoiceRTCRemoteUserDidJoinChannelWithUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    NSLog(@"Remote user joined, uid: %lu, elapsed: %ldms", (unsigned long)uid, (long)elapsed);
}

// Remote user left channel callback
- (void)onVoiceRTCRemoteUserDidLeaveChannelWithUid:(NSUInteger)uid offlineReason:(NSInteger)offlineReason {
    // offlineReason: 0=normal leave 1=timeout 2=role switch
}
```

### Conversation Control

```objc
// Interrupt current robot reply
[self.rtcManager interrupt];

// Mute microphone
[self.rtcManager setAudioEnable:NO];

// Unmute microphone
[self.rtcManager setAudioEnable:YES];

// Get SDK version
NSString *version = [DYNAVoiceRTCManager sdkVersion];
```

### Complete Example (Auto Interrupt & End)

```objc
#import <DYNAVoiceRTCKit/DYNAVoiceRTCKit.h>

@interface DemoViewController () <DYNAVoiceRTCManagerDelegate>
@property (nonatomic, strong) DYNAVoiceRTCManager *rtcManager;
@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.rtcManager = [[DYNAVoiceRTCManager alloc] initAIVoiceRTCWithKey:YOUR_ROBOT_KEY
                                                                  token:YOUR_ROBOT_TOKEN
                                                               userName:@"demo-user-1"];
    self.rtcManager.delegate = self;
    
    // Start conversation
    [self.rtcManager startVoiceChatCompleteCallBack:^(BOOL isSuccess, DYNAVoiceRTCError * _Nullable error) {
        if (!isSuccess) {
            NSLog(@"Start failed: %@", error.errorMessage);
            return;
        }
        
        // Interrupt after 5 seconds
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.rtcManager interrupt];
        });
        
        // End after 10 seconds
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.rtcManager stopVoiceChatCompleteCallBack:^(BOOL isSuccess, DYNAVoiceRTCError * _Nullable error) {
                NSLog(@"Session ended: %@", isSuccess ? @"success" : error.errorMessage);
            }];
        });
    }];
}

@end
```

## API Reference

### DYNAVoiceRTCManager
Core manager class for session management and conversation control.

#### Initializer

```objc
- (instancetype)initAIVoiceRTCWithKey:(NSString *)robotKey
                                token:(NSString *)robotToken
                             userName:(NSString *)userName;
```

**Parameters**
- `robotKey: NSString` – Agent key from the Dyna platform
- `robotToken: NSString` – Agent token from the Dyna platform
- `userName: NSString` – Unique user identifier (required, must be unique per user)

#### Methods

| Method | Return | Description |
|--------|--------|-------------|
| `startVoiceChatCompleteCallBack:` | `void` | Start voice chat, establish RTC connection; result via block callback |
| `stopVoiceChatCompleteCallBack:` | `void` | End conversation and release resources; result via block callback |
| `interrupt` | `void` | Interrupt robot reply; result via delegate callback |
| `setAudioEnable:` | `void` | Enable / disable microphone capture; result via delegate callback |
| `sdkVersion` (class method) | `NSString` | Get current SDK version |

### DYNAVoiceRTCManagerDelegate
Delegate protocol for receiving all SDK events.

| Delegate Method | Trigger | Key Parameters |
|-----------------|---------|----------------|
| `onVoiceRTCInterruptResult:error:` | Returns result after calling `interrupt` | `isSuccess`, `error` |
| `onVoiceRTCSetAudioEnableResult:enable:error:` | Returns result after calling `setAudioEnable:` | `enable` target state, `isSuccess` |
| `onVoiceRTCRuntimeError:` | Runtime exception not covered by other callbacks | `error` error object |
| `onVoiceRTCReceiveStreamMessage:fromRole:raw:` | RTC business data stream received | `text` parsed content, `fromRole` sender role, `raw` raw JSON |
| `onVoiceRTCRemoteUserDidJoinChannelWithUid:elapsed:` | Remote agent joined channel | `uid`, `elapsed` (ms) |
| `onVoiceRTCRemoteUserDidLeaveChannelWithUid:offlineReason:` | Remote agent left channel | `uid`, `offlineReason` |

#### Data Structures
**DYNAVoiceRTCError**
- `errorCode: NSInteger` – Error code
- `errorMessage: NSString` – Error description

**DYNAVoiceRTCStreamMessageRole Enum**
- `DYNAVoiceRTCStreamMessageRoleUser` – User-side message
- `DYNAVoiceRTCStreamMessageRoleRobot` – Robot-side message
- `DYNAVoiceRTCStreamMessageRoleUnknown` – Unknown role

## Error Codes

| Code | Description |
|------|-------------|
| 3001 | Parameter validation failed (empty, invalid, missing fields) |
| 3002 | No available network connection |
| 3003 | Internal network request exception (interruption, non-2xx response) |
| 3004 | Microphone permission not granted |
| 3005 | Unsupported channel or platform |
| 3006 | Voice engine initialization failed |
| 3007 | Failed to join RTC channel |
| 3008 | Failed to leave RTC channel |
| 3009 | Interrupt called before session is established |
| 3010 | Command serialization failed |
| 3011 | Failed to send command / data stream |
| 3012 | SDK method called before engine initialization |
| 3013 | Failed to set microphone state |
| 3014 | Unknown underlying system exception |
| 3015 | Connection interrupted during session start |
| 3016 | RTC data stream receive error |
| 3017 | Failed to create business data channel |
| 3018 | Remote agent join timeout after local joined |
| 3019 | Remote agent offline & reconnection timeout |
| 3020 | Business data JSON parsing failed |
| 3021 | Call flow conflict (duplicate start request) |

## Compatibility

| Item | Requirement |
|------|-------------|
| System | iOS 13.0+ |
| Architecture | arm64 real device + x86_64 simulator (Apple Silicon simulator runs via Rosetta) |
| Build Options | BitCode is not supported |
| Requirements | Microphone + network connection |

## Run Demo
The demo project lives in `iOS/DYNAVoiceRTCDemo` and integrates the SDK via CocoaPods as a third-party app:

```bash
cd iOS
pod install
open DYNAVoiceRTCDemo.xcworkspace
```

In Xcode, configure `robotKey` and `robotToken` (via the in-app credential page), then run on a real device.
