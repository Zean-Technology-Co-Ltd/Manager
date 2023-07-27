//
//  AVAssetWriteManager.m
//  NiuNiuRent
//
//  Created by Q Z on 2023/7/21.
//

#import "AVAssetWriteManager.h"
#import <CoreMedia/CoreMedia.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface AVAssetWriteManager ()
@property (nonatomic, strong) dispatch_queue_t writeQueue;
@property (nonatomic, strong) NSURL           *videoUrl;

@property (nonatomic, strong)AVAssetWriter *assetWriter;

@property (nonatomic, strong)AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, strong)AVAssetWriterInput *assetWriterAudioInput;

@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;


@property (nonatomic, assign) BOOL canWrite;
@property (nonatomic, assign) CGSize outputSize;
@end

@implementation AVAssetWriteManager

#pragma mark - private method
- (instancetype)init{
    self = [super init];
    if (self) {
        _outputSize = CGSizeMake(kScreenWidth, kScreenWidth);
        _writeQueue = dispatch_queue_create("com.5miles", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

//开始写入数据
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType
{
    if (sampleBuffer == NULL){
        NSLog(@"empty sampleBuffer");
        return;
    }
    
    @synchronized(self){
        if (self.writeState < FMRecordStateRecording){
            NSLog(@"not ready yet");
            return;
        }
    }
    
    CFRetain(sampleBuffer);
    dispatch_async(self.writeQueue, ^{
        @autoreleasepool {
            @synchronized(self) {
                if (self.writeState > FMRecordStateRecording){
                    CFRelease(sampleBuffer);
                    return;
                }
            }
            
            if (!self.canWrite && mediaType == AVMediaTypeVideo) {
                [self.assetWriter startWriting];
                [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                self.canWrite = YES;
            }
            
            //写入视频数据
            if (mediaType == AVMediaTypeVideo) {
                if (self.assetWriterVideoInput.readyForMoreMediaData) {
                    BOOL success = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                    if (!success) {
                        @synchronized (self) {
                            [self stopWrite];
                            [self destroyWrite];
                        }
                    }
                }
            }
            
            //写入音频数据
            if (mediaType == AVMediaTypeAudio) {
                if (self.assetWriterAudioInput.readyForMoreMediaData) {
                    BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                    if (!success) {
                        @synchronized (self) {
                            [self stopWrite];
                            [self destroyWrite];
                        }
                    }
                }
            }
            
            CFRelease(sampleBuffer);
        }
    } );
}

#pragma mark - public methed
- (void)startWrite:(NSURL *)url
{
    if (self.assetWriter) {
        [self destroyWrite];
    }
    self.videoUrl = url;
    self.writeState = FMRecordStatePrepareRecording;
    [self setUpWriter];
}

- (void)stopWrite
{
    self.writeState = FMRecordStateFinish;
    __weak __typeof(self)weakSelf = self;
    if(_assetWriter && _assetWriter.status == AVAssetWriterStatusWriting){
        dispatch_async(self.writeQueue, ^{
            [weakSelf.assetWriter finishWritingWithCompletionHandler:^{
//                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//                    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:self.videoUrl];
//                } completionHandler:^(BOOL success, NSError * _Nullable error) {
//                    if (success == true) {
//                        NSLog(@"视频保存成功");
//                    } else {
//                        NSLog(@"视频保存失败");
//                    }
//                }];
            }];
        });
    }
}

#pragma mark - private method
//设置写入视频属性
- (void)setUpWriter
{
    self.assetWriter = [AVAssetWriter assetWriterWithURL:self.videoUrl fileType:AVFileTypeMPEG4 error:nil];
    //写入视频大小
    NSInteger numPixels = self.outputSize.width * self.outputSize.height;
    //每像素比特
    CGFloat bitsPerPixel = 6.0;
    NSInteger bitsPerSecond = numPixels * bitsPerPixel;
    
    // 码率和帧率设置
    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                             AVVideoExpectedSourceFrameRateKey : @(30),
                                             AVVideoMaxKeyFrameIntervalKey : @(30),
                                             AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };
    
    //视频属性
    self.videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecTypeH264,
                                       AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                       AVVideoWidthKey : @(self.outputSize.height),
                                       AVVideoHeightKey : @(self.outputSize.width),
                                       AVVideoCompressionPropertiesKey : compressionProperties };

    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoCompressionSettings];
    //expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
    _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
    
    // 音频设置
    self.audioCompressionSettings = @{ AVEncoderBitRatePerChannelKey : @(28000),
                                       AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                       AVNumberOfChannelsKey : @(1),
                                       AVSampleRateKey : @(22050) };
    
    
    _assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioCompressionSettings];
    _assetWriterAudioInput.expectsMediaDataInRealTime = YES;
    
    if ([_assetWriter canAddInput:_assetWriterVideoInput]) {
        [_assetWriter addInput:_assetWriterVideoInput];
    }else {
        NSLog(@"AssetWriter videoInput append Failed");
    }
    if ([_assetWriter canAddInput:_assetWriterAudioInput]) {
        [_assetWriter addInput:_assetWriterAudioInput];
    }else {
        NSLog(@"AssetWriter audioInput Append Failed");
    }
    
    self.writeState = FMRecordStateRecording;
}

- (void)destroyWrite
{
    self.assetWriter = nil;
    self.assetWriterAudioInput = nil;
    self.assetWriterVideoInput = nil;
    self.videoUrl = nil;
}

- (void)getVideoDataWithCallback:(void(^)(NSData *data))callback;{
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:self.videoUrl  options:nil];
    NSDateFormatter* formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"yyyyMMddHHmmss"];
    NSString * _fileName = [NSString stringWithFormat:@"output-%@.mp4",[formater stringFromDate:[NSDate date]]];
    NSString * _outfilePath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", _fileName];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        NSLog(@"outPath = %@",_outfilePath);
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
        exportSession.outputURL = [NSURL fileURLWithPath:_outfilePath];
        exportSession.outputFileType = AVFileTypeMPEG4;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
                NSString * _filePath = _outfilePath;
                NSURL *  _filePathURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@",_outfilePath]];
                NSLog(@"转换完成_filePath = %@\n_filePathURL = %@",_filePath,_filePathURL);
                NSData *videoData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:_filePath]];
                NSLog(@"changeInstanceData:%@",  videoData);
                callback(videoData);
            }else{
                NSLog(@"转换失败,值为:%li,可能的原因:%@",(long)[exportSession status],[[exportSession error] localizedDescription]);
            }
        }];
    }
}

- (void)dealloc
{
    [self destroyWrite];
}

@end
