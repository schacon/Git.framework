//
//  GITHttpHelper.h
//  Git
//
//  Created by Scott Chacon on 4/11/10.
//  Copyright 2010 Geoff Garside. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GITRepo.h"

@interface GITHttpHelper : NSObject {
    GITRepo *repo;
}

@property (assign) GITRepo *repo;

- (id)initWithRepo: (GITRepo *)theRepo;

- (NSData *)refAdvertisement:(NSString *)gitService;

- (NSString*) prependPacketLine:(NSString*) info;
- (NSData*) packetData:(NSString*) info;

@end
