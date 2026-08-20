//
//  BRAIVoiceRTCManager.h
//  BRAIVoiceRTCKit
//
//  Created by admin on 2026/4/21.
//

#import <Foundation/Foundation.h>
@class BRAIVoiceRTCError;

// 开启和停止语音完成回调
typedef void(^BRAIVoiceChatResultBlock)(BOOL isSuccess, BRAIVoiceRTCError * _Nullable error);

/// 数据流 JSON 中 `role` 字段对应的业务角色：`user` → User（ASR），`llm` → Robot（大模型）；缺省或非预期取值 → Unknown。
typedef NS_ENUM(NSUInteger, BRAIVoiceRTCStreamMessageRole) {
    BRAIVoiceRTCStreamMessageRoleUser = 0,
    BRAIVoiceRTCStreamMessageRoleRobot = 1,
    BRAIVoiceRTCStreamMessageRoleUnknown = 2,
};

//可选代理
@protocol BRAIVoiceRTCManagerDelegate <NSObject>
@optional

/// 打断指令执行结果。调用 interrupt 后触发；成功时 isSuccess 为 YES 且 error 为 nil，失败时 isSuccess 为 NO 且 error 非空。
- (void)onVoiceRTCInterruptResult:(BOOL)isSuccess error:(BRAIVoiceRTCError *_Nullable)error;

/// 麦克风开关（muteRecordingSignal）执行结果。调用 setAudioEnable: 后触发；`enable` 与本次 `setAudioEnable:` 入参一致（YES 开启麦克风，NO 关闭）；成功时 isSuccess 为 YES 且 error 为 nil，失败时 isSuccess 为 NO 且 error 非空。
- (void)onVoiceRTCSetAudioEnableResult:(BOOL)isSuccess enable:(BOOL)enable error:(BRAIVoiceRTCError *_Nullable)error;

/// 运行期异常与底层错误
/// PS:不包含启动失败，停止失败，打断失败，麦克风开关失败
- (void)onVoiceRTCRuntimeError:(BRAIVoiceRTCError *_Nonnull)error;

/// 收到 RTC 数据流业务回调（解析数据流 JSON）
/// 参数：
/// - text：从 JSON 中 `text` 键（不区分大小写）解析出的字符串；经 UTF-8 可编码性校验（必要时允许有损转换），无该字段或非字符串时为 `@""`。
/// - fromRole：由 `role` 键推导，`user` → User，`llm` → Robot，其它或缺省 → Unknown。
/// - raw：整条数据流 JSON 的 UTF-8 文本。
- (void)onVoiceRTCReceiveStreamMessage:(NSString *_Nullable)text
                              fromRole:(BRAIVoiceRTCStreamMessageRole)fromRole
                                   raw:(NSString *_Nullable)raw;

/// 远端用户（非本端）加入当前 RTC 频道，用于感知频道内其他成员上线。
/// 回调时机：远端用户进房成功后；elapsed 表示从本端加入频道到该远端用户加入的时间间隔（毫秒）。
- (void)onVoiceRTCRemoteUserDidJoinChannelWithUid:(NSUInteger)uid elapsed:(NSInteger)elapsed;

/// 远端用户离开频道、主动下线或异常掉线等，可结合 offlineReason 判断原因；offlineReason 为整型，含义如下：
/// - 0：对方主动离开频道 / 正常挂断（Quit）。
/// - 1：超时掉线（Dropped）：一段时间内未收到该用户数据包被判定掉线；若对端已离开但信令路径不可靠、SDK 未及时收到离开通知时，也可能表现为本值。
/// - 2：对方将客户端角色由主播切换为观众（BecomeAudience），在直播场景下会表现为「离开」当前互动形态。
/// SDK 行为：在通话过程中收到本回调后，将启动 30 秒重连等待；若此期间未再收到 `onVoiceRTCRemoteUserDidJoinChannelWithUid`，将主动断开并回调 onVoiceRTCRuntimeError:（错误码 BRAIVoiceRTCErrorTypeRemoteUserReconnectTimeout）。
- (void)onVoiceRTCRemoteUserDidLeaveChannelWithUid:(NSUInteger)uid offlineReason:(NSInteger)offlineReason;
@end

NS_ASSUME_NONNULL_BEGIN

@interface BRAIVoiceRTCManager : NSObject

// SDK 版本号字符串
+ (NSString *)sdkVersion;

//代理
@property (nonatomic, weak) id<BRAIVoiceRTCManagerDelegate> delegate;

//初始化缓存数据，存储入参
- (instancetype)initAIVoiceRTCWithKey:(NSString *)rotbotKey token:(NSString *)robotToken userName:(NSString *)userName;

//开始语音会话（进房成功后若 15 秒内未收到远端 user-join，SDK 将主动退房、销毁 RTC 资源，并通过 onVoiceRTCRuntimeError: 抛出 BRAIVoiceRTCErrorTypeRemoteUserJoinTimeout）
- (void)startVoiceChatCompleteCallBack:(BRAIVoiceChatResultBlock)resultBlock;

//结束语音会话
- (void)stopVoiceChatCompleteCallBack:(BRAIVoiceChatResultBlock)resultBlock;

//打断机器人回复及播报
- (void)interrupt;

//麦克风开关
- (void)setAudioEnable:(BOOL)enable;


@end

NS_ASSUME_NONNULL_END
