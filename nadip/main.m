//
//  main.m
//  nadip
//
//  Created by Pete Maiser on 2/11/18.
//  Copyright © 2018 Pete Maiser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerController.h"
#import "LogHandler.h"
#import "SettingsHandler.h"
#import "PutController.h"


int main(int argc, char * argv[]) {
    @autoreleasepool {
        
        ///// Get the Options /////
        
        NSString *logFileName = nil;
        NSString *putFileName = nil;
        NSString *settingsFileName = nil;
        NSInteger waitMilliseconds = 0;
        
        int c;
        while ((c = getopt (argc, argv, "l:p:s:w:")) != -1) {
            switch (c)
            {
                case 'l':
                    logFileName = [NSString stringWithFormat:@"%s", optarg];
                    break;
                case 'p':
                    putFileName = [NSString stringWithFormat:@"%s", optarg];
                    break;
                case 's':
                    settingsFileName = [NSString stringWithFormat:@"%s", optarg];
                    break;
                case 'w':
                    waitMilliseconds = [[NSString stringWithFormat:@"%s", optarg] integerValue];
                    break;
                case '?':
                    // Unknown option received
                    fprintf(stderr, "Usage:  nadip  [-l log_file] [-p put_file] [-s settings_file] [-w milliseconds] IP_address IP_port [put_command_string]\n");
                    return 1;
                default:
                    abort ();
                    
            }
            // All options require an argument.  Check that we aren't taking the next option as an argument on the last option.
            if (optarg[0] == '-') {
                fprintf(stderr, "Usage:  nadip  [-l log_file] [-p put_file] [-s settings_file] [-w milliseconds] IP_address IP_port [put_command_string]\n");
                return 1;
            }
        }
        
        
        ///// Get the Arguments /////
        
        if ( (optind != (argc - 2)) &&
             (optind != (argc - 3)) )
        {
            fprintf(stderr, "nadip  [-l log_file] [-p put_file] [-s settings_file] [-w milliseconds] IP_address IP_port [put_command_string]\n");
            return 1;
        }
        
        NSString *serverIPArg = [NSString stringWithFormat:@"%s", argv[optind]];
        NSString *serverPortArg = [NSString stringWithFormat:@"%s", argv[optind + 1]];
        NSString *commandArg = nil;
        
        if (optind == (argc - 3)) {
            commandArg = [NSString stringWithFormat:@"%s", argv[optind + 2]];
        }
        
        // Check that we have input to work on
        if (!putFileName && !commandArg) {
            fprintf(stderr, "Usage:  nadip  [-l log_file] [-p put_file] [-s settings_file] [-w milliseconds] IP_address IP_port [put_command_string]\n");
            fprintf(stderr, "A put_file OR a put_command_string must be supplied to nadip, or there is nothing for it to do. Loser.\n");
            return 1;
        }

        
        ///// Initiatilize the Handlers and Controllers /////

        ServerController *serverController = nil;
        LogHandler *logHandler = nil;
        SettingsHandler *settingsHandler = nil;
        PutController *putController = nil;

        serverController = [[ServerController alloc] initWithIPAddress:serverIPArg port:[serverPortArg intValue] lineTerminationString:@"\r"];
        if (serverController)
        {
            serverController.nameShort = serverIPArg;
            serverController.stringFragmentProcessingType = stringFragmentProcessingMended;
            if (logFileName) {
                logHandler = [[LogHandler alloc] initForServerController:serverController withFileName:logFileName];
            }
            if (settingsFileName) {
                settingsHandler = [[SettingsHandler alloc] initForServerController:serverController withFileName:settingsFileName];
                
                // Set some things for the settings handler to ignore, such as "Model"
                [settingsHandler.ignoreSet addObjectsFromArray:@[@"Main.Model", @"Main.Serial", @"Main.Version"]];
            }
            putController = [[PutController alloc] initForServerController:serverController withFileName:putFileName withCommand:commandArg];
        }
        
        
        ///// Execute the Process /////
        
        if (putController)
        {
            putController.waitMilliseconds = waitMilliseconds;
            
            // Provide some user feedback
            fprintf(stdout, "\n");
            fprintf(stdout, "Starting nadip...\n");
            if (logFileName){
                fprintf(stdout, "Log File requested with file name '%s'\n", [logFileName UTF8String]);
            }
            if (putFileName) {
                fprintf(stdout, "Put File requested with file name '%s'\n", [putFileName UTF8String]);
            }
            if (settingsFileName){
                fprintf(stdout, "Settings File requested with file name '%s'\n", [settingsFileName UTF8String]);
            }
            if (waitMilliseconds > 0) {
                fprintf(stdout, "Wait feature requested with %ld milliseconds\n", waitMilliseconds);
            }
                
            fprintf(stdout, "IP: %s\n", [serverIPArg UTF8String]);
            fprintf(stdout, "Port: %s\n", [serverPortArg UTF8String]);
            if (commandArg) {
                fprintf(stdout, "Command: %s\n", [commandArg UTF8String]);
            }
            fprintf(stdout, "\n");
            
            // Start the main Controller
            [putController start];
            
            // Start the Run Loop so the put controller can do its thing
            CFRunLoopRun();
            
            // Complete the Process
            fprintf(stdout, "Finished running nadip.\n");
            fprintf(stdout, "\n");
            
        } else {
            // A put controller was not established
            fprintf(stderr, "Usage:  nadip  [-l log_file] [-p put_file] [-s settings_file] [-w milliseconds] IP_address IP_port [put_command_string]\n");
            return 1;
        }
        
    }
    return 0;
}
