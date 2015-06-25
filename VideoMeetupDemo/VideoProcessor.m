//
//  VideoProcessor.m
//  VideoMeetupDemo
//
//  Created by BARRY EZELL on 6/25/15.
//  Copyright (c) 2015 Barry Ezell. All rights reserved.
//

#import "VideoProcessor.h"
#import "Filter.h"
#import "NoGreenFilter.h"
#import "InverseFilter.h"
#import "SwapFilter.h"

#define FRAME_RATE 15

@interface VideoProcessor() <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic)   AVCaptureSession *captureSession;
@property (nonatomic)   AVCaptureConnection *videoConnection;
@property (nonatomic)   AVCaptureVideoOrientation videoOrientation;
@property (nonatomic)   CALayer *previewLayer;
@property (nonatomic)   CGSize previewLayerSize;
@property (nonatomic)   NSURL *recordedFileURL;
@property (atomic)      AVAssetWriterInput *assetWriterVideoIn;
@property (atomic)      AVAssetWriter *assetWriter;
@property (atomic)      BOOL readyToRecordVideo;
@property (nonatomic)   Filter *currentFilter;

@end

CMBufferQueueRef previewBufferQueue;
dispatch_queue_t movieWritingQueue;

@implementation VideoProcessor

- (void)setupCaptureSession:(CALayer*)previewLayer {
    
    self.previewLayer = previewLayer;
    self.previewLayerSize = previewLayer.frame.size;

    // Create and configure capture session
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    
    if ([captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    } else {
        NSLog(@"Error - can't set high quality capture session preset");
        return;
    }
    
    // Create video connection. Note for this demo we're not adding audio. With AVFoundation, you have to handle that manually too.
    NSError *error;
    AVCaptureDeviceInput *videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backwardFacingCameraDevice] error:&error];
    if (error) {
        NSLog(@"Error - creating video input: %@", error.localizedDescription);
        return;
    }
    
    if ([captureSession canAddInput:videoInput]) {
        [captureSession addInput:videoInput];
    } else {
        NSLog(@"Error - adding video input");
        return;
    }
    
    // Configure video output settings:
    
    // It's critical that frames are processed as quickly as possible when the camera supplies them so
    // setting "discards late frames" is generally a good idea. Otherwise the app could face a backlog
    // of frames to process which could lead to an out-of-memory exception.
    AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
    videoOut.alwaysDiscardsLateVideoFrames = YES;
    
    // There are many pixel formats but 32BGRA is used commonly.
    NSDictionary *videoSettings = @{ (id) kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] };
    videoOut.videoSettings = videoSettings;
    
    // Create a queue for processing frames.
    dispatch_queue_t videoCaptureQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
    [videoOut setSampleBufferDelegate:self queue:videoCaptureQueue];
    if ([captureSession canAddOutput:videoOut]) {
        [captureSession addOutput:videoOut];
    } else {
        NSLog(@"Error - cannot add video out");
        return;
    }
    
    self.videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
    
    // Set the video orientation to be portrait only for simplicity.
    self.videoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoConnection.videoOrientation = self.videoOrientation;
    
    self.captureSession = captureSession;
    
	// Create a shallow queue for buffers going to the display for preview.
	CMBufferQueueCreate(kCFAllocatorDefault, 1, CMBufferQueueGetCallbacksForUnsortedSampleBuffers(), &previewBufferQueue);
    
    // Create serial queue for movie writing.
    // Note that the video writer iself won't be created until we have a CMFormatDescriptionRef to use for setting it up.
    movieWritingQueue = dispatch_queue_create("Movie Writing Queue", DISPATCH_QUEUE_SERIAL);
    
    // Set the default filter as no filter
    self.currentFilter = [Filter new];
}

- (AVCaptureDevice *)backwardFacingCameraDevice {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == AVCaptureDevicePositionBack) {
    
            // Set conservative frame rate.
            [device lockForConfiguration:nil];
            device.activeVideoMaxFrameDuration = CMTimeMake(1, FRAME_RATE);
            device.activeVideoMinFrameDuration = CMTimeMake(1, FRAME_RATE);
            [device unlockForConfiguration];
            
            return device;
        }
    }
    
    return nil;
}

- (void)setupVideoWriter:(CMFormatDescriptionRef)formatDescription {
    
    // Set the file URL. This is duplicated in other places in this project.
    // For a production app, this would need to be consolidated.
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *moviePath = [documentsPath stringByAppendingPathComponent:@"movie.mov"];
    self.recordedFileURL = [NSURL fileURLWithPath:moviePath];
    
    // Delete the file if it exists else AVAssetWriter will through an exception.
    [self removeFile:self.recordedFileURL];
    
    // Create an asset writer
    NSError *error;
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:self.recordedFileURL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error) {
        NSLog(@"Could not create writer for video. %@", error.localizedDescription);
        return;
    }
    
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
    CGSize videoSize = CGSizeMake(dimensions.width / 2, dimensions.height / 2);
	int numPixels = videoSize.width * videoSize.height;
    
    // This bitrate matches the quality produced by AVCaptureSessionPresetHigh.
    float bitsPerPixel = 11.4;
    int bitsPerSecond = numPixels * bitsPerPixel;
    
    NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              AVVideoCodecH264, AVVideoCodecKey,
                                              [NSNumber numberWithInteger:videoSize.width], AVVideoWidthKey,
                                              [NSNumber numberWithInteger:videoSize.height], AVVideoHeightKey,
                                              [NSDictionary dictionaryWithObjectsAndKeys:
                                               [NSNumber numberWithInteger:bitsPerSecond], AVVideoAverageBitRateKey,
                                               [NSNumber numberWithInteger:FRAME_RATE], AVVideoMaxKeyFrameIntervalKey,
                                               nil], AVVideoCompressionPropertiesKey,
                                              nil];
    if ([self.assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]) {
        self.assetWriterVideoIn = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
        self.assetWriterVideoIn.expectsMediaDataInRealTime = YES;
        if ([self.assetWriter canAddInput:self.assetWriterVideoIn])
            [self.assetWriter addInput:self.assetWriterVideoIn];
        else {
            NSLog(@"Couldn't add asset writer video input");
            return;
        }
    } else {
        NSLog(@"Couldn't apply video output settings");
        return;
    }
    
    self.readyToRecordVideo = YES;
}

- (void)startRecordingSession {
    [self.captureSession startRunning];
}

- (void)endRecordingSession {
    [self.captureSession stopRunning];
    
    if (!self.assetWriterVideoIn.readyForMoreMediaData) {
        return;  // Can't finish a write unless the writer is in a good state
    }
    
    dispatch_async(movieWritingQueue, ^{
        [self.assetWriterVideoIn markAsFinished];
        [self.assetWriter finishWritingWithCompletionHandler:^{
            if (self.assetWriter.status == AVAssetWriterStatusCompleted) {
                self.assetWriterVideoIn = nil;
                self.assetWriter = nil;
                NSLog(@"Finished writing to video file");
            } else {
                NSLog(@"Could not finish video write session. %@", self.assetWriter.error.localizedDescription);
            }
        }];
    });
}

- (void)removeFile:(NSURL *)fileURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [fileURL path];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success) {
            NSLog(@"Error deleting URL: %@", fileURL);
        }
    }
}

- (void)setSelectedFilterIndex:(int)selectedFilterIndex {
    switch (selectedFilterIndex) {
        case 0:
            self.currentFilter = [Filter new];
            break;
        case 1:
            self.currentFilter = [NoGreenFilter new];
            break;
        case 2:
            self.currentFilter = [InverseFilter new];
            break;
        case 3:
            self.currentFilter = [SwapFilter new];
            break;
        default:
            break;
    }
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate methods

// Sample captured on videoCaptureQueue
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Lock the base address of this pixel buffer
	CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
    
    // Process the pixel buffer
    [self.currentFilter processPixelBuffer:pixelBuffer];
    
    // Get a resized CGImage from this buffer for display in the view
    CGImageRef resizedImage = [self convertPixelBufferToImage:pixelBuffer];
    
    // Enqueue it for preview. This is a shallow queue, so if image processing is taking too long,
    // we'll drop this frame for preview (this keeps preview latency low).
    // BTE note: I got this from Apple's "Rosy Writer" sample app.
    OSStatus err = CMBufferQueueEnqueue(previewBufferQueue, sampleBuffer);
    if ( !err ) {        
        dispatch_async(dispatch_get_main_queue(), ^{
            CMSampleBufferRef sbuf = (CMSampleBufferRef)CMBufferQueueDequeueAndRetain(previewBufferQueue);
            if (sbuf) {
                _previewLayer.contents = (__bridge id) resizedImage;
                CGImageRelease(resizedImage);
                CFRelease(sbuf);
            }
        });
    }
    
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(pixelBuffer,0);
    
    // Write the sample buffer to the asset writer. If it's not yet configured, do so now.
	CFRetain(sampleBuffer);
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
	CFRetain(formatDescription);
    
   	dispatch_async(movieWritingQueue, ^{
        if (self.assetWriter) {
            if (self.readyToRecordVideo) {
                if (self.assetWriter.status == AVAssetWriterStatusUnknown) {
                    if ([self.assetWriter startWriting]) {
                        NSLog(@"Start writing");
                        [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                    }
                }
                
                if (self.assetWriterVideoIn.readyForMoreMediaData) {
                    if (![self.assetWriterVideoIn appendSampleBuffer:sampleBuffer]) {
                        NSLog(@"Could not add video frames to video. %@", self.assetWriter.error.localizedDescription);
                    }
                }
            }
        } else {
            [self setupVideoWriter:formatDescription];
        }
        
        CFRelease(sampleBuffer);
        CFRelease(formatDescription);
    });
}

#pragma mark Image Processing

- (CGImageRef)convertPixelBufferToImage:(CVImageBufferRef)pixelBuffer {
    
    // Attain the base address of this pixel buffer
    unsigned char *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    // Convert the pixel buffer into a resized image.
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Resize to fit display
    CGContextRef resizedContext = CGBitmapContextCreate(NULL, self.previewLayerSize.width, self.previewLayerSize.height, 8, 4 * self.previewLayerSize.width, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(resizedContext, CGRectMake(0, 0, self.previewLayerSize.width, self.previewLayerSize.height), quartzImage);
    CGImageRef resizedQuartzImage = CGBitmapContextCreateImage(resizedContext);
    
    CGImageRelease(quartzImage);
    
    return resizedQuartzImage;
}

@end

