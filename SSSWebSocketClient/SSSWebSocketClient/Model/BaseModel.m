//
//  BaseModel.m
//  SSSWebSocketClient
//
//  Created by sagles on 14-3-7.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#import "BaseModel.h"
#import <objc/runtime.h>

#ifdef DEBUG
static NSMutableDictionary *ivarDictionay = nil;
#endif

@implementation BaseModel

- (NSString *)description
{
    Class cls = [self class];
    NSString *className = NSStringFromClass(cls);
    if (ivarDictionay == nil)
    ivarDictionay = [[NSMutableDictionary alloc] init];
    
    if ([ivarDictionay objectForKey:className] == nil)
    {
        NSMutableArray *ivarArray = [[NSMutableArray alloc] init];
        
        unsigned int count = 0;
        do
        {
            Ivar *ivars = class_copyIvarList(cls, &count);
            for (uint i = 0; i < count; i++)
            {
                NSString *ivar = [[NSString alloc] initWithUTF8String:ivar_getName(ivars[i])];
                [ivarArray addObject:ivar];
            }
            free(ivars);
        }
        while ((cls = class_getSuperclass(cls))!= [BaseModel class]);
        
        [ivarDictionay setObject:ivarArray forKey:className];
    }
    
    NSArray *ivarArray = [ivarDictionay objectForKey:className];
    NSMutableDictionary *ivarDict = [[NSMutableDictionary alloc] initWithCapacity:ivarArray.count];
    for (NSString *ivar in ivarArray)
    {
        id value = [self valueForKey:ivar];
        [ivarDict setValue:(value ? value : [NSNull null]) forKey:ivar];
    }
    
    NSString *_description = [ivarDict description];
    return _description;
}

@end
