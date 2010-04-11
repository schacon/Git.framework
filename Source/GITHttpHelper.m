//
//  GITHttpHelper.m
//  Git
//
//  Created by Scott Chacon on 4/11/10.
//  Copyright 2010 Geoff Garside. All rights reserved.
//

#import "GITHttpHelper.h"
#import "GITRef.h"

@implementation GITHttpHelper

@synthesize repo;

- (id)initWithRepo: (GITRepo *)theRepo {
    if ( ![super init] )
        return nil;
	
    self.repo = theRepo;
	
    return self;
}

- (NSData *)refAdvertisement:(NSString *)gitService {
	NSArray *refs = [self.repo allRefs];

	NSMutableData *outdata = [[NSMutableData new] autorelease];
	NSString *serviceLine = [NSString stringWithFormat:@"# service=%@\n", gitService];

	[outdata appendData:[self packetData:serviceLine]];
	[outdata appendData:[@"0000" dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSString *cap = @"include_tag multi_ack_detailed";
	
	int count = 0;
	NSString *refLine;
	for ( GITRef *ref in refs ) {
		if(count == 0) {
			refLine = [NSString stringWithFormat:@"%@ %@\0%@\n", [ref targetName], [ref name], cap];
		} else {
			refLine = [NSString stringWithFormat:@"%@ %@\n", [ref targetName], [ref name]];
		}
		
		[outdata appendData:[self packetData:refLine]];

		count++;
    }
	
	if(count == 0) {
		[outdata appendData:[self packetData:@"0000000000000000000000000000000000000000 capabilities^{}\0include_tag multi_ack_detailed"]];
	}

	[outdata appendData:[@"0000" dataUsingEncoding:NSUTF8StringEncoding]];	
	return outdata;
}

#define hex(a) (hexchar[(a) & 15])
- (NSString*) prependPacketLine:(NSString*) info
{
	static char hexchar[] = "0123456789abcdef";
	uint8_t buffer[5];
	
	unsigned int length = [info length] + 4;
	
	buffer[0] = hex(length >> 12);
	buffer[1] = hex(length >> 8);
	buffer[2] = hex(length >> 4);
	buffer[3] = hex(length);
	
	NSLog(@"write len [%c %c %c %c]", buffer[0], buffer[1], buffer[2], buffer[3]);
	
	NSData *data=[[[NSData alloc] initWithBytes:buffer length:4] autorelease];
	NSString *lenStr = [[NSString alloc] 
						initWithData:data
						encoding:NSUTF8StringEncoding];
	
	return [NSString stringWithFormat:@"%@%@", lenStr, info];
}

- (NSData*) packetData:(NSString*) info
{
	return [[self prependPacketLine:info] dataUsingEncoding:NSUTF8StringEncoding];
}


@end
