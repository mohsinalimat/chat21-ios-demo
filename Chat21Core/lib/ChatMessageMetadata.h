//
//  ChatMessageMetadata.h
//  chat21
//
//  Created by Andrea Sponziello on 10/04/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FIRDataSnapshot;

@interface ChatMessageMetadata : NSObject

@property (assign, nonatomic) NSInteger width;
@property (assign, nonatomic) NSInteger height;
@property (strong, nonatomic) NSString *url;

-(NSDictionary *)asDictionary;
+(ChatMessageMetadata *)fromSnapshotFactory:(FIRDataSnapshot *)snapshot;

@end
