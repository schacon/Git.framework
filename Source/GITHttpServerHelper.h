//
//  GITHttpServerHelper.h
//  Git
//
//  Created by Scott Chacon on 4/11/10.
//  Copyright 2010 Geoff Garside. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GITRepo.h"

// This file implements the Git functionality of the Smart HTTP
// Git protocol - specifically the non-HTTP stuff.  This makes
// it easier to build a server with whatever Obj-C server library
// you want.

@interface GITHttpServerHelper : NSObject {
    GITRepo *repo;
	NSMutableDictionary*	refDict;
}

@property (assign) GITRepo *repo;
@property(assign, readwrite) NSMutableDictionary *refDict;

- (id)initWithRepo: (GITRepo *)theRepo;

// These are the main methods that need to be called to 
// handle the Git functionality

- (NSData *)refAdvertisement:(NSString *)gitService;
- (NSFileHandle *)uploadPack:(NSString *)wantHaves;

- (void) gatherObjectShasFromCommit:(GITObjectHash *)shaHash; 
- (void) gatherObjectShasFromTree:(GITObjectHash *)shaHash;

- (NSData *)receivePack:(NSFileHandle *)packfile;

// These are mostly data-related methods that may eventually
// be refactored out somewhere that makes more sense.

- (NSString*) prependPacketLine:(NSString*) info;
- (NSData*) packetData:(NSString*) info;

@end
