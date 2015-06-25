//
//  AVFRecorderViewController.m
//  VideoMeetupDemo
//
//  Created by BARRY EZELL on 6/25/15.
//  Copyright (c) 2015 Barry Ezell. All rights reserved.
//

#import "AVFRecorderViewController.h"
#import "VideoProcessor.h"

@interface AVFRecorderViewController ()

@property (nonatomic)   VideoProcessor *videoProcessor;
@property (nonatomic)   IBOutlet UIView *previewView;
@property (nonatomic)   CALayer  *previewLayer;

@end

@implementation AVFRecorderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"GeoCitiesBackground"]];
    
    // Manually request camera access.
    [self checkDeviceAuthorizationStatus];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.videoProcessor endRecordingSession];
}

- (void)didReceiveMemoryWarning {
    NSLog(@"Better take this seriously because memory can get out of hand quickly when using AVFoundation");
    [super didReceiveMemoryWarning];
}

- (void)checkDeviceAuthorizationStatus {
	[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
		if (granted) {
			//Granted access to mediaType
            NSLog(@"AVMediaTypeVideo device authorized");
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self configAfterAuthCheck];
            });
		} else {
			//Not granted access to mediaType
            NSLog(@"AVMediaTypeVideo device not authorized");
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [[[UIAlertView alloc] initWithTitle:@"Permission Needed"
                                            message:@"This app doesn't have permission to record video, please enable in iOS Settings"
                                           delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            });
		}
	}];
}

- (void)configAfterAuthCheck {
    // Setup a video preview layer.
    self.previewLayer = [CALayer layer];
    self.previewLayer.bounds = CGRectMake(0, 0, CGRectGetWidth(self.previewView.frame), CGRectGetHeight(self.previewView.frame));
    self.previewLayer.position = CGPointMake(CGRectGetWidth(self.previewView.frame) / 2, CGRectGetHeight(self.previewView.frame) / 2);
    [self.previewView.layer addSublayer:self.previewLayer];
    
    // Start our video processor.
    self.videoProcessor = [VideoProcessor new];
    [self.videoProcessor setupCaptureSession:self.previewLayer];
    
    if (!self.videoProcessor.captureSession) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Cannot create capture session"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        
        NSLog(@"Cannot create capture session");
        return;
    }
    
    [self.videoProcessor startRecordingSession];
}

- (IBAction)filterSelectionChanged:(id)sender {
    UISegmentedControl *control = (UISegmentedControl *)sender;
    
    if (self.videoProcessor) {
        self.videoProcessor.selectedFilterIndex = (int) control.selectedSegmentIndex;
    }
}


@end
