//
//  Queue.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 11/7/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "Queue.h"

// a linked list of objects
@interface QueueNode : NSObject
@property(strong, nonatomic) id item;
@property(strong, nonatomic) QueueNode * next;
+(QueueNode *) nodeWithItem:(id)itm;
+(QueueNode *) nodeWithItem:(id)itm andNext:(QueueNode*)nxt;
@end

@implementation QueueNode
+(QueueNode *) nodeWithItem:(id)itm{
    return [QueueNode nodeWithItem:itm andNext:nil];
}
+(QueueNode *) nodeWithItem:(id)itm andNext:(QueueNode*)nxt{
    QueueNode * node = [[QueueNode alloc] init];
    node.item = itm;
    node.next = nxt;
    return node;
}
@end

// a wrapper around a linked list of objects
@interface Queue ()
{
    QueueNode * head;
    QueueNode * tail;
}
@end

@implementation Queue
-(id) init{
    self = [super init];
    if(self != nil)
    {
        head = nil;
        tail = nil;
    }
    return self;
}
-(BOOL) isEmpty{
    return head == nil;
}
-(id) top{
    if(head != nil)
        return head.item;
    else
        return nil;
}
-(void) pull{
    if(head != nil)
    {
        head = head.next;
        if(head == nil)
            tail = nil;
    }
}
-(void) push:(id)item{
    if(head != nil)
    {
        tail.next = [QueueNode nodeWithItem:item];
        tail = tail.next;
    }
    else
    {
        head = [QueueNode nodeWithItem:item];
        tail = head;
    }
}
@end
