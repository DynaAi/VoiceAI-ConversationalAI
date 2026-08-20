//
//  BRAIVoiceRTCError.h
//  BRAIVoiceRTCKit
//
//  Created by admin on 2026/4/21.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    BRAIVoiceRTCErrorTypeParamIllegal                = 3001,
    BRAIVoiceRTCErrorTypeNoNetWork                   = 3002,
    BRAIVoiceRTCErrorTypeOuathError                  = 3003,
    BRAIVoiceRTCErrorTypeMicPermissionDenied         = 3004,
    BRAIVoiceRTCErrorTypeUnsupportedRTCVendor        = 3005,
    BRAIVoiceRTCErrorTypeEngineInitFailed            = 3006,
    BRAIVoiceRTCErrorTypeJoinChannelFailed           = 3007,
    BRAIVoiceRTCErrorTypeLeaveChannelFailed          = 3008,
    BRAIVoiceRTCErrorTypeVoiceChatNotConnected       = 3009,
    BRAIVoiceRTCErrorTypeJSONSerializationFailed     = 3010,
    BRAIVoiceRTCErrorTypeSendStreamMessageFailed     = 3011,
    BRAIVoiceRTCErrorTypeEngineNotInitialized        = 3012,
    BRAIVoiceRTCErrorTypeMuteRecordingFailed         = 3013,
    BRAIVoiceRTCErrorTypeRTCSDKError               = 3014,
    BRAIVoiceRTCErrorTypeRTCConnectionFailed       = 3015,
    BRAIVoiceRTCErrorTypeDataStreamReceiveError      = 3016,
    BRAIVoiceRTCErrorTypeCreateDataStreamFailed      = 3017,
    BRAIVoiceRTCErrorTypeRemoteUserJoinTimeout       = 3018,
    BRAIVoiceRTCErrorTypeRemoteUserReconnectTimeout  = 3019,
    BRAIVoiceRTCErrorTypeResponseParseFailed         = 3020,
    BRAIVoiceRTCErrorTypeOnGoing                     = 3021
} BRAIVoiceRTCErrorType;


NS_ASSUME_NONNULL_BEGIN

@interface BRAIVoiceRTCError : NSObject


@property (nonatomic, assign) BRAIVoiceRTCErrorType errorCode;
@property (nonatomic, copy) NSString* errorMessage;

+ (instancetype)createErrorWithCode:(BRAIVoiceRTCErrorType)errorCode info:(NSString *__nullable)info;

@end

NS_ASSUME_NONNULL_END
