//
//  BMOEDNObject.h
//  edn-objc
//
//  Created by Ben Mosher on 8/29/13.
//  Copyright (c) 2013 Ben Mosher. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BMOEDNRepresentation <NSObject>

-(id)ednRepresentation;
+(instancetype) objectWithEDNRepresentation:(id)ednRepresentation;

@end
