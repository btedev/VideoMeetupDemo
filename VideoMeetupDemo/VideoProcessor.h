//
//  VideoProcessor.h
//  VideoMeetupDemo
//
//  Created by BARRY EZELL on 6/25/15.
//  Copyright (c) 2015 Barry Ezell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

@interface VideoProcessor : NSObject

@property (nonatomic, readonly) AVCaptureSession *captureSession;
@property (atomic, getter=isRecording) BOOL recording;
@property (nonatomic)   int selectedFilterIndex;

- (void)setupCaptureSession:(CALayer*)previewLayer;
- (void)startRecordingSession;
- (void)endRecordingSession;

@end
