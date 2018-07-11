//
//  DMGetAddressBook.m
//  DMContactBookDemo
//
//  Created by 李二狗 on 2018/7/11.
//  Copyright © 2018年 李二狗. All rights reserved.
//

#import "DMGetAddressBook.h"


#define START NSDate *startTime = [NSDate date]
#define END NSLog(@"Time: %f", -[startTime timeIntervalSinceNow])

@implementation DMGetAddressBook

+ (BOOL)requestAddressBookAuthorization
{
    __block BOOL block_result;
    [[DMContactBookHandle shareInstance] requestAuthorizationWithSuccessBlock:^(BOOL result) {
        if (result) {
              [DMGetAddressBook getOrderAddressBook:nil authorizationFailure:nil];
        }
        block_result = result;
    }];
    return block_result;
}

+ (void)getAllAddressBookDataViaJSON:(void (^)(NSString *json))returnBlock{
    BOOL result =  [self requestAddressBookAuthorization];
    //未授权或者授权失败
    NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:3];
    if (!result) {
        [resultDic setObject:@"-1" forKey:@"code"];
        [resultDic setObject:@"授权失败或未授权" forKey:@"msg"];
        [resultDic setObject:@[] forKey:@"dataArray"];
         [DMGetAddressBook handleJsonData:resultDic returnBlock:returnBlock];
    } else {
        [resultDic setObject:@"1" forKey:@"code"];
        [resultDic setObject:@"授权成功" forKey:@"msg"];
        [DMGetAddressBook getOriginalDictAddressBook:^(NSArray<NSDictionary *> *addressBookArray) {
            [resultDic setObject:addressBookArray forKey:@"dataArray"];
            [DMGetAddressBook handleJsonData:resultDic returnBlock:returnBlock];
        } authorizationFailure:^{
            [resultDic setObject:@[] forKey:@"dataArray"];
            [DMGetAddressBook handleJsonData:resultDic returnBlock:returnBlock];
        }];
    }
    
}

+ (void)handleJsonData:(NSDictionary *)resultDic returnBlock:(void (^)(NSString *json))returnBlock
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultDic options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"数据解析出错");
        returnBlock(nil);
    }
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    returnBlock(jsonString);
}

+ (void)initialize
{
    [self getOrderAddressBook:nil authorizationFailure:nil];
}


#pragma mark - 获取原始顺序所有联系人 字典

+(void)getOriginalDictAddressBook:(ContactBookArrayBlock)contactBookArray authorizationFailure:(AuthorizationFailure)failure
{
    // 将耗时操作放到子线程
    dispatch_queue_t queue = dispatch_queue_create("addressBook.array", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(queue, ^{
        
        NSMutableArray *array = [NSMutableArray array];
        
        [[DMContactBookHandle shareInstance] getDictAddressBookDataSource:^(NSMutableDictionary *dict) {
            [array addObject:dict];
        } authorizationFailure:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                failure ? failure() : nil;
            });
        }];
        
        // 将联系人数组回调到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            contactBookArray ? contactBookArray(array) : nil ;
        });
    });
}

#pragma mark - 获取原始顺序所有联系人 模型

+ (void)getOriginalAddressBook:(AddressBookArrayBlock)addressBookArray authorizationFailure:(AuthorizationFailure)failure
{
    // 将耗时操作放到子线程
    dispatch_queue_t queue = dispatch_queue_create("addressBook.array", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(queue, ^{
        
        NSMutableArray *array = [NSMutableArray array];
        [[DMContactBookHandle shareInstance] getAddressBookDataSource:^(DMContactBookPersonModel *model) {
            
            [array addObject:model];
            
        } authorizationFailure:^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                failure ? failure() : nil;
            });
        }];
        
        // 将联系人数组回调到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            addressBookArray ? addressBookArray(array) : nil ;
        });
    });
    
}

#pragma mark - 获取按A~Z顺序排列的所有联系人 模型

+ (void)getOrderAddressBook:(AddressBookDictBlock)addressBookInfo authorizationFailure:(AuthorizationFailure)failure
{
    
    // 将耗时操作放到子线程
    dispatch_queue_t queue = dispatch_queue_create("addressBook.infoDict", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(queue, ^{
        
        NSMutableDictionary *addressBookDict = [NSMutableDictionary dictionary];
        [[DMContactBookHandle shareInstance] getAddressBookDataSource:^(DMContactBookPersonModel *model) {
            //获取到姓名的大写首字母
            NSString *firstLetterString = [self getFirstLetterFromString:model.name];
            //如果该字母对应的联系人模型不为空,则将此联系人模型添加到此数组中
            if (addressBookDict[firstLetterString])
            {
                [addressBookDict[firstLetterString] addObject:model];
            }
            //没有出现过该首字母，则在字典中新增一组key-value
            else
            {
                //创建新发可变数组存储该首字母对应的联系人模型
                NSMutableArray *arrGroupNames = [NSMutableArray arrayWithObject:model];
                //将首字母-姓名数组作为key-value加入到字典中
                [addressBookDict setObject:arrGroupNames forKey:firstLetterString];
            }
        } authorizationFailure:^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                failure ? failure() : nil;
            });
        }];
        
        // 将addressBookDict字典中的所有Key值进行排序: A~Z
        NSArray *nameKeys = [[addressBookDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
        
        // 将 "#" 排列在 A~Z 的后面
        if ([nameKeys.firstObject isEqualToString:@"#"])
        {
            NSMutableArray *mutableNamekeys = [NSMutableArray arrayWithArray:nameKeys];
            [mutableNamekeys insertObject:nameKeys.firstObject atIndex:nameKeys.count];
            [mutableNamekeys removeObjectAtIndex:0];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                addressBookInfo ? addressBookInfo(addressBookDict,mutableNamekeys) : nil;
            });
            return;
        }
        
        // 将排序好的通讯录数据回调到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            addressBookInfo ? addressBookInfo(addressBookDict,nameKeys) : nil;
        });
        
    });
    
}


#pragma mark - 获取联系人姓名首字母(传入汉字字符串, 返回大写拼音首字母)
+ (NSString *)getFirstLetterFromString:(NSString *)aString
{
    //截获空字符串
    if ([DMContactBookHandle dm_isBlankString:aString]) {
        return @"#";
    }
    
    /**
     * **************************************** START ***************************************
     * 之前PPGetAddressBook对联系人排序时在中文转拼音这一部分非常耗时
     * 参考博主-庞海礁先生的一文:iOS开发中如何更快的实现汉字转拼音 http://www.olinone.com/?p=131
     * 使PPGetAddressBook对联系人排序的性能提升 3~6倍, 非常感谢!
     */
    NSMutableString *mutableString = [NSMutableString stringWithString:aString];
    CFStringTransform((CFMutableStringRef)mutableString, NULL, kCFStringTransformToLatin, false);
    NSString *pinyinString = [mutableString stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]];
    /**
     *  *************************************** END ******************************************
     */
    
    // 将拼音首字母装换成大写
    NSString *strPinYin = [[self polyphoneStringHandle:aString pinyinString:pinyinString] uppercaseString];
    // 截取大写首字母
    NSString *firstString = [strPinYin substringToIndex:1];
    // 判断姓名首位是否为大写字母
    NSString * regexA = @"^[A-Z]$";
    NSPredicate *predA = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexA];
    // 获取并返回首字母
    return [predA evaluateWithObject:firstString] ? firstString : @"#";
    
}

/**
 多音字处理
 */
+ (NSString *)polyphoneStringHandle:(NSString *)aString pinyinString:(NSString *)pinyinString
{
    if ([aString hasPrefix:@"长"]) { return @"chang";}
    if ([aString hasPrefix:@"沈"]) { return @"shen"; }
    if ([aString hasPrefix:@"厦"]) { return @"xia";  }
    if ([aString hasPrefix:@"地"]) { return @"di";   }
    if ([aString hasPrefix:@"重"]) { return @"chong";}
    return pinyinString;
}
@end
