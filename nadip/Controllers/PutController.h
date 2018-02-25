//
//  PutController.h
//  nadip
//
//  Created by Pete Maiser on 2/11/18.
//  Copyright © 2018 Pete Maiser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Controller.h"
@class ServerController;

@interface PutController : Controller

@property (nonatomic) NSInteger waitMilliseconds;

- (instancetype)initForServerController:(ServerController *)serverController
                           withFileName:(NSString *)fileName
                            withCommand:(NSString *)command;
- (void)start;

@end

#define PausePrefix @"#!p"
#define CommentPrefix @"#"
#define ProcessNextString @"ProcessNextString"
