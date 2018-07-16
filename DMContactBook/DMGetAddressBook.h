//
//  DMGetAddressBook.h
//  DMContactBookDemo
//
//  Created by 李二狗 on 2018/7/11.
//  Copyright © 2018年 李二狗. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DMContactBookPersonModel.h"
#import "DMContactBookHandle.h"

/**
 *  获取原始顺序的所有联系人的Block-字典
 */
typedef void(^ContactBookArrayBlock)(NSArray<NSDictionary *> *addressBookArray);

/**
 *  获取原始顺序的所有联系人的Block
 */
typedef void(^AddressBookArrayBlock)(NSArray<DMContactBookPersonModel *> *addressBookArray);

/**
 *  获取按A~Z顺序排列的所有联系人的Block
 *
 *  @param addressBookDict 装有所有联系人的字典->每个字典key对应装有多个联系人模型的数组->每个模型里面包含着用户的相关信息.
 *  @param nameKeys   联系人姓名的大写首字母的数组
 */
typedef void(^AddressBookDictBlock)(NSDictionary<NSString *,NSArray *> *addressBookDict,NSArray *nameKeys);

@interface DMGetAddressBook : NSObject


+ (void)getAllAddressBookDataViaJSON:(void (^)(NSString *json))returnBlock;
/**
 *  请求用户是否授权APP访问通讯录的权限,建议在APPDeletegate.m中的didFinishLaunchingWithOptions方法中调用
 */

/**
 *  获取原始顺序排列的所有联系人字典(以后便于上传数据库用)
 *
 *  @param contactBookArray 装着原始顺序的联系人字典Block回调
 */
+ (void)getOriginalDictAddressBook:(ContactBookArrayBlock)contactBookArray authorizationFailure:(AuthorizationFailure)failure;


/**
 *  获取原始顺序排列的所有联系人模型（便于比较通讯录变化）
 *
 *  @param addressBookArray 装着原始顺序的联系人字典Block回调
 */
+ (void)getOriginalAddressBook:(AddressBookArrayBlock)addressBookArray authorizationFailure:(AuthorizationFailure)failure;


/**
 *  获取按A~Z顺序排列的所有联系人模型（便于显示UI）
 *
 *  @param addressBookInfo 装着A~Z排序的联系人字典Block回调
 *  @param failure         授权失败的Block
 */
+ (void)getOrderAddressBook:(AddressBookDictBlock)addressBookInfo authorizationFailure:(AuthorizationFailure)failure;

@end
