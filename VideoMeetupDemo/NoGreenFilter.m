//
//  NoGreenFilter.m
//  VideoMeetupDemo
//
//  Created by BARRY EZELL on 6/25/15.
//  Copyright (c) 2015 Barry Ezell. All rights reserved.
//

#import "NoGreenFilter.h"

@implementation NoGreenFilter

- (void)processPixelBuffer:(CVImageBufferRef)pixelBuffer {
	size_t bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
	size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
	unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);

    // Perform the conversion on each pixel in the buffer.
	for( int row = 0; row < bufferHeight; row++ ) {		
		for( int column = 0; column < bufferWidth; column++ ) {
			pixel[1] = 0; // De-green (second pixel in BGRA is green)
			pixel += BYTES_PER_PIXEL;
		}
	}
}

@end
