//
//  AVAssetWriteManager.h
//  NiuNiuRent
//
//  Created by Q Z on 2023/7/21.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

//录制状态，（这里把视频录制与写入合并成一个状态）
typedef NS_ENUM(NSInteger, FMRecordState) {
    FMRecordStateInit = 0,
    FMRecordStatePrepareRecording,
    FMRecordStateRecording,
    FMRecordStateFinish,
    FMRecordStateFail,
};

@interface AVAssetWriteManager : NSObject

@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputVideoFormatDescription;
@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputAudioFormatDescription;

@property (nonatomic, assign) FMRecordState writeState;
- (void)startWrite:(NSURL *)url;
- (void)stopWrite;
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType;
- (void)destroyWrite;
- (void)getVideoDataWithCallback:(void(^)(NSData *data))callback;
@end
