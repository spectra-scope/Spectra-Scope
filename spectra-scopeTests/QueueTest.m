//
//  QueueTest.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 11/7/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "QueueTest.h"
#import "Queue.h"
@interface QueueTest ()
{
    Queue * q;
    NSArray * items;
}
@end
@implementation QueueTest
-(void) setUp{
    [super setUp];
    q = [[Queue alloc] init];
    items = @[@"a", @"b", @"c", @"d"];
}
-(void)testPush{
    if(![q isEmpty])
        STFail(@"queue not empty when ought to be");
    for(id obj in items)
    {
        [q push:obj];
        if([q isEmpty])
            STFail(@"queue empty when not ought to be");
    }
}
-(void)testPull{
    while(![q isEmpty])
    {
        id obj = [q top];
        if(![items containsObject:obj])
            STFail(@"queue contains garbage");
        [q pull];
    }
}
@end
