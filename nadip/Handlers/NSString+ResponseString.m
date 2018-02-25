//
//  NSString+ResponseString.m
//  DTrol
//  nadip
//
//  Created by Pete Maiser on 2/23/17.
//  Updated by Pete Maiser on 2/24/18.
//

#import "NSString+ResponseString.h"

@implementation NSString (ResponseString)

- (NSString *)first_word
{
    NSString *s = nil;
    NSArray *components = [self componentsSeparatedByString:@" "];
    
    if ([components count] > 1) {
        s = [components objectAtIndex:0];
    }
    return s;
}

- (NSString *)second_word
{
    NSString *s = nil;
    NSArray *components = [self componentsSeparatedByString:@" "];
    
    if ([components count] > 1) {
        s = [components objectAtIndex:1];
    }
    return s;
}

- (NSString *)nad_prefix
{
    NSString *s = nil;
    NSArray *components = [self componentsSeparatedByString:@"."];
    
    if ([components count] > 1) {
        s = [components objectAtIndex:0];
    }
    return s;
}

- (NSString *)nad_variable
{
    
    NSString *s = nil;
    NSArray *components1 = [self componentsSeparatedByString:@"="];
    
    if ([components1 count] > 1) {
        NSArray *components2 = [[components1 objectAtIndex:0] componentsSeparatedByString:@"."];
        if ([components2 count] == 2) {
        s = [components2 objectAtIndex:1];
        } else if ([components2 count] == 3) {
            s = [NSString stringWithFormat:@"%@.%@", [components2 objectAtIndex:1], [components2 objectAtIndex:2]];
        }
    }
    return s;
}

- (NSString *)nad_variable1
{
    
    NSString *s = nil;
    NSArray *components1 = [self componentsSeparatedByString:@"="];
    
    if ([components1 count] > 1) {
        NSArray *components2 = [[components1 objectAtIndex:0]componentsSeparatedByString:@"."];
        if ([components2 count] >= 2) {
            s = [components2 objectAtIndex:1];
        }
    }
    return s;
}

- (NSString *)nad_variable2
{
    NSString *s = nil;
    NSArray *components1 = [self componentsSeparatedByString:@"="];
    
    if ([components1 count] > 1) {
        NSArray *components2 = [[components1 objectAtIndex:0] componentsSeparatedByString:@"."];
        if ([components2 count] == 3) {
            s = [components2 objectAtIndex:2];
        }
    }
    return s;
}

- (NSString *)nad_response
{
    NSString *s = nil;
    NSArray *responseStringComponents = [self componentsSeparatedByString:@"="];
    
    if ([responseStringComponents count] > 1) {
        s = [responseStringComponents objectAtIndex:0];
    }
    return s;
}

- (NSString *)nad_value
{
    NSString *s = nil;
    NSArray *responseStringComponents = [self componentsSeparatedByString:@"="];
    
    if ([responseStringComponents count] > 1) {
        s = [responseStringComponents objectAtIndex:1];
    }
    return s;
}

- (BOOL)isInSet:(NSSet *)set
{
    for (NSString *s in set) {
        if ([self isEqualToString:s]) {
            return YES;
        }
    }
    return NO;
}

@end
