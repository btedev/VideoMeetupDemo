//
//  Filter.h
//  VideoMeetupDemo
//
//  Created by BARRY EZELL on 6/25/15.
//  Copyright (c) 2015 Barry Ezell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

#define BYTES_PER_PIXEL 4 // Using BGRA format

@interface Filter : NSObject

- (void)processPixelBuffer:(CVImageBufferRef)pixelBuffer;

@end
