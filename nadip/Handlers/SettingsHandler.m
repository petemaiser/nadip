//
//  SettingsHandler.m
//  nadip
//
//  Created by Pete Maiser on 2/11/18.
//  Copyright © 2018 Pete Maiser. All rights reserved.
//

#import "SettingsHandler.h"


@implementation SettingsHandler

- (instancetype)initForServerController:(ServerController *)serverController
                           withFileName:(NSString *)fileName
{
    self = [super initForServerController:serverController withFileName:fileName];
    
    if (self) {
        NSAssert(fileName, @"SettingsHandler initialized with a NULL filename");
        NSAssert(![fileName isEqualToString:@""], @"SettingsHandler initialized with a a blank filename");
    }
    
    // Start Settings
    [self writeDefaults];
    
    return self;
}

- (void)writeDefaults
{
    // Write some default stuff to the file
    [self writeString:@"#######################################################"];
    [self writeString:@"#####       nadip settings file (put file)        #####"];
    [self writeString:@"#######################################################"];
    [self writeString:@"#"];
    [self writeString:@"##### Turn off Zones first #####"];
    [self writeString:@"Main.Power=Off"];
    [self writeString:@"Zone2.Power=Off"];
    [self writeString:@"Zone3.Power=Off"];
    [self writeString:@"Zone4.Power=Off"];
    [super writeString:@"#!p750"];
    [self writeString:@"##### Generated Settings #####"];
    
    // Since we just wrote some default above -- add those responses to the "ignore set"
    if (self.ignoreSet == nil) {
        self.ignoreSet = [[NSMutableSet alloc] init];
    }
    [self.ignoreSet addObject:@"Main.Power"];
    [self.ignoreSet addObject:@"Zone2.Power"];
    [self.ignoreSet addObject:@"Zone3.Power"];
    [self.ignoreSet addObject:@"Zone4.Power"];
}

@end
