//
//  CityModel.m
//  GoEarn
//
//  Created by miaomiaokeji on 2016/11/3.
//  Copyright © 2016年 Beyondream. All rights reserved.
//

#import "CityModel.h"

@implementation CityModel

- (instancetype)init{
    if (self=[super init]) {
        [CityModel mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
            
            return @{@"ID" : @"id"};
            
        }];
    }
    
    return self;
    
}
@end
