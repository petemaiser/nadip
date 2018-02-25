//
//  Handler.h
//  nadip
//
//  Created by Pete Maiser on 2/11/18.
//  Copyright © 2018 Pete Maiser. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ServerController;

@interface Handler : NSObject

@property (nonatomic) ServerController *serverController;   // the server controller to observe and handle responses from
@property (nonatomic, copy) NSString *fileName;             // the file name into which responses should be written
@property (nonatomic) NSMutableSet *ignoreSet;                     // ignore NAD "responses" in this set -- i.e. do not "handle" them

- (instancetype)initForServerController:(ServerController *)serverController
                           withFileName:(NSString *)fileName;
- (void)writeString:(NSString *)str;

@end
