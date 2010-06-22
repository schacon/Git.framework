//
//  GITHttpHelper.m
//  Git
//
//  Created by Scott Chacon on 4/11/10.
//  Copyright 2010 Geoff Garside. All rights reserved.
//

#import "GITHttpHelper.h"
#import "GITRef.h"
#import "GITCommit.h"
#import "GITObjectHash.h"
#import "GITTree.h"
#import "GITTreeItem.h"

@implementation GITHttpHelper

@synthesize repo;
@synthesize refDict;

- (id)initWithRepo: (GITRepo *)theRepo {
    if ( ![super init] )
        return nil;
	
    self.repo = theRepo;
	
    return self;
}

// For handling the /info/refs call

- (NSData *)refAdvertisement:(NSString *)gitService {
	NSArray *refs = [self.repo allRefs];

	NSMutableData *outdata = [[NSMutableData new] autorelease];
	NSString *serviceLine = [NSString stringWithFormat:@"# service=%@\n", gitService];

	[outdata appendData:[self packetData:serviceLine]];
	[outdata appendData:[@"0000" dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSString *cap = @"include_tag multi_ack_detailed";
	NSLog(@"testing");
	
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

// for handling the /upload-pack RPC call
//
// this takes a string of want/haves from the client
// and returns a filehandle containing either another
// series of want/haves or the actual packfile data
//
// - using a filehandle here so I don't have to buffer 
//   the whole packfile response in memory

- (NSFileHandle *)uploadPack:(NSString *)wantHaves {
	NSLog(@"upload pack file");
	NSLog(@"wantHaves: \n%@", wantHaves);

	NSString *thisLine, *cmd, *sha;
	NSArray *values;
	GITObjectHash *shaHash;

	refDict = [[NSMutableDictionary alloc] init];
	
	//NSMutableArray *needRefs = [[NSMutableArray alloc] init];

	NSArray *lines = [wantHaves componentsSeparatedByString:@"\n"];
	NSEnumerator *e    = [lines objectEnumerator];
	while ( (thisLine = [e nextObject]) ) {	
		NSLog(@"processing line: %@", thisLine);
		
		if (![thisLine isEqualToString:@""] &&
			![thisLine isEqualToString:@"00000009done"]) {
			values = [thisLine componentsSeparatedByString:@" "];
			cmd	= [[values objectAtIndex: 0] substringFromIndex:4];
			sha	= [values objectAtIndex: 1];
			if([cmd isEqualToString:@"have"]) {
				[refDict setObject:@"have" forKey:sha];
			}
			if([cmd isEqualToString:@"want"]) {
				NSLog(@"haveFU: %@", sha);
				shaHash = [GITObjectHash objectHashWithString:sha];
				[self gatherObjectShasFromCommit:shaHash];
			}
		}
		NSLog(@"done with loop");
	}
	
	NSLog(@"done");
	NSLog(@"reflist: %@", refDict);
	// [self sendPackData];
	return nil;
}

- (void) gatherObjectShasFromCommit:(GITObjectHash *)shaHash 
{
	GITObjectHash *parentSha;

	NSLog(@"before");
	GITObject *commit = [repo objectWithSha1:shaHash error:NULL];
	NSLog(@"after: %@", commit);
	NSLog(@"type: %d", [commit type]);
	[refDict setObject:@"_commit" forKey:[shaHash unpackedString]];

	// add the tree objects

	if ([commit type] == GITObjectTypeTag) {
		commit = [commit target];
		NSLog(@"after: %@", commit);
		NSLog(@"type: %d", [commit type]);
	}
	
	if ([commit type] == GITObjectTypeCommit) {
		NSLog(@"gather trees");
		[self gatherObjectShasFromTree:[commit treeSha1]];
		NSLog(@"trees gathered");

		NSArray *parents = [commit parentShas];
		//GITObjectHash *pHash;
		
		NSEnumerator *e = [parents objectEnumerator];
		while ( (parentSha = [e nextObject]) ) {
			NSLog(@"parent sha:%@", parentSha);
			// TODO : check that refDict does not have this
			//pHash = [GITObjectHash objectHashWithString:parentSha];
			if (![refDict valueForKey:[parentSha unpackedString]]) {
				[self gatherObjectShasFromCommit:parentSha];
			}
		}
	}
}

- (void) gatherObjectShasFromTree:(GITObjectHash *)shaHash
{
	NSLog(@"treeHash:%@", shaHash);
	NSLog(@"treeSha:%@", [shaHash unpackedString]);
	GITTree *tree = [repo objectWithSha1:shaHash error:NULL];
	NSLog(@"tree:%@", tree);
	[refDict setObject:@"/" forKey:[shaHash unpackedString]];

	NSEnumerator *e = [[tree items] objectEnumerator];
	GITTreeItem *item;
    NSString  *name;        //!< Name of the file or directory
    GITObjectHash *sha1; 
	GITTreeItemMode mode;   //!< File/directory mode of the item
	while ( (item = [e nextObject]) ) {
		mode = [item mode];
		name = [item name];
		sha1  = [item sha1];
		[refDict setObject:name forKey:[sha1 unpackedString]];
		if (mode == GITTreeItemModeDir) {
			// TODO : check that refDict does not have this
			[self gatherObjectShasFromTree:sha1];
		}
	}
}



// for handling the /receive-pack RPC call
//
// this takes a refs+packfile file handle that was POSTed
// by the Git client and processes it, returning the refs
// that were updated as an NSData object

- (NSData *)receivePack:(NSFileHandle *)packfile {
	return nil;
}


// DATA MANIPULATION METHODS //

// prepends the packet-line data (4 leading bytes representing the 
// length of data that follows) to a given string and returns a new
// string

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
		
	NSData *data=[[[NSData alloc] initWithBytes:buffer length:4] autorelease];
	NSString *lenStr = [[NSString alloc] 
						initWithData:data
						encoding:NSUTF8StringEncoding];
	
	return [NSString stringWithFormat:@"%@%@", lenStr, info];
}

// takes a string, prepends the packet-line data and returns a NSData object

- (NSData*) packetData:(NSString*) info
{
	return [[self prependPacketLine:info] dataUsingEncoding:NSUTF8StringEncoding];
}


@end
