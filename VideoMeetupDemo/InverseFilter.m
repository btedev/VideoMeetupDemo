//
//  InverseFilter.m
//  VideoMeetupDemo
//
//  Created by BARRY EZELL on 6/25/15.
//  Copyright (c) 2015 Barry Ezell. All rights reserved.
//

#import "InverseFilter.h"

@implementation InverseFilter

- (void)processPixelBuffer:(CVImageBufferRef)pixelBuffer {
    size_t bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    // Perform the conversion on each pixel in the buffer.
    for( int row = 0; row < bufferHeight; row++ ) {
        for( int column = 0; column < bufferWidth; column++ ) {
            
            // Format is BGRA
            pixel[0] = 255 - pixel[0]; // B
            pixel[1] = 255 - pixel[1]; // G
            pixel[2] = 255 - pixel[2]; // R
            pixel += BYTES_PER_PIXEL;
        }
    }
}

@end
