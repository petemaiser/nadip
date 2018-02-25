//
//  NSString+ResponseString.h
//  DTrol
//  nadip
//
//  Created by Pete Maiser on 2/23/17.
//  Updated by Pete Maiser on 2/24/18.
//

#import <Foundation/Foundation.h>

@interface NSString (ResponseString) // Category on NSString to enable easy processing of response strings 

// word processing
- (NSString *)first_word;
- (NSString *)second_word;

// for NAD devices that reply with ZONE.VAR.OPTIONALVAR=VALUE
- (NSString *)nad_prefix;       // ZONE Prefix - i.e. everything up to the first dot (ZONE)
- (NSString *)nad_variable;     // Total Variable - i.e. everything between the first dot and the equal sign
- (NSString *)nad_variable1;    // First Variable - i.e. everything between the first dot and the second dot (VAR)
- (NSString *)nad_variable2;    // Second Variable, if applicable - i.e. everything between the second dot and the equal sign (OPTIONALVAR)
- (NSString *)nad_response;     // The NAD response type - i.e. everything up to the equal sign
- (NSString *)nad_value;        // Response Value - i.e. everything after the equal sign (VALUE)

// comparisons
- (BOOL)isInSet:(NSSet *)set;   // Returns a Boolean value that indicates whether a given set of string contains a string
                                // equal to the receiver (uses isEqualToString:)

@end
