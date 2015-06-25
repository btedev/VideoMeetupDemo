//
//  SwapFilter.m
//  VideoMeetupDemo
//
//  Created by BARRY EZELL on 6/25/15.
//  Copyright (c) 2015 Barry Ezell. All rights reserved.
//

#import "SwapFilter.h"

@implementation SwapFilter

- (void)processPixelBuffer:(CVImageBufferRef)pixelBuffer {
    size_t bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    // Perform the conversion on each pixel in the buffer.
    for( int row = 0; row < bufferHeight; row++ ) {
        for( int column = 0; column < bufferWidth; column++ ) {
            
            // Format is BGRA
            pixel[0] = pixel[1];
            pixel[1] = pixel[2];
            pixel[2] = pixel[0];
            pixel += BYTES_PER_PIXEL;
        }
    }
}

@end
