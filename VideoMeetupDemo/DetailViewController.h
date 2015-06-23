//
//  DetailViewController.h
//  VideoMeetupDemo
//
//  Created by BARRY EZELL on 6/23/15.
//  Copyright (c) 2015 Barry Ezell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

