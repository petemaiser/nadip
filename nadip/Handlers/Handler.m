//
//  Handler.m
//  nadip
//
//  Created by Pete Maiser on 2/11/18.
//  Copyright © 2018 Pete Maiser. All rights reserved.
//

#import "Handler.h"
#import "ServerController.h"
#import "NSString+ResponseString.h"

@interface Handler ()
@property  void (^callbackBlockForReceivedStrings)(NSString *);
@end

@implementation Handler

- (instancetype)initForServerController:(ServerController *)serverController
                           withFileName:(NSString *)fileName
{
    self = [super init];
    
    if (self) {
        
        // Create a block to send to the DataStreamConnector for when it gets data back from the server
        __weak Handler *weakSelf = self;
        self.callbackBlockForReceivedStrings = ^(NSString *responseString) {
            [weakSelf handleResponseString:responseString];
        };
        
        self.serverController = serverController;
        self.fileName = fileName;
        self.ignoreSet = nil;
    }
    
    return self;
}

- (void)setServerController:(ServerController *)serverController
{
    if (_serverController) {
        [_serverController removeBlockForIncomingStrings:self.callbackBlockForReceivedStrings];
    }
    [serverController addBlockForIncomingStrings:self.callbackBlockForReceivedStrings];
    _serverController = serverController;
}

- (void)handleResponseString:(NSString *)str
{
    if (![str isEqualToString:@""]) {
        [self writeString:str];
    }
}

- (void)writeString:(NSString *)str
{
    if (![[str nad_response] isInSet:self.ignoreSet]) {
        if ([self.fileName isEqualToString:@""])
        {
            NSLog(@"%@", str);
        } else
        {
            NSString *formattedString = [NSString stringWithFormat:@"%@\n", str];
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if([fileManager fileExistsAtPath:self.fileName])
            {
                NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:self.fileName];
                [myHandle seekToEndOfFile];
                [myHandle writeData:[formattedString dataUsingEncoding:NSUTF8StringEncoding]];
            }
            else
            {
                [formattedString writeToFile:self.fileName
                                  atomically:YES
                                    encoding:NSUTF8StringEncoding
                                       error:nil];
            }
        }
    }
}

@end
