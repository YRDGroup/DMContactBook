//
//  DMContactBookHandle.m
//  DMContactBookDemo
//
//  Created by 李二狗 on 2018/7/11.
//  Copyright © 2018年 李二狗. All rights reserved.
//

#import "DMContactBookHandle.h"
@interface DMContactBookHandle ()

#ifdef __IPHONE_9_0
/** iOS9之后的通讯录对象*/
@property (nonatomic, strong) CNContactStore *contactStore;
#endif

@end

@implementation DMContactBookHandle

+ (instancetype)shareInstance {
    static DMContactBookHandle * shareInstance = nil ;
    if (shareInstance == nil) {
        shareInstance = [[DMContactBookHandle alloc] init];
    }
    return (DMContactBookHandle *)shareInstance;
}



- (void)requestAuthorizationWithSuccessBlock:(void (^)(BOOL result))successOrFail
{

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
        // 1.判断是否授权成功,若授权成功直接return
    if ([CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized) \
    {
        successOrFail(YES);
        return;
    }
        // 2.创建通讯录
        //CNContactStore *store = [[CNContactStore alloc] init];
        // 3.授权
        [self.contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                NSLog(@"授权成功");
                successOrFail(YES);
            }else{
                NSLog(@"授权失败");
                successOrFail(NO);
            }
        }];
#else
        // 1.获取授权的状态
        ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
        // 2.判断授权状态,如果是未决定状态,才需要请求
        if (status == kABAuthorizationStatusNotDetermined) {
            // 3.创建通讯录进行授权
            ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                if (granted) {
                    NSLog(@"授权成功");
                     successOrFail(YES);
                } else {
                    NSLog(@"授权失败");
                     successOrFail(NO);
                }
                
            });
        }
#endif
    
}

#pragma mark - 模型模型模型模型模型模型模型模型
/**
 *  0.返回每个联系人的模型-----是模型方便显示UI
 *
 *  @param personModel 单个联系人模型
 *  @param failure     授权失败的Block
 */
- (void)getAddressBookDataSource:(DMContactBookPersonModelBlock)personModel authorizationFailure:(AuthorizationFailure)failure
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
        [self getDataSourceFrom_IOS9_Later:personModel authorizationFailure:failure];
#else
        [self getDataSourceFrom_IOS9_Ago:personModel authorizationFailure:failure];
#endif
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_9_0
// IOS9之前获取通讯录的方法
- (void)getDataSourceFrom_IOS9_Ago:(DMContactBookPersonModelBlock)personModel authorizationFailure:(AuthorizationFailure)failure
{
    // 1.获取授权状态
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    
    // 2.如果没有授权,先执行授权失败的block后return
    if (status != kABAuthorizationStatusAuthorized/** 已经授权*/)
    {
        failure ? failure() : nil;
        return;
    }
    
    // 3.创建通信录对象
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    //4.按照排序规则从通信录对象中请求所有的联系人,并按姓名属性中的姓(LastName)来排序
    ABRecordRef recordRef = ABAddressBookCopyDefaultSource(addressBook);
    CFArrayRef allPeopleArray = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, recordRef, kABPersonSortByLastName);
    
    // 5.遍历每个联系人的信息,并装入模型
    for(id personInfo in (__bridge NSArray *)allPeopleArray)
    {
        DMContactBookPersonModel *model = [DMContactBookPersonModel new];
        
        // 5.1获取到联系人
        ABRecordRef person = (__bridge ABRecordRef)(personInfo);
        
        // 5.2获取全名
        NSString *name = (__bridge_transfer NSString *)ABRecordCopyCompositeName(person);
        model.name = name.length > 0 ? name : @"  ";
        
        // 5.4获取每个人所有的电话号码
        ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
        
        CFIndex phoneCount = ABMultiValueGetCount(phones);
        for (CFIndex i = 0; i < phoneCount; i++)
        {
            // 号码
            NSString *phoneValue = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, i);
            NSString *mobile = [self removeSpecialSubString:phoneValue];
            
            //脉典app只需要手机号，所以只拿第一个属于手机号的号码
            if (mobile.length == 11) {
                model.phone = mobile;
            }else{
                model.phone = @"";
            }
        }
        // 5.5将联系人模型回调出去
        personModel ? personModel(model) : nil;
        
        CFRelease(phones);
    }
    
    // 释放不再使用的对象
    CFRelease(allPeopleArray);
    CFRelease(recordRef);
    CFRelease(addressBook);
}

#else

// IOS9之后获取通讯录的方法
- (void)getDataSourceFrom_IOS9_Later:(DMContactBookPersonModelBlock)personModel authorizationFailure:(AuthorizationFailure)failure
{
    // 1.获取授权状态
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    // 2.如果没有授权,先执行授权失败的block后return
    if (status != CNAuthorizationStatusAuthorized)
    {
        failure ? failure() : nil;
        return;
    }
    // 3.获取联系人
    // 3.1.创建联系人仓库
    //CNContactStore *store = [[CNContactStore alloc] init];
    
    // 3.2.创建联系人的请求对象
    // keys决定能获取联系人哪些信息,例:姓名,电话,头像等
    NSArray *fetchKeys = @[[CNContactFormatter descriptorForRequiredKeysForStyle:CNContactFormatterStyleFullName],CNContactPhoneNumbersKey,CNContactThumbnailImageDataKey];
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:fetchKeys];
    
    // 3.3.请求联系人
    [self.contactStore enumerateContactsWithFetchRequest:request error:nil usingBlock:^(CNContact * _Nonnull contact,BOOL * _Nonnull stop) {
        
        // 获取联系人全名
        NSString *name = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];
        
        // 创建联系人模型
        DMContactBookPersonModel *model = [DMContactBookPersonModel new];
        model.name = name.length > 0 ? name : @"  " ;
        
        // 获取一个人的所有电话号码
        NSArray *phones = contact.phoneNumbers;
        
        for (CNLabeledValue *labelValue in phones)
        {
            CNPhoneNumber *phoneNumber = labelValue.value;
            NSString *mobile = [self removeSpecialSubString:phoneNumber.stringValue];
            //脉典app只需要手机号，所以只拿第一个属于手机号的号码
            if (mobile.length == 11) {
                model.phone = mobile;
            }else{
                model.phone = @"";
            }
        }
        
        //将联系人模型回调出去
        personModel ? personModel(model) : nil;
    }];

    
}
#endif


#pragma mark - 字典字典字典字典字典字典字典字典

/**
 *  1.返回每个联系人的字典-----是字典类型方便转换上传通讯录到SERVER
 *
 *  @param personModel 单个联系人字典
 *  @param failure     授权失败的Block
 */
- (void)getDictAddressBookDataSource:(DMContactBookPersonDictBlock)personDict authorizationFailure:(AuthorizationFailure)failure
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
    [self getDictDataSourceFrom_IOS9_Later:personDict authorizationFailure:failure];
#else
    [self getDictDataSourceFrom_IOS9_Ago:personDict authorizationFailure:failure];
#endif
}


#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_9_0
// IOS9之前获取通讯录的方法
- (void)getDictDataSourceFrom_IOS9_Ago:(DMContactBookPersonDictBlock)personDict authorizationFailure:(AuthorizationFailure)failure
{
    // 1.获取授权状态
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    
    // 2.如果没有授权,先执行授权失败的block后return
    if (status != kABAuthorizationStatusAuthorized/** 已经授权*/)
    {
        failure ? failure() : nil;
        return;
    }
    
    // 3.创建通信录对象
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    //4.按照排序规则从通信录对象中请求所有的联系人,并按姓名属性中的姓(LastName)来排序
    ABRecordRef recordRef = ABAddressBookCopyDefaultSource(addressBook);
    CFArrayRef allPeopleArray = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, recordRef, kABPersonSortByLastName);
    
    // 5.遍历每个联系人的信息,并装入字典
    for(id personInfo in (__bridge NSArray *)allPeopleArray)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        // 5.1获取到联系人
        ABRecordRef person = (__bridge ABRecordRef)(personInfo);
        
        // 5.2获取全名
        NSString *name = (__bridge_transfer NSString *)ABRecordCopyCompositeName(person);
        
        [dict setValue:(name.length > 0 ? name : @"Z未命名") forKey:@"remark"];
        
        // 5.4获取每个人所有的电话号码
        ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
        CFIndex phoneCount = ABMultiValueGetCount(phones);
        for (CFIndex i = 0; i < phoneCount; i++)
        {
            // 号码
            NSString *phoneValue = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, i);
            NSString *mobile = [self removeSpecialSubString:phoneValue];
            
            //脉典app只需要手机号，所以只拿第一个属于手机号的号码
            if (mobile.length == 11) {
                [dict setValue:mobile forKey:@"phone"];
            }
        }
        
        if (![DMContactBookHandle dm_isBlankString:dict[@"phone"]]) {
            // 5.5将联系人模型回调出去
            personDict ? personDict(dict) : nil;
        }
        
        CFRelease(phones);
    }
    
    // 释放不再使用的对象
    CFRelease(allPeopleArray);
    CFRelease(recordRef);
    CFRelease(addressBook);
}

#else
// IOS9之后获取通讯录的方法
- (void)getDictDataSourceFrom_IOS9_Later:(DMContactBookPersonDictBlock)personDict authorizationFailure:(AuthorizationFailure)failure
{
    // 1.获取授权状态
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    // 2.如果没有授权,先执行授权失败的block后return
    if (status != CNAuthorizationStatusAuthorized)
    {
        failure ? failure() : nil;
        return;
    }
    // 3.获取联系人
    // 3.1.创建联系人仓库
    //CNContactStore *store = [[CNContactStore alloc] init];
    
    // 3.2.创建联系人的请求对象
    // keys决定能获取联系人哪些信息,例:姓名,电话,头像等
    NSArray *fetchKeys = @[[CNContactFormatter descriptorForRequiredKeysForStyle:CNContactFormatterStyleFullName],CNContactPhoneNumbersKey,CNContactThumbnailImageDataKey];
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:fetchKeys];
    
    // 3.3.请求联系人
    [self.contactStore enumerateContactsWithFetchRequest:request error:nil usingBlock:^(CNContact * _Nonnull contact,BOOL * _Nonnull stop) {
        
        // 创建联系人模型
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        // 获取联系人全名
        NSString *name = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];
        
        // 获取一个人的所有电话号码
        NSArray *phones = contact.phoneNumbers;
        
        for (CNLabeledValue *labelValue in phones)
        {
            CNPhoneNumber *phoneNumber = labelValue.value;
            NSString *mobile = [self removeSpecialSubString:phoneNumber.stringValue];
            //脉典app只需要手机号，所以只拿第一个属于手机号的号码
            if (mobile.length == 11) {
                [dict setValue:mobile forKey:@"phone"];
            }
        }
        
        //userId
        [dict setValue:(name.length > 0 ? name : @"Z未命名") forKey:@"remark"];
        
        if (![DMContactBookHandle dm_isBlankString:dict[@"phone"]]) {
            //将联系人模型回调出去
            personDict ? personDict(dict) : nil;
        }
    }];

    
}
#endif

+ (BOOL)dm_isBlankString:(NSString *)string{
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]==0) {
        return YES;
    }
    return NO;
}

#pragma mark - 私有模型/字典公共方法
//过滤指定字符串(可自定义添加自己过滤的字符串)
- (NSString *)removeSpecialSubString: (NSString *)string
{
    string = [string stringByReplacingOccurrencesOfString:@"+86" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"-" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"(" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@")" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    return string;
}

#pragma mark - lazy

#ifdef __IPHONE_9_0
- (CNContactStore *)contactStore
{
    if(!_contactStore)
    {
        _contactStore = [[CNContactStore alloc] init];
    }
    return _contactStore;
}
#endif
@end
