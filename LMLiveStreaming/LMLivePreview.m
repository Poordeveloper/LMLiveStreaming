//
//  LMLivePreview.m
//  LFLiveKit
//
//  Created by 倾慕 on 16/5/2.
//  Copyright © 2016年 live Interactive. All rights reserved.
//

#import "LMLivePreview.h"
#import "UIControl+YYAdd.h"
#import "UIView+YYAdd.h"
#import "LFLiveKit/LFLiveSession.h"

LFLiveSession* g_session;

int buttonsShown = 1;

@interface LMLivePreview ()<LFLiveSessionDelegate>

@property (nonatomic, strong) UIButton *beautyButton;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UIButton *startLiveButton;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) LFLiveDebug *debugInfo;
@property (nonatomic, strong) LFLiveSession *session;
@property (nonatomic, strong) UILabel *stateLabel;
@property (nonatomic, strong) UILabel *nullLabel;
@property (nonatomic, strong) UITextField *urlInput;


@end

@implementation LMLivePreview

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        self.backgroundColor = [UIColor clearColor];
        [self requestAccessForVideo];
        [self requestAccessForAudio];
        [self addSubview:[[UILabel alloc] initWithFrame:self.bounds]]; // to make uiview clickable
        [self addSubview:self.containerView];
        [self.containerView addSubview:self.urlInput];
        [self addSubview:self.stateLabel];
        [self.containerView addSubview:self.cameraButton];
        [self.containerView addSubview:self.beautyButton];
        [self.containerView addSubview:self.startLiveButton];
        UITapGestureRecognizer *singleTap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(toggleButtons)];
        [self.containerView addGestureRecognizer:singleTap];
        _urlInput.delegate = self;
    }
    return self;
}

#pragma mark -- Public Method
- (void)requestAccessForVideo{
    __weak typeof(self) _self = self;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            // 许可对话没有出现，发起授权许可
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_self.session setRunning:YES];
                    });
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            // 已经开启授权，可继续
            //dispatch_async(dispatch_get_main_queue(), ^{
            [_self.session setRunning:YES];
            //});
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            // 用户明确地拒绝授权，或者相机设备无法访问
            
            break;
        default:
            break;
    }
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    return YES;
}

- (void)requestAccessForAudio{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            break;
        default:
            break;
    }
}


#pragma mark -- LFStreamingSessionDelegate
/** live status changed will callback */
- (void)liveSession:(nullable LFLiveSession *)session liveStateDidChange:(LFLiveState)state{
    NSLog(@"liveStateDidChange: %ld", state);
    switch (state) {
        case LFLiveReady:
            _stateLabel.text = @"未连接";
            break;
        case LFLivePending:
            _stateLabel.text = @"连接中";
            break;
        case LFLiveStart:
            _stateLabel.text = @"已连接";
            [self toggleButtons];
            break;
        case LFLiveError:
            _stateLabel.text = @"连接错误";
            [self toggle:FALSE];
            break;
        case LFLiveStop:
            _stateLabel.text = @"未连接";
            break;
        default:
            break;
    }
}

/** live debug info callback */
- (void)liveSession:(nullable LFLiveSession *)session debugInfo:(nullable LFLiveDebug*)debugInfo{
    NSLog(@"debugInfo: %lf", debugInfo.dataFlow);
}

/** callback socket errorcode */
- (void)liveSession:(nullable LFLiveSession*)session errorCode:(LFLiveSocketErrorCode)errorCode{
    NSLog(@"errorCode: %ld", errorCode);
}

#pragma mark -- Getter Setter
- (LFLiveSession*)session{
    if(!_session){
        /**    自己定制高质量音频128K 分辨率设置为720*1280 方向横屏  */
        
        
         LFLiveAudioConfiguration *audioConfiguration = [LFLiveAudioConfiguration new];
         audioConfiguration.numberOfChannels = 2;
         audioConfiguration.audioBitrate = LFLiveAudioBitRate_128Kbps;
         audioConfiguration.audioSampleRate = LFLiveAudioSampleRate_44100Hz;
         
         LFLiveVideoConfiguration *videoConfiguration = [LFLiveVideoConfiguration new];
         videoConfiguration.videoSize = CGSizeMake(1280, 720);
         videoConfiguration.videoBitRate = 800*1024;
         videoConfiguration.videoMaxBitRate = 1000*1024;
         videoConfiguration.videoMinBitRate = 500*1024;
         videoConfiguration.videoFrameRate = 15;
         videoConfiguration.videoMaxKeyframeInterval = 30;
         videoConfiguration.landscape = YES;
         videoConfiguration.sessionPreset = LFCaptureSessionPreset720x1280;
         
         g_session = _session = [[LFLiveSession alloc] initWithAudioConfiguration:audioConfiguration videoConfiguration:videoConfiguration];
         
        
        _session.delegate = self;
        _session.preView = self;
    }
    return _session;
}

- (UIView*)containerView{
    if(!_containerView){
        _containerView = [UIView new];
        _containerView.frame = self.bounds;
        _containerView.backgroundColor = [UIColor colorWithRed:0. green:0.39 blue:0.106 alpha: 0.4];
        _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _containerView;
}

- (UILabel*)stateLabel{
    if(!_stateLabel){
        _stateLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 80, 40)];
        _stateLabel.text = @"未连接";
        _stateLabel.textColor = [UIColor redColor];
        _stateLabel.font = [UIFont boldSystemFontOfSize:14.f];
    }
    return _stateLabel;
}

- (UITextField*)urlInput{
    if(!_urlInput){
        CGRect someRect = CGRectMake(50, self.height / 4, self.width - 100, 30.0);
        _urlInput = [[UITextField alloc] initWithFrame:someRect];
        _urlInput.borderStyle = UITextBorderStyleRoundedRect;
        _urlInput.font = [UIFont systemFontOfSize:15];
        _urlInput.placeholder = @"url";
        _urlInput.autocorrectionType = UITextAutocorrectionTypeNo;
        _urlInput.keyboardType = UIKeyboardTypeDefault;
        _urlInput.returnKeyType = UIReturnKeyDone;
        _urlInput.clearButtonMode = UITextFieldViewModeWhileEditing;
        _urlInput.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _urlInput.delegate = self;
    }
    return _urlInput;
}

- (UIButton*)cameraButton{
    if(!_cameraButton){
        _cameraButton = [UIButton new];
        _cameraButton.size = CGSizeMake(44, 44);
        _cameraButton.origin = CGPointMake(self.width - 10 - _cameraButton.width, 0);
        [_cameraButton setImage:[UIImage imageNamed:@"camra_preview"] forState:UIControlStateNormal];
        _cameraButton.exclusiveTouch = YES;
        __weak typeof(self) _self = self;
        [_cameraButton addBlockForControlEvents:UIControlEventTouchUpInside block:^(id sender) {
            AVCaptureDevicePosition devicePositon = _self.session.captureDevicePosition;
            _self.session.captureDevicePosition = (devicePositon == AVCaptureDevicePositionBack) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
        }];
    }
    return _cameraButton;
}

- (UIButton*)beautyButton{
    if(!_beautyButton){
        _beautyButton = [UIButton new];
        _beautyButton.size = CGSizeMake(44, 44);
        _beautyButton.origin = CGPointMake(_cameraButton.left - 10 - _beautyButton.width,0);
        [_beautyButton setImage:[UIImage imageNamed:@"camra_beauty"] forState:UIControlStateSelected];
        [_beautyButton setImage:[UIImage imageNamed:@"camra_beauty_close"] forState:UIControlStateNormal];
        _beautyButton.exclusiveTouch = YES;
        __weak typeof(self) _self = self;
        [_beautyButton addBlockForControlEvents:UIControlEventTouchUpInside block:^(id sender) {
            _self.session.beautyFace = !_self.session.beautyFace;
            _self.beautyButton.selected = !_self.session.beautyFace;
        }];
    }
    return _beautyButton;
}

- (UIButton*)startLiveButton{
    if(!_startLiveButton){
        _startLiveButton = [UIButton new];
        _startLiveButton.size = CGSizeMake(100, 36);
        _startLiveButton.left = (self.width - 100) / 2;
        _startLiveButton.top = self.height / 2;
        _startLiveButton.layer.cornerRadius = _startLiveButton.height/2;
        [_startLiveButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_startLiveButton.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [_startLiveButton setTitle:@"开始直播" forState:UIControlStateNormal];
        [_startLiveButton setBackgroundColor:[UIColor colorWithRed:50 green:32 blue:245 alpha:1]];
        _startLiveButton.exclusiveTouch = YES;
        __weak typeof(self) _self = self;
        [_startLiveButton addBlockForControlEvents:UIControlEventTouchUpInside block:^(id sender) {
            [_self toggle:TRUE];
        }];
    }
    return _startLiveButton;
}

-(void)toggle:(BOOL)action {
    self.startLiveButton.selected = !self.startLiveButton.selected;
    if(self.startLiveButton.selected){
        [self.startLiveButton setTitle:@"结束直播" forState:UIControlStateNormal];
        LFLiveStreamInfo *stream = [LFLiveStreamInfo new];
        stream.url = self.urlInput.text;
        //stream.url = @"rtmp://daniulive.com:1935/live/stream2399";
        if (action)[self.session startLive:stream];
    }else{
        [self.startLiveButton setTitle:@"开始直播" forState:UIControlStateNormal];
        if (action)[self.session stopLive];
    }

}

-(void)toggleButtons{
    [self endEditing: true]; // to hide keyboard
    buttonsShown = !buttonsShown;
    if (buttonsShown)
        _containerView.backgroundColor = [UIColor colorWithRed:0. green:0.39 blue:0.106 alpha: 0.4];
    else
        _containerView.backgroundColor = [UIColor clearColor];
    [self.containerView.subviews setValue:buttonsShown ? @NO : @YES forKeyPath:@"hidden"];
}

@end
