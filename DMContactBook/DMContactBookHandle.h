//
//  DMContactBookHandle.h
//  DMContactBookDemo
//
//  Created by 李二狗 on 2018/7/11.
//  Copyright © 2018年 李二狗. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#ifdef __IPHONE_9_0
#import <Contacts/Contacts.h>
#endif
#import <AddressBook/AddressBook.h>


#import "DMContactBookPersonModel.h"

#define DMContactBook_IOS9_LATER ([[UIDevice currentDevice] systemVersion].floatValue > 9.0 ? YES : NO )

/** 0.一个联系人模型的相关信息 方便获取显示到UI **/
typedef void(^DMContactBookPersonModelBlock)(DMContactBookPersonModel *model);

/** 1.一个联系人相关的字典数据 方便获取转JSON上传 **/
typedef void(^DMContactBookPersonDictBlock)(NSMutableDictionary *dict);

/** 授权失败的Block*/
typedef void(^AuthorizationFailure)(void);


@interface DMContactBookHandle : NSObject

/**
 单例

 */
+ (instancetype)shareInstance;


/**
 请求用户通讯录授权
 
 @param successOrFail 授权成功的回调
 */
- (void)requestAuthorizationWithSuccessBlock:(void (^)(BOOL result))successOrFail;


/**
 *  0.返回每个联系人的模型-----是模型方便显示UI
 *
 *  @param personModel 单个联系人模型
 *  @param failure     授权失败的Block
 */
- (void)getAddressBookDataSource:(DMContactBookPersonModelBlock)personModel authorizationFailure:(AuthorizationFailure)failure;

/**
 *  1.返回每个联系人的字典-----是字典类型方便转换上传通讯录到SERVER
 *
 *  @param personDict 单个联系人字典
 *  @param failure     授权失败的Block
 */
- (void)getDictAddressBookDataSource:(DMContactBookPersonDictBlock)personDict authorizationFailure:(AuthorizationFailure)failure;

+ (BOOL)dm_isBlankString:(NSString *)string;

@end
