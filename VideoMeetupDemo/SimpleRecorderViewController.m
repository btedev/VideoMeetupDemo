//
//  SimpleRecorderViewController.m
//  VideoMeetupDemo
//
//  Created by BARRY EZELL on 6/24/15.
//  Copyright (c) 2015 Barry Ezell. All rights reserved.
//

#import "SimpleRecorderViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>

@interface SimpleRecorderViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@end

@implementation SimpleRecorderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self displayCamera];
}

- (void)displayCamera {
    UIImagePickerController *camera = [UIImagePickerController new];
    camera.delegate = self;
    
    // Specify that we want to use the camera.
    camera.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    // Specify that we only want to record movies.
    camera.mediaTypes = @[(NSString *) kUTTypeMovie];
    
    [self presentViewController:camera
                       animated:NO
                     completion:nil];
}

- (void)popToParentVC {
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIImagePickerController delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    // Copy the video locally. First get the URL of the recorded video.
    NSURL *movieSourceURL = [info objectForKey:UIImagePickerControllerMediaURL];
    
    // Create a file URL called "movie.mov" in the Documents directory.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *movieTargetPath = [documentsPath stringByAppendingPathComponent:@"movie.mov"];
    NSURL *movieTargetURL = [NSURL fileURLWithPath:movieTargetPath];
    
    // Copy the video.
    NSError *error;
    [fileManager copyItemAtURL:movieSourceURL toURL:movieTargetURL error:&error];
    
    if (error) {
        NSLog(@"Error copying movie at URL: %@", movieSourceURL);
    }
    
    [self popToParentVC];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self popToParentVC];
}

@end
