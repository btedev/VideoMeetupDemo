//
//  MasterViewController.m
//  VideoMeetupDemo
//
//  Created by BARRY EZELL on 6/23/15.
//  Copyright (c) 2015 Barry Ezell. All rights reserved.
//

#import "MasterViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface MasterViewController ()

@property NSMutableArray *objects;
@end

@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)playRecordedVideo {
    NSURL *movieURL = [self recordedMovieURL];
    
    if (!movieURL) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Record a video first"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    MPMoviePlayerViewController *mPlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:movieURL];
    [self presentMoviePlayerViewControllerAnimated:mPlayer];
}

- (NSURL *)recordedMovieURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *moviePath = [documentsPath stringByAppendingPathComponent:@"movie.mov"];
    
    if ([fileManager fileExistsAtPath:moviePath]) {
        return [NSURL fileURLWithPath:moviePath];
    } else {
        return nil;
    }
}

#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 2) {
        [self playRecordedVideo];
    }
}

@end
