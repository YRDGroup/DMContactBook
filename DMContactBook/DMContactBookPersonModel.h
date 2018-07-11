//
//  DMContactBookPersonModel.h
//  DMContactBookDemo
//
//  Created by 李二狗 on 2018/7/11.
//  Copyright © 2018年 李二狗. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DMContactBookPersonModel : NSObject
/** 联系人姓名*/
@property (nonatomic, copy) NSString *name;

/** 只拿手机号11位判断 **/
@property (nonatomic, copy) NSString *phone;

@end
