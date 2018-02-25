//
//  ServerController.m
//  nadsetvar
//  DTrol
//  nadip
//
//  Created by Pete Maiser on 2/7/16.
//  Copyright © 2016 Pete Maiser. All rights reserved.
//  Copyright © 2018 Pete Maiser. All rights reserved.
//

#import "ServerController.h"

@interface ServerController ()

@property (nonatomic) NSString *serverIPAddress;
@property uint serverPort;
@property (nonatomic, copy) NSString *lineTerminationString;

@property (nonatomic) NSMutableData *data;
@property (nonatomic) NSInputStream *iStream;
@property (nonatomic) NSOutputStream *oStream;
@property (nonatomic) NSMutableArray *blocksForIncomingStream;
@property (nonatomic) NSMutableArray *blocksForLogOutput;

@property BOOL isConnected;
@property (nonatomic) NSString *stringFragment;

@end


@implementation ServerController

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    
    
    NSString * status = [NSString stringWithFormat:@"WARNING init called, but generally for this class initWithIPAddress:port: should be used as designated initializer.  Execution will continue."];
    [self logString:status];
    
    return self;
}

- (instancetype)initWithIPAddress:(NSString *)serverIPAddress
                             port:(uint)serverPort
            lineTerminationString:(NSString *)termString
{
    self = [super init];
    
    if (self) {
        
        // Set defalts
        self.serverIPAddress = serverIPAddress;
        self.serverPort = serverPort;
        self.address = [[NSString alloc] initWithFormat:@"%@:%u", serverIPAddress, serverPort];
        self.nameShort = @"";
        self.nameLong = [[NSString alloc] initWithFormat:@"Server at %@", self.address];
        self.stringFragmentProcessingType = stringFragmentProcessingNone;
        self.treatSpaceAsLineTerminationSend = YES;
        self.treatSpaceAsLineTerminationReceive = NO;
        self.lineTerminationString = termString;
        self.blocksForIncomingStream = nil;
        self.blocksForLogOutput = nil;
        self.isConnected = NO;
        self.stringFragment = @"";
    }
    
    return self;
}

- (void)openStreams
{
    if (self) {
        
        CFReadStreamRef readStream = NULL;
        CFWriteStreamRef writeStream = NULL;
        
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                           (__bridge CFStringRef)(self.serverIPAddress),
                                           self.serverPort,
                                           &readStream,
                                           &writeStream);
        
        if (readStream && writeStream) {
            CFReadStreamSetProperty(readStream,
                                    kCFStreamPropertyShouldCloseNativeSocket,
                                    kCFBooleanTrue);
            CFWriteStreamSetProperty(writeStream,
                                     kCFStreamPropertyShouldCloseNativeSocket,
                                     kCFBooleanTrue);
            
            self.iStream = (__bridge NSInputStream *)readStream;
            [self.iStream setDelegate:self];
            [self.iStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                    forMode:NSDefaultRunLoopMode];
            [self.iStream open];
            
            self.oStream = (__bridge NSOutputStream *)writeStream;
            [self.oStream setDelegate:self];
            [self.oStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                    forMode:NSDefaultRunLoopMode];
            [self.oStream open];
        }
    }
}


#pragma mark - Callback setup and management

- (void)addBlockForIncomingStrings:(void (^)(NSString *))callbackBlock
{
    if (!self.blocksForIncomingStream) {
        self.blocksForIncomingStream = [[NSMutableArray alloc] init];
    }
    [self.blocksForIncomingStream addObject:callbackBlock];
}

- (void)removeBlockForIncomingStrings:(void (^)(NSString *))callbackBlock
{
    if (self.blocksForIncomingStream) {
        [self.blocksForIncomingStream removeObject:callbackBlock];
    }
}

- (void)addBlockForLogStrings:(void (^)(NSString *))callbackBlock
{
    if (!self.blocksForLogOutput) {
        self.blocksForLogOutput = [[NSMutableArray alloc] init];
    }
    [self.blocksForLogOutput addObject:callbackBlock];
}
- (void)removeBlockForLogStrings:(void (^)(NSString *))callbackBlock
{
    if (self.blocksForLogOutput) {
        [self.blocksForLogOutput removeObject:callbackBlock];
    }
}


#pragma mark - Server Interaction

- (void)stream:(NSStream *)stream
   handleEvent:(NSStreamEvent)eventCode
{
    // NSStreamDelegate
    
    NSString *streamID = @"";
    
    if (stream == self.iStream) {
        streamID = @"READ ";
    } else if (stream == self.oStream) {
        streamID = @"WRITE ";
    }
    
    NSNotification *eventNotification = nil;
    NSPostingStyle eventNotificationPostingStye = NSPostASAP;
    
    switch(eventCode) {
            
        case NSStreamEventEndEncountered:{
            
            [stream close];
            [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            
            NSString * status = [NSString stringWithFormat:@"%@CONNECTION CLOSED (%@)", streamID, self.nameShort];
            [self logString:status];
            
            if ( (self.isConnected == NO) &&
                ([self streamsClosed]) )
            {
                eventNotification = [NSNotification notificationWithName:StreamClosedNotificationString object:self];
            }
            self.isConnected = NO;
            
        } break;
            
        case NSStreamEventErrorOccurred:{
            
            NSString * status = [NSString stringWithFormat:@"ERROR OCCURRED IN %@STREAM (%@)", streamID, self.nameShort];
            [self logString:status];
            
            eventNotification = [NSNotification notificationWithName:StreamErrorNotificationString object:self];
            eventNotificationPostingStye = NSPostWhenIdle;
            
        } break;
            
        case NSStreamEventHasBytesAvailable:{
            
            if (self.data == nil) {
                self.data = [[NSMutableData alloc] init];
            }
            
            uint8_t buf[1024];
            NSInteger len = 0;
            len = [(NSInputStream *)stream read:buf maxLength:1024];
            
            if(len) {
                NSString * status = [NSString stringWithFormat:@"RECEIVED (%@):  %ld bytes", self.nameShort, (long)len];
                [self logString:status];
                [self.data appendBytes:(const void *)buf length:len];
            } else {
                NSString * status = [NSString stringWithFormat:@"NO DATA IN %@STREAM (%@)", streamID, self.nameShort];
                [self logString:status];
            }
            
            NSString *receiveString = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
            [self handleResponseString:receiveString];
            eventNotification = [NSNotification notificationWithName:StreamNewDataNotificationString object:self];
            self.data = nil;
            
        } break;
            
        case NSStreamEventOpenCompleted:{
            
            NSString * status = [NSString stringWithFormat:@"%@CONNECTION OPEN (%@)", streamID, self.nameShort];
            [self logString:status];
            
            if ( !self.isConnected && [self streamsReady]) {
                self.isConnected = YES;
                eventNotification = [NSNotification notificationWithName:StreamsReadyNotificationString object:self];
            }
            
        } break;
            
        default:
            break;
    }
    
    if (eventNotification) {
        [[NSNotificationQueue defaultQueue] enqueueNotification:eventNotification
                                                   postingStyle:eventNotificationPostingStye
                                                   coalesceMask:NSNotificationCoalescingOnName|NSNotificationCoalescingOnSender
                                                       forModes:nil];
    }
}
    
- (void)handleResponseString:(NSString *)str
{
    if ((str) &&
        (![str isEqualToString:@""]))
    {
        if (self.blocksForIncomingStream) {
            
            NSString *receiveString;
            if (self.treatSpaceAsLineTerminationReceive) {
                receiveString = [str stringByReplacingOccurrencesOfString:@" "
                                                            withString:self.lineTerminationString];
            } else {
                receiveString = str;
            }

            // Divide the string by any terminators
            NSArray *receiveStrings = [receiveString componentsSeparatedByString:self.lineTerminationString];
            NSInteger stringCount = [receiveStrings count];
            
            // Process the first string
            if (stringCount > 0) {
                
                // Pre-pend the fragment from the previous event, if applicable
                // See the FRAGMENT PROCESSING comment below for more information
                if (self.stringFragmentProcessingType & (stringFragmentProcessingMended|stringFragmentProcessingSafe))
                {
                    NSString * mendedString = [NSString stringWithFormat:@"%@%@", self.stringFragment, [receiveStrings objectAtIndex:0]];
                    for (void (^callbackBlock)(NSString *) in self.blocksForIncomingStream) {
                        callbackBlock(mendedString);
                    }
                }
                
                // Process the first string as it is, with no "mending"
                if (self.stringFragmentProcessingType & (stringFragmentProcessingNone|stringFragmentProcessingSafe))
                {
                    for (void (^callbackBlock)(NSString *) in self.blocksForIncomingStream) {
                        callbackBlock([receiveStrings objectAtIndex:0]);
                    }
                }
                
            }
            
            // Process the rest of the strings - stop before the very last string though
            for (NSInteger i = 1; i < (stringCount - 1); i++)
            {
                NSString *responseString = [receiveStrings objectAtIndex:i];
                for (void (^callbackBlock)(NSString *) in self.blocksForIncomingStream) {
                    callbackBlock(responseString);
                }
            }
            
            // FRAGMENT PROCESSING
            // The for loop above leaves out the last string. The componentsSeparatedByString: method will produce an empty string
            // as the last component if the string ends with the separator - which is the expected behavior here (the server should
            // be separating every command by the lineTerminationString) and thus stopping here should be fine.  EXCEPT -
            // if the last string is NOT empty...that means that for whatever reason* a response from the server may have been
            // cut-off.  That last non-empty string may be a fragment of a complete string, and the first string in the next set
            // of received data may be the rest of it.  So let's save it.  We will process it later by with the next first string
            // in the next event by prepending this bit of string on to the first string in the next event.
            
            // * Why would this happen?  The buffer may be full (make the buffer bigger you say? well at some point it has to have a limit);
            // I have also seen cases where strings seem to get cut-off, probably a timing issue of some fashion in NSStream.
            // Might as well just handle the case as it does seem to happen and handling it in this way does little if any harm.
            
            if (stringCount > 1) {
                
                // Save the fragment
                self.stringFragment = [receiveStrings objectAtIndex:(stringCount-1)];
                
                // Process the fragment now, if applicable
                if ((self.stringFragmentProcessingType & (stringFragmentProcessingNone|stringFragmentProcessingSafe)) &&
                    (![self.stringFragment isEqualToString:@""]) &&
                    (self.blocksForIncomingStream))
                {
                    for (void (^callbackBlock)(NSString *) in self.blocksForIncomingStream) {
                        callbackBlock(self.stringFragment);
                    }
                }
                
            }
            
        } else {
            // A callback block is not set for recieved data, so write any received data to NSLog
            NSString * status = [NSString stringWithFormat:@"%@", str];
            [self logString:status];
        }
    }
}

- (void)sendString:(NSString *)str
{
    if ((str) &&
        (![str isEqualToString:@""]))
    {
        NSString *sendString;
        
        if (self.treatSpaceAsLineTerminationSend) {
            sendString = [str stringByReplacingOccurrencesOfString:@" "
                                                        withString:self.lineTerminationString];
        } else {
            sendString = str;
        }
        
        if(![sendString hasSuffix:self.lineTerminationString]) {
            sendString = [NSString stringWithFormat:@"%@%@", str, self.lineTerminationString];
        }
        
        const uint8_t *sendBuffer = (uint8_t *)[sendString cStringUsingEncoding:NSASCIIStringEncoding];
        [self.oStream write:sendBuffer maxLength:strlen((char*)sendBuffer)];
        
        NSString * status = [NSString stringWithFormat:@"SENT (%@): %@", self.nameShort, str];
        [self logString:status];
    }
}
    
- (void)sendStringTest:(NSString *)str
{
    [self handleResponseString:str];
}


#pragma mark - Admin

- (void)closeStreams
{
    if (![self streamsClosed]) {
        
        NSString *status = nil;
        [self.oStream close];
        status = [NSString stringWithFormat:@"CLOSING WRITE CONNECTION (%@)", self.nameShort];
        [self logString:status];
        
        status = nil;
        [self.iStream close];
        status = [NSString stringWithFormat:@"CLOSING READ CONNECTION (%@)", self.nameShort];
        [self logString:status];
        
        self.isConnected = NO;
        
        NSNotification *eventNotification = [NSNotification notificationWithName:StreamClosedNotificationString object:self];
        if (eventNotification) {
            [[NSNotificationQueue defaultQueue] enqueueNotification:eventNotification
                                                       postingStyle:NSPostASAP
                                                       coalesceMask:NSNotificationCoalescingOnName
                                                           forModes:nil];
        }
    }
}

- (BOOL)streamsReady
{
    NSStreamStatus readStreamStatus = [self.iStream streamStatus];
    NSStreamStatus writeStreamStatus = [self.oStream streamStatus];
    
    if ( ( (readStreamStatus == NSStreamStatusOpen) ||
          (readStreamStatus == NSStreamStatusReading) ||
          (readStreamStatus == NSStreamStatusWriting) ) &&
        (
         (writeStreamStatus == NSStreamStatusOpen) ||
         (writeStreamStatus == NSStreamStatusReading) ||
         (writeStreamStatus == NSStreamStatusWriting) )  )
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)streamsNeedOpen
{
    NSStreamStatus readStreamStatus = [self.iStream streamStatus];
    NSStreamStatus writeStreamStatus = [self.oStream streamStatus];
    
    if ( (readStreamStatus == NSStreamStatusNotOpen) ||
        (readStreamStatus == NSStreamStatusClosed) ||
        (readStreamStatus == NSStreamStatusError) ||
        (writeStreamStatus == NSStreamStatusNotOpen) ||
        (writeStreamStatus == NSStreamStatusClosed) ||
        (writeStreamStatus == NSStreamStatusError) )
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)streamsClosed
{
    NSStreamStatus readStreamStatus = [self.iStream streamStatus];
    NSStreamStatus writeStreamStatus = [self.oStream streamStatus];
    
    if ( (readStreamStatus == NSStreamStatusClosed) &&
        (writeStreamStatus == NSStreamStatusClosed) )
    {
        return YES;
    }
    
    return NO;
}

- (void)logString:(NSString *)str
{
    if ((str) &&
        (![str isEqualToString:@""]) &&
        (self.blocksForLogOutput))
    {
        for (void (^callbackBlock)(NSString *) in self.blocksForLogOutput) {
            callbackBlock(str);
        }
    }
}

@end
