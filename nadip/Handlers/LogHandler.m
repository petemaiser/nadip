//
//  LogHandler.m
//  nadip
//
//  Created by Pete Maiser on 2/11/18.
//  Copyright © 2018 Pete Maiser. All rights reserved.
//

#import "LogHandler.h"
#import "ServerController.h"
#import "NSString+ResponseString.h"

@interface LogHandler ()
@property  void (^callbackBlockForLogStrings)(NSString *);
@end

@implementation LogHandler

- (instancetype)initForServerController:(ServerController *)serverController
                           withFileName:(NSString *)fileName
{
    self = [super initForServerController:serverController withFileName:fileName];
    
    if (self) {
    
        // Create a block to send to the DataStreamConnector for its logging
        __weak LogHandler *weakSelf = self;
        self.callbackBlockForLogStrings = ^(NSString *logString) {
            [weakSelf handleLogString:logString];
        };
        [self.serverController addBlockForLogStrings:self.callbackBlockForLogStrings];
        
    }
    
    return self;
}

- (void)handleResponseString:(NSString *)str
{
    if (![str isEqualToString:@""]) {
        NSString *formattedString = [NSString stringWithFormat:@"PARSED FROM RECEIVED BYTES:  %@", str];
        [self writeString:formattedString];
    }
}

- (void)handleLogString:(NSString *)str
{
    if ([str isEqualToString:@""]) {
        return;
    }
    [self writeString:str];
}

- (void)writeString:(NSString *)str
{
    if (![[str nad_response] isInSet:self.ignoreSet]) {
        if ([self.fileName isEqualToString:@""])
        {
            NSLog(@"%@", str);
        } else
        {
            NSString *programName = [NSString stringWithUTF8String:getprogname()];
            
            NSDate *date = [NSDate date];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
            
            NSString *formattedString = [NSString stringWithFormat:@"%@ %@: %@\n", programName ,[dateFormatter stringFromDate:date], str];
            
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
