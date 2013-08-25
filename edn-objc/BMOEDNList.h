//
//  BMOEDNConsCell.h
//  edn-objc
//
//  Created by Ben Mosher on 8/25/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMOEDNConsCell : NSObject

@property (strong, nonatomic) id first;
@property (strong, nonatomic) id rest;

@end

@interface BMOEDNList : NSObject

@property (strong, nonatomic) BMOEDNConsCell *head;

@end
