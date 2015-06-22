//
//  FFInputFile.m
//  LiveStreamer
//
//  Created by Christopher Ballinger on 10/1/13.
//  Copyright (c) 2013 OpenWatch, Inc. All rights reserved.
//

#import "FFInputFile.h"
#import "FFInputStream.h"
#import "FFUtilities.h"

NSString const *kFFmpegInputFormatKey = @"kFFmpegInputFormatKey";

@implementation FFInputFile
@synthesize endOfFileReached, timestampOffset, lastTimestamp, formatContext;

- (void) dealloc {
    avformat_close_input(&formatContext);
}

- (AVFormatContext*) formatContextForInputPath:(NSString*)inputPath options:(NSDictionary*)options {
    // You can override the detected input format
    AVFormatContext *inputFormatContext = NULL;
    AVInputFormat *inputFormat = NULL;
    AVDictionary *inputOptions = NULL;
    
    NSString *inputFormatString = [options objectForKey:kFFmpegInputFormatKey];
    if (inputFormatString) {
        inputFormat = av_find_input_format([inputFormatString UTF8String]);
    }
    
    // It's possible to send more options to the parser
    
    
    
    
    //av_dict_set(&inputOptions, "s", "320x240", 0);
//    av_dict_set(&inputOptions, "pixel_format", "rgb24", 0);
//    av_dict_free(&inputOptions); // Don't forget to free
    
//    AVDictionaryEntry *e;
//    if (e = av_dict_get(inputOptions, "", NULL, AV_DICT_IGNORE_SUFFIX)) {
//        fprintf(stderr, "Option %s not recognized by the demuxer.\n", e->key);
//        //abort();
//    }
    
    int openInputValue = avformat_open_input(&inputFormatContext, [inputPath UTF8String], inputFormat, &inputOptions);
    if (openInputValue != 0) {
        avformat_close_input(&inputFormatContext);
        return nil;
    }
    
    int streamInfoValue = avformat_find_stream_info(inputFormatContext, &inputOptions);
    if (streamInfoValue < 0) {
        avformat_close_input(&inputFormatContext);
        return nil;
    }
    
//    av_dict_free(&inputOptions);
    
    return inputFormatContext;
}

- (void) populateStreams {
    NSUInteger inputStreamCount = formatContext->nb_streams;
    NSMutableArray *inputStreams = [NSMutableArray arrayWithCapacity:inputStreamCount];
    for (int i = 0; i < inputStreamCount; i++) {
        AVStream *inputStream = formatContext->streams[i];
        FFInputStream *ffInputStream = [[FFInputStream alloc] initWithInputFile:self stream:inputStream];
        [inputStreams addObject:ffInputStream];
    }
    self.streams = inputStreams;
}

- (id) initWithPath:(NSString *)path options:(NSDictionary *)options {
    if (self = [super initWithPath:path options:options]) {
        self.formatContext = [self formatContextForInputPath:path options:options];
        [self populateStreams];
    }
    return self;
}

- (BOOL) readFrameIntoPacket:(AVPacket*)packet error:(NSError *__autoreleasing *)error {
    BOOL continueReading = YES;
    int frameReadValue = av_read_frame(self.formatContext, packet);
    if (frameReadValue != 0) {
        continueReading = NO;
        if (frameReadValue != AVERROR_EOF) {
            if (error != NULL) {
                *error = [FFUtilities errorForAVError:frameReadValue];
            }
        }
        av_free_packet(packet);
    }
    return continueReading;
}

@end
