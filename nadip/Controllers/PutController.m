//
//  PutController.m
//  nadip
//
//  Created by Pete Maiser on 2/11/18.
//  Copyright © 2018 Pete Maiser. All rights reserved.
//

#import "PutController.h"
#import "ServerController.h"

@interface PutController ()
    
@property (nonatomic) ServerController *serverController;
@property (nonatomic) NSArray *putDataArray;
@property (nonatomic) NSInteger putDataIndex;
@property (nonatomic, copy) NSString *commandString;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) NSNotification *processNextStringNotification;

@end


@implementation PutController
    
- (instancetype)initForServerController:(ServerController *)serverController
                           withFileName:(NSString *)fileName
                            withCommand:(NSString *)command;
{
    self = [super init];
    
    if (self) {
        self.waitMilliseconds = 0;
        self.serverController = serverController;
        self.putDataArray = nil;
        self.putDataIndex = 0;
        self.commandString = command;
        self.timer = nil;
        self.processNextStringNotification = [NSNotification notificationWithName:ProcessNextString object:self];

        // Setup a notifcation to enable asychronous recursive calling of processNextDataArrayString
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processNextDataArrayString)
                                                     name:ProcessNextString
                                                   object:self];
        
    } else {
        fprintf(stderr, "Unknown error.  Check input and try again.\n");
        return nil;
    }
    
    if (fileName) {
        NSData *putData = [NSData dataWithContentsOfFile:fileName];
        if (!putData) {
            fprintf(stderr, "Put file read error.  Check input.\n");
            return nil;
        } else {
            NSString *putDataString = [[NSString alloc] initWithData:putData encoding:NSUTF8StringEncoding];
            self.putDataArray = [putDataString componentsSeparatedByString:@"\n"];
        }
    }
        
    return self;
}
    
- (void)start
{
    // Setup events that drive actions
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processNextStringNotification)
                                                 name:StreamsReadyNotificationString
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(attemptRecoveryFromStreamError)
                                                 name:StreamErrorNotificationString
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(exit)
                                                 name:StreamClosedNotificationString
                                               object:nil];
    
    // Open the streams and start the process
    [self.serverController openStreams];
    
    [[NSNotificationQueue defaultQueue] enqueueNotification:self.processNextStringNotification
                                               postingStyle:NSPostNow
                                               coalesceMask:NSNotificationNoCoalescing
                                                   forModes:nil];
}

- (void)processNextDataArrayString
{
    if (self.putDataIndex < [self.putDataArray count]) {

        NSString *s = [self.putDataArray objectAtIndex:self.putDataIndex];
        self.putDataIndex++;
        
        // Pause for a pause command, then set a timer to process the next string
        if ([s hasPrefix:PausePrefix])
        {
            NSTimeInterval pauseInterval = .1;
            NSArray *components = [s componentsSeparatedByString:PausePrefix];
            if ([components count] > 1) {
                NSString *pauseValue = [components objectAtIndex:1];
                pauseInterval = (double)[pauseValue intValue]/1000;
            }
            
            self.timer = [NSTimer scheduledTimerWithTimeInterval:pauseInterval
                                                          target:self
                                                        selector:@selector(processNextDataArrayString)
                                                        userInfo:nil
                                                         repeats:NO];
            
        // Otherwise process the line, then send a message or set a timer to take the next step
        } else {
            if ((s) &&
                (![s hasPrefix:CommentPrefix])) // Unless of course it a comment
            {
                [self.serverController sendString:s];
            }
            
            // Send a notification to process the next string
            if (self.putDataIndex < [self.putDataArray count])
            {
                if (self.waitMilliseconds > 0) {
                    NSTimeInterval pauseInterval = (double)self.waitMilliseconds/1000;
                    self.timer = [NSTimer scheduledTimerWithTimeInterval:pauseInterval
                                                                  target:self
                                                                selector:@selector(processNextDataArrayString)
                                                                userInfo:nil
                                                                 repeats:NO];
                } else {
                    [[NSNotificationQueue defaultQueue] enqueueNotification:self.processNextStringNotification
                                                               postingStyle:NSPostWhenIdle
                                                               coalesceMask:NSNotificationNoCoalescing
                                                                   forModes:nil];
                }
                
            // Unless it was the end of the array, then move on to processing the command string
            } else {
                [self processCommandString];
            }
        }
        
    } else {
        // This is an unusual case of stepping-off the end of the Data Array (the last line was probably a pause command),
        // so move on to processing the command string
        [self processCommandString];
    }
}

- (void)processCommandString
{
    [self.serverController sendString:self.commandString];
    
    // finish up with a timer
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(closeStreams)
                                                userInfo:nil
                                                 repeats:NO];
}

- (void)attemptRecoveryFromStreamError
{
    [self.serverController closeStreams];
    [self.serverController openStreams];
}

- (void)closeStreams
{
    [self.serverController closeStreams];
}

- (void)exit
{
    CFRunLoopStop(CFRunLoopGetCurrent());
}

@end
