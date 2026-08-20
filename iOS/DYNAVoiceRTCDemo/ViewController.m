//
//  ViewController.m
//  DYNAVoiceRTCDemo
//
//  Created by admin on 2026/4/21.
//

#import "ViewController.h"
#import "DemoCredentialDefaultsKeys.h"
#import "DemoCredentialConfigViewController.h"
#import <DYNAVoiceRTCKit/DYNAVoiceRTCKit.h>

@interface ViewController () <DYNAVoiceRTCManagerDelegate>

@property (nonatomic, strong, nullable) DYNAVoiceRTCManager *rtcManager;
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) UIButton *interruptButton;
@property (nonatomic, strong) UIButton *muteButton;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, assign) BOOL isAudioEnabled;
@property (nonatomic, copy, nullable) NSString *demoRtcCredentialFingerprint;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"DYNAVoiceRTCDemo";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.isAudioEnabled = YES;

    [self setupNavigationItems];
    [self setupViews];

    [self appendDisplayLine:@"Debug page initialized."];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self demo_updateRtcManagerForCurrentCredentials];
}

#pragma mark - UI

- (void)setupNavigationItems {
    UIBarButtonItem *configItem = [[UIBarButtonItem alloc] initWithTitle:@"Configure"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(openCredentialConfigAction)];
    UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(clearTextAction)];
    self.navigationItem.leftBarButtonItem = configItem;
    self.navigationItem.rightBarButtonItem = clearItem;
}

- (void)setupViews {
    self.startButton = [self makeActionButtonWithTitle:@"Start Voice Chat" action:@selector(startVoiceChatAction)];
    self.stopButton = [self makeActionButtonWithTitle:@"Stop Voice Chat" action:@selector(stopVoiceChatAction)];
    self.interruptButton = [self makeActionButtonWithTitle:@"Interrupt" action:@selector(interruptAction)];
    self.muteButton = [self makeActionButtonWithTitle:@"Mute" action:@selector(toggleMuteAction)];

    UIStackView *firstRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.startButton, self.stopButton]];
    firstRow.axis = UILayoutConstraintAxisHorizontal;
    firstRow.alignment = UIStackViewAlignmentFill;
    firstRow.distribution = UIStackViewDistributionFillEqually;
    firstRow.spacing = 12.0;
    firstRow.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *secondRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.interruptButton, self.muteButton]];
    secondRow.axis = UILayoutConstraintAxisHorizontal;
    secondRow.alignment = UIStackViewAlignmentFill;
    secondRow.distribution = UIStackViewDistributionFillEqually;
    secondRow.spacing = 12.0;
    secondRow.translatesAutoresizingMaskIntoConstraints = NO;

    self.textView = [[UITextView alloc] init];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.editable = NO;
    self.textView.selectable = YES;
    self.textView.alwaysBounceVertical = YES;
    self.textView.font = [UIFont systemFontOfSize:15.0];
    self.textView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.textView.textColor = [UIColor labelColor];
    self.textView.layer.cornerRadius = 12.0;
    self.textView.layer.masksToBounds = YES;

    [self.view addSubview:firstRow];
    [self.view addSubview:secondRow];
    [self.view addSubview:self.textView];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [firstRow.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:16.0],
        [firstRow.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:16.0],
        [firstRow.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-16.0],
        [firstRow.heightAnchor constraintEqualToConstant:44.0],

        [secondRow.topAnchor constraintEqualToAnchor:firstRow.bottomAnchor constant:12.0],
        [secondRow.leadingAnchor constraintEqualToAnchor:firstRow.leadingAnchor],
        [secondRow.trailingAnchor constraintEqualToAnchor:firstRow.trailingAnchor],
        [secondRow.heightAnchor constraintEqualToConstant:44.0],

        [self.textView.topAnchor constraintEqualToAnchor:secondRow.bottomAnchor constant:16.0],
        [self.textView.leadingAnchor constraintEqualToAnchor:firstRow.leadingAnchor],
        [self.textView.trailingAnchor constraintEqualToAnchor:firstRow.trailingAnchor],
        [self.textView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-16.0]
    ]];
}

- (UIButton *)makeActionButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
    button.backgroundColor = [UIColor systemBlueColor];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.layer.cornerRadius = 10.0;
    button.layer.masksToBounds = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

#pragma mark - Credentials & RTC Initialization

- (NSString *)demo_trimCredentialText:(NSString *)text {
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
}

- (BOOL)demo_hasCompleteCredentialsInUserDefaults {
    return [self demo_credentialFingerprintFromUserDefaults].length > 0;
}

/// Returns a stable fingerprint when all three values are non-empty; otherwise returns nil.
- (NSString *)demo_credentialFingerprintFromUserDefaults {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *robotKey = [self demo_trimCredentialText:[ud stringForKey:kDemoCredentialUDRobotKey]];
    NSString *robotToken = [self demo_trimCredentialText:[ud stringForKey:kDemoCredentialUDRobotToken]];
    NSString *userName = [self demo_trimCredentialText:[ud stringForKey:kDemoCredentialUDUserName]];
    if (robotKey.length == 0 || robotToken.length == 0 || userName.length == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@|%@|%@", robotKey, robotToken, userName];
}

- (void)demo_refreshRtcManagerFromUserDefaults {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *robotKey = [self demo_trimCredentialText:[ud stringForKey:kDemoCredentialUDRobotKey]];
    NSString *robotToken = [self demo_trimCredentialText:[ud stringForKey:kDemoCredentialUDRobotToken]];
    NSString *userName = [self demo_trimCredentialText:[ud stringForKey:kDemoCredentialUDUserName]];
    self.rtcManager = [[DYNAVoiceRTCManager alloc] initAIVoiceRTCWithKey:robotKey
                                                                  token:robotToken
                                                               userName:userName];
    self.rtcManager.delegate = self;
}

- (void)demo_presentCredentialGuideIfNeeded {
    if (self.presentedViewController != nil) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Credentials Not Configured"
                                                                   message:@"Tap Configure in the top-left, enter robotKey, robotToken, userName, then return."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)demo_updateRtcManagerForCurrentCredentials {
    NSString *fingerprint = [self demo_credentialFingerprintFromUserDefaults];
    if (fingerprint == nil) {
        self.rtcManager = nil;
        self.demoRtcCredentialFingerprint = nil;
        [self demo_presentCredentialGuideIfNeeded];
        return;
    }
    if (self.rtcManager != nil && [fingerprint isEqualToString:self.demoRtcCredentialFingerprint]) {
        return;
    }
    [self demo_refreshRtcManagerFromUserDefaults];
    self.demoRtcCredentialFingerprint = fingerprint;
}

- (void)openCredentialConfigAction {
    DemoCredentialConfigViewController *vc = [[DemoCredentialConfigViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Actions

- (void)startVoiceChatAction {
    [self.view endEditing:YES];
    if (![self demo_hasCompleteCredentialsInUserDefaults]) {
        [self demo_updateRtcManagerForCurrentCredentials];
        [self appendDisplayLine:@"Start failed: please configure credentials first."];
        return;
    }
    [self demo_updateRtcManagerForCurrentCredentials];
    if (self.rtcManager == nil) {
        [self appendDisplayLine:@"Start failed: unable to initialize RTC."];
        return;
    }

    [self appendDisplayLine:@"Tapped Start Voice Chat."];
    __weak typeof(self) weakSelf = self;
    [self.rtcManager startVoiceChatCompleteCallBack:^(BOOL isSuccess, DYNAVoiceRTCError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        if (isSuccess) {
            [strongSelf appendDisplayLine:@"Voice chat started successfully."];
        } else {
            [strongSelf appendDisplayLine:[NSString stringWithFormat:@"Voice chat start failed: %@", error.errorMessage ?: @"Unknown error"]];
        }
    }];
}

- (void)stopVoiceChatAction {
    if (self.rtcManager == nil) {
        [self appendDisplayLine:@"Stop voice chat: not initialized (configure credentials first)."];
        return;
    }
    [self appendDisplayLine:@"Tapped Stop Voice Chat."];
    __weak typeof(self) weakSelf = self;
    [self.rtcManager stopVoiceChatCompleteCallBack:^(BOOL isSuccess, DYNAVoiceRTCError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        if (isSuccess) {
            [strongSelf appendDisplayLine:@"Voice chat stopped successfully."];
        } else {
            [strongSelf appendDisplayLine:[NSString stringWithFormat:@"Voice chat stop failed: %@", error.errorMessage ?: @"Unknown error"]];
        }
    }];
    
}

- (void)interruptAction {
    if (self.rtcManager == nil) {
        [self appendDisplayLine:@"Interrupt: not initialized (configure credentials first)."];
        return;
    }
    [self appendDisplayLine:@"Tapped Interrupt."];
    [self.rtcManager interrupt];
}

- (void)toggleMuteAction {
    if (self.rtcManager == nil) {
        [self appendDisplayLine:@"Microphone: not initialized (configure credentials first)."];
        return;
    }
    self.isAudioEnabled = !self.isAudioEnabled;
    [self.muteButton setTitle:(self.isAudioEnabled ? @"Mute" : @"Unmute") forState:UIControlStateNormal];
    [self appendDisplayLine:(self.isAudioEnabled ? @"Local audio resumed." : @"Local audio muted.")];
    [self.rtcManager setAudioEnable:self.isAudioEnabled];
}


- (void)clearTextAction {
    self.textView.text = @"";
}

#pragma mark - DYNAVoiceRTCManagerDelegate

/**
 * Runtime error (does not include interrupt/microphone results, which are handled by
 * `onVoiceRTCInterruptResult:error:` and `onVoiceRTCSetAudioEnableResult:enable:error:`).
 */
- (void)onVoiceRTCRuntimeError:(DYNAVoiceRTCError *)error {
    NSString *msg = error.errorMessage.length > 0 ? error.errorMessage : @"(no description)";
    [self appendDisplayLine:[NSString stringWithFormat:@"Runtime error (code=%lu): %@", (unsigned long)error.errorCode, msg]];
}

- (void)onVoiceRTCInterruptResult:(BOOL)isSuccess error:(DYNAVoiceRTCError *)error {
    if (isSuccess) {
        [self appendDisplayLine:@"Interrupt: succeeded"];
    } else {
        NSString *msg = error.errorMessage.length > 0 ? error.errorMessage : @"Unknown error";
        [self appendDisplayLine:[NSString stringWithFormat:@"Interrupt: failed — %@", msg]];
    }
}

- (void)onVoiceRTCSetAudioEnableResult:(BOOL)isSuccess enable:(BOOL)enable error:(DYNAVoiceRTCError *)error {
    NSString *target = enable ? @"ON" : @"OFF";
    if (isSuccess) {
        [self appendDisplayLine:[NSString stringWithFormat:@"Microphone toggle (target: %@): succeeded", target]];
    } else {
        NSString *msg = error.errorMessage.length > 0 ? error.errorMessage : @"Unknown error";
        [self appendDisplayLine:[NSString stringWithFormat:@"Microphone toggle (target: %@): failed — %@", target, msg]];
    }
}

/**
 * Receives stream business callbacks: `text` is the `text` field from the JSON, `raw` is the entire
 * JSON string (`\u` already decoded into UTF-8 visible characters).
 *
 * @param text     Transcription/model text content.
 * @param fromRole Derived from the `role` field in the JSON: user → User, llm → Robot.
 * @param raw      Full stream JSON text (UTF-8 semantic string).
 */
- (void)onVoiceRTCReceiveStreamMessage:(NSString *)text
                              fromRole:(DYNAVoiceRTCStreamMessageRole)fromRole
                                   raw:(NSString *)raw {
    NSString *roleLabel = [self demo_labelForStreamMessageRole:fromRole];
    //[self appendDisplayLine:[NSString stringWithFormat:@"Received raw message role=%@\n text: %@\n raw: %@",
//                             roleLabel,
//                             text.length > 0 ? text : @"(empty)",
//                             raw.length > 0 ? raw : @"(empty)"]];
    [self appendDisplayLine:[NSString stringWithFormat:@"Received raw message role=%@\n text: %@\n",
                             roleLabel,
                             text.length > 0 ? text : @"(empty)"]];
    NSData *rawData = [raw dataUsingEncoding:NSUTF8StringEncoding];
    if (rawData.length == 0) {
        return;
    }
    NSError *err = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:rawData options:0 error:&err];
    NSDictionary *root = [obj isKindOfClass:[NSDictionary class]] ? obj : nil;
    if (root != nil) {
        [self demo_appendTranscriptionSummaryIfAnyForStreamRoot:root];
    }
}

#pragma mark - Demo stream JSON (business-layer parsing example)

- (NSString *)demo_labelForStreamMessageRole:(DYNAVoiceRTCStreamMessageRole)role {
    switch (role) {
        case DYNAVoiceRTCStreamMessageRoleUser:
            return @"User(ASR)";
        case DYNAVoiceRTCStreamMessageRoleRobot:
            return @"Robot(LLM)";
        case DYNAVoiceRTCStreamMessageRoleUnknown:
            return @"Unknown";
    }
}

- (void)demo_appendTranscriptionSummaryIfAnyForStreamRoot:(NSDictionary *)root {
    NSDictionary *leaf = [self demo_nestedTranscriptionPayloadIfAny:root];
    if (leaf == nil) {
        return;
    }
    NSString *role = [self demo_stringForCaseInsensitiveKey:@"role" inDictionary:leaf];
    NSString *text = [self demo_stringForCaseInsensitiveKey:@"text" inDictionary:leaf];
    NSString *prefix = [self demo_transcriptPrefixForRole:role];
    [self appendDisplayLine:[NSString stringWithFormat:@"[Demo transcription parse] %@: %@", prefix, text ?: @""]];
}

- (NSString *)demo_transcriptPrefixForRole:(NSString *)role {
    NSString *normalized = [[role stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    if ([normalized isEqualToString:@"user"]) {
        return @"ASR";
    }
    if ([normalized isEqualToString:@"llm"]) {
        return @"LLM";
    }
    return @"Text";
}

- (NSString *)demo_stringForCaseInsensitiveKey:(NSString *)wantedKey inDictionary:(NSDictionary *)dictionary {
    for (NSString *key in dictionary) {
        if ([key caseInsensitiveCompare:wantedKey] == NSOrderedSame) {
            return [self demo_coercedStringFromJSONValue:dictionary[key]];
        }
    }
    return nil;
}

- (NSString *)demo_coercedStringFromJSONValue:(id)value {
    if ([value isKindOfClass:[NSString class]]) {
        return (NSString *)value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value stringValue];
    }
    return nil;
}

- (NSDictionary *)demo_nestedTranscriptionPayloadIfAny:(NSDictionary *)root {
    return [self demo_nestedTranscriptionPayloadIfAny:root depth:0];
}

- (NSDictionary *)demo_nestedTranscriptionPayloadIfAny:(NSDictionary *)root depth:(NSInteger)depth {
    static const NSInteger kMaxDepth = 8;
    if (depth > kMaxDepth || ![root isKindOfClass:[NSDictionary class]] || root.count == 0) {
        return nil;
    }

    NSString *topic = [self demo_topicStringFromDictionary:root];
    if ([self demo_topicMatchesTranscription:topic]) {
        return root;
    }

    static NSArray<NSString *> *nestedKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nestedKeys = @[ @"data", @"payload", @"content", @"body", @"message", @"inner", @"event" ];
    });

    for (NSString *key in nestedKeys) {
        id node = root[key];
        if ([node isKindOfClass:[NSDictionary class]]) {
            NSDictionary *found = [self demo_nestedTranscriptionPayloadIfAny:(NSDictionary *)node depth:depth + 1];
            if (found != nil) {
                return found;
            }
        } else if ([node isKindOfClass:[NSString class]]) {
            NSString *jsonString = [(NSString *)node stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (jsonString.length == 0) {
                continue;
            }
            NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            if (data.length == 0) {
                continue;
            }
            NSError *error = nil;
            id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if ([parsed isKindOfClass:[NSDictionary class]]) {
                NSDictionary *found = [self demo_nestedTranscriptionPayloadIfAny:(NSDictionary *)parsed depth:depth + 1];
                if (found != nil) {
                    return found;
                }
            }
        }
    }

    return nil;
}

- (NSString *)demo_topicStringFromDictionary:(NSDictionary *)dictionary {
    for (NSString *key in dictionary) {
        if ([key caseInsensitiveCompare:@"topic"] == NSOrderedSame) {
            id value = dictionary[key];
            if ([value isKindOfClass:[NSString class]]) {
                return [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
            if ([value isKindOfClass:[NSNumber class]]) {
                return [[(NSNumber *)value stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
            break;
        }
    }
    return nil;
}

- (BOOL)demo_topicMatchesTranscription:(NSString *)topic {
    if (topic.length == 0) {
        return NO;
    }
    return [topic caseInsensitiveCompare:@"lk.transcription"] == NSOrderedSame;
}

#pragma mark - Helpers

- (void)appendDisplayLine:(NSString *)line {
    if (line.length == 0) {
        return;
    }

    NSString *currentText = self.textView.text ?: @"";
    NSString *nextText = currentText.length > 0 ? [currentText stringByAppendingFormat:@"\n%@", line] : line;
    self.textView.text = nextText;

    NSRange bottom = NSMakeRange(MAX(nextText.length - 1, 0), 1);
    [self.textView scrollRangeToVisible:bottom];
}

- (NSString *)displayStringForJSONObject:(id)jsonObject {
    if (![NSJSONSerialization isValidJSONObject:jsonObject]) {
        return [jsonObject description] ?: @"";
    }

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (error != nil || jsonData.length == 0) {
        return [jsonObject description] ?: @"";
    }

    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString.length > 0 ? jsonString : ([jsonObject description] ?: @"");
}

@end
