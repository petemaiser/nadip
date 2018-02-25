//
//  ServerController.h
//  nadsetvar
//  DTrol
//  nadip
//
//  Created by Pete Maiser on 2/7/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//  Copyright © 2018 Pete Maiser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Controller.h"

@interface ServerController : Controller <NSStreamDelegate>



@property (nonatomic, copy) NSString *nameShort;
@property (nonatomic, copy) NSString *nameLong;
@property (nonatomic, copy) NSString *address;

- (instancetype)initWithIPAddress:(NSString *)serverIPAddress
                             port:(uint)serverPort
            lineTerminationString:(NSString *)termString;

typedef NS_ENUM(NSInteger, StringFragmentProcessingType) {
     stringFragmentProcessingNone   = 1 << 0    // Incoming string fragments are processed like any other string
    ,stringFragmentProcessingMended = 1 << 1    // String fragments (a non-terminated incoming string) will not be directly processed,
                                                //      they will be prepened to the beginning of the next recieved string
    ,stringFragmentProcessingSafe   = 1 << 2    // Mends the strig like Mended, but the fragment and the beginning of the next recieved string
                                                // will also be processed independently
};
@property (nonatomic) StringFragmentProcessingType stringFragmentProcessingType; // Defaults to stringFragmentProcessingNone
@property BOOL treatSpaceAsLineTerminationSend;     // Defaults to YES so spaces are treated the same as the line termination string when sending
@property BOOL treatSpaceAsLineTerminationReceive;  // Defaults to NO so spaces are not considered a line termination string

- (void)addBlockForIncomingStrings:(void (^)(NSString *))callbackBlock;
- (void)removeBlockForIncomingStrings:(void (^)(NSString *))callbackBlock;
- (void)addBlockForLogStrings:(void (^)(NSString *))callbackBlock;
- (void)removeBlockForLogStrings:(void (^)(NSString *))callbackBlock;

- (void)openStreams;
- (void)closeStreams;

- (void)sendString:(NSString *)str;
- (void)sendStringTest:(NSString *)str; // Doesn't actually send the string, just sends it straight through to the response handler

#define StreamsReadyNotificationString @"StreamsReady"
#define StreamClosedNotificationString @"StreamClosed"
#define StreamErrorNotificationString @"StreamError"
#define StreamNewDataNotificationString @"StreamNewData"

@end
