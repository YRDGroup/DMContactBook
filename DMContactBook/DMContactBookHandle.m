//
//  DMContactBookHandle.m
//  DMContactBookDemo
//
//  Created by 李二狗 on 2018/7/11.
//  Copyright © 2018年 李二狗. All rights reserved.
//

#import "DMContactBookHandle.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
#import "DMCNContactPickerViewController.h"
#else
#import "DMABPeoplePickerNavigationController.h"
#endif

#define kRootViewController [UIApplication sharedApplication].keyWindow.rootViewController


@interface DMContactBookHandle ()<UINavigationControllerDelegate,
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
CNContactPickerDelegate
#else
ABPeoplePickerNavigationControllerDelegate
#endif
>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
/** iOS9之后的通讯录对象*/
@property (nonatomic, strong) CNContactStore *contactStore;
#endif

@property (nonatomic, copy) DMUISingleContactsBlock singleBlock;

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
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (status == CNAuthorizationStatusAuthorized) \
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
              return;
        }else{
            NSLog(@"授权失败");
            successOrFail(NO);
              return;
        }
    }];
#else
        // 1.获取授权的状态
        ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    
        if (status == kABAuthorizationStatusAuthorized) {
            successOrFail(YES);
            return;
        }
        // 2.判断授权状态,如果是未决定状态,才需要请求
//        if (status == kABAuthorizationStatusNotDetermined) {
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
//        }
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
    NSArray *peopleArray = (__bridge NSArray *)allPeopleArray;
    NSMutableArray *dicArray = [NSMutableArray arrayWithCapacity:peopleArray.count];
    for(id personInfo in peopleArray)
    {
        // 5.1获取到联系人
        ABRecordRef person = (__bridge ABRecordRef)(personInfo);
        NSMutableArray *singlePeopleArray = [NSMutableArray array];
        // 5.4获取每个人所有的电话号码
        ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
        CFIndex phoneCount = ABMultiValueGetCount(phones);
        //获取全名
        NSString *fullName = (__bridge_transfer NSString *)ABRecordCopyCompositeName(person)?:@"Z未命名";
        //获取当前联系人的昵称
        NSString*nickyName=(__bridge NSString*)(ABRecordCopyValue(person, kABPersonNicknameProperty))?:@"Z未命名昵称";
        //获取当前联系人姓氏
        NSString*familyName=(__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty))?:@"Z未命名姓氏";
        //获取当前联系人的公司
        NSString*org=(__bridge NSString*)(ABRecordCopyValue(person, kABPersonOrganizationProperty))?:@"";
        //备注
        NSString*note=(__bridge NSString*)(ABRecordCopyValue(person, kABPersonNoteProperty))?:@"";
        if (phoneCount <= 0) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [dic setValue:fullName forKey:@"fullName"];
            [dic setValue:nickyName forKey:@"nickyName"];
            [dic setValue:familyName forKey:@"familyName"];
            [dic setValue:org forKey:@"org"];
            [dic setValue:note forKey:@"note"];
            [dic setValue:@"未知类型" forKey:@"type"];
            [dic setValue:@"无号码" forKey:@"number"];
            [singlePeopleArray addObject:dic];
        } else {
            for (CFIndex i = 0; i < phoneCount; i++)
            {
                 NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                //nickname
                
                // 号码
                NSString *phoneValue = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, i);
                NSString *number = [self removeSpecialSubString:phoneValue];
               NSString *type = (__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(phones, i);
                type = [self removeSpecialSubString:type];
                //脉典app只需要手机号，所以只拿第一个属于手机号的号码
                [dic setValue:fullName forKey:@"fullName"];
                [dic setValue:nickyName forKey:@"nickyName"];
                [dic setValue:familyName forKey:@"familyName"];
                [dic setValue:org forKey:@"org"];
                [dic setValue:note forKey:@"note"];
                [dic setValue:type forKey:@"type"];
                [dic setValue:number forKey:@"number"];
                
                 [singlePeopleArray addObject:dic];
            }
        }
        CFRelease(phones);
        [dicArray addObjectsFromArray:singlePeopleArray];
    }
    // 释放不再使用的对象
    CFRelease(allPeopleArray);
    CFRelease(recordRef);
    CFRelease(addressBook);
     personDict ? personDict(dicArray) : nil;
}

// IOS9之前获取通讯录的方法
- (void)getDataSourceFrom_IOS9_Ago:(DMContactBookPersonModelBlock)personModel authorizationFailure:(AuthorizationFailure)failure
{
    [self getDictAddressBookDataSource:^(NSArray<NSDictionary *> *dicArray) {
        NSMutableArray *models = [NSMutableArray arrayWithCapacity:dicArray.count];
        for (NSDictionary *dic in dicArray) {
            DMContactBookPersonModel *model = [DMContactBookPersonModel new];
            model.fullName = dic[@"fullName"];
            model.nickyName = dic[@"nickyName"];
            model.familyName = dic[@"familyName"];
            model.org = dic[@"org"];
            model.note = dic[@"note"];
            model.type = dic[@"type"];
            model.number = dic[@"number"];
            [models addObject:model];
        }
        personModel?personModel(models):nil;
    } authorizationFailure:failure];
}

#else

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
    NSArray *fetchKeys = @[[CNContactFormatter descriptorForRequiredKeysForStyle:CNContactFormatterStyleFullName],CNContactNicknameKey,CNContactFamilyNameKey,CNContactOrganizationNameKey,CNContactNoteKey,CNContactPhoneNumbersKey];
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:fetchKeys];
    
    // 3.3.请求联系人
    [self.contactStore enumerateContactsWithFetchRequest:request error:nil usingBlock:^(CNContact * _Nonnull contact,BOOL * _Nonnull stop) {
        
        // 创建联系人模型
        // 获取联系人全名
        NSString *fullName = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName]?:@"Z未命名";
        NSString *nickyName = contact.nickname?:@"Z未命名昵称";
        NSString *familyName = contact.familyName?:@"Z未命名姓氏";
        NSString *org = contact.organizationName?:@"";
        NSString *note = contact.note?:@"";
        // 获取一个人的所有电话号码
        NSArray *phones = contact.phoneNumbers;
        NSMutableArray *dicArray = [NSMutableArray arrayWithCapacity:phones.count];
        if (phones.count <= 0) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [dic setValue:fullName forKey:@"fullName"];
            [dic setValue:nickyName forKey:@"nickyName"];
             [dic setValue:familyName forKey:@"familyName"];
             [dic setValue:org forKey:@"org"];
             [dic setValue:note forKey:@"note"];
             [dic setValue:@"未知类型" forKey:@"type"];
             [dic setValue:@"无号码" forKey:@"number"];
            [dicArray addObject:dic];
        } else {
            for (CNLabeledValue *labelValue in phones)
            {
                CNPhoneNumber *phoneNumber = labelValue.value;
                NSString *type = labelValue.label?:@"未知类型";
                type = [self removeSpecialSubString:type];
                NSString *number = phoneNumber.stringValue?:@"无号码";
                number = [self removeSpecialSubString:number];
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                [dic setValue:fullName forKey:@"fullName"];
                [dic setValue:nickyName forKey:@"nickyName"];
                [dic setValue:familyName forKey:@"familyName"];
                [dic setValue:org forKey:@"org"];
                [dic setValue:note forKey:@"note"];
                [dic setValue:type forKey:@"type"];
                [dic setValue:number forKey:@"number"];
                [dicArray addObject:dic];
            }
        }
       personDict ? personDict(dicArray) : nil;
    }];
    
    
}

// IOS9之后获取通讯录的方法
- (void)getDataSourceFrom_IOS9_Later:(DMContactBookPersonModelBlock)personModel authorizationFailure:(AuthorizationFailure)failure
{
    
    [self getDictAddressBookDataSource:^(NSArray<NSDictionary *> *dicArray) {
        NSMutableArray *models = [NSMutableArray arrayWithCapacity:dicArray.count];
        for (NSDictionary *dic in dicArray) {
            DMContactBookPersonModel *model = [DMContactBookPersonModel new];
            model.fullName = dic[@"fullName"];
            model.nickyName = dic[@"nickyName"];
            model.familyName = dic[@"familyName"];
            model.org = dic[@"org"];
            model.note = dic[@"note"];
            model.type = dic[@"type"];
            model.number = dic[@"number"];
            [models addObject:model];
        }
        personModel?personModel(models):nil;
        
    } authorizationFailure:failure];
}
#endif


#pragma mark - 字典字典字典字典字典字典字典字典

/**
 *  1.返回每个联系人的字典-----是字典类型方便转换上传通讯录到SERVER
 *
 *  @param personDict 单个联系人字典
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
    string = [string stringByReplacingOccurrencesOfString:@"_" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"(" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@")" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"$" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"!" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"<" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@">" withString:@""];
    
    return string;
}

- (void)getSingleContactsHandler:(DMUISingleContactsBlock)singleBlock {

    self.singleBlock = singleBlock;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
    
        // 1.获取授权状态
        CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        // 2.如果没有授权,先执行授权失败的block后return
        if (status != CNAuthorizationStatusAuthorized)
        {
            NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:3];
            [resultDic setObject:@"-1" forKey:@"code"];
            [resultDic setObject:@"授权失败或未授权" forKey:@"msg"];
            singleBlock(nil,resultDic);
            return;
        }
    
        CNContactStore *contactStore = [[CNContactStore alloc] init];
        [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                DMCNContactPickerViewController *picker = [[DMCNContactPickerViewController alloc] init];
                picker.delegate = self;
                [kRootViewController presentViewController:picker animated:YES completion:^{}];
                
            }
            
        }];
#else
    
    // 1.获取授权的状态
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    // 2.如果没有授权,先执行授权失败的block后return
    if (status != kABAuthorizationStatusAuthorized/** 已经授权*/)
    {
        NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:3];
        [resultDic setObject:@"-1" forKey:@"code"];
        [resultDic setObject:@"授权失败或未授权" forKey:@"msg"];
        singleBlock(nil,resultDic);
        return;
    }
    DMABPeoplePickerNavigationController *peoplePicker = [[DMABPeoplePickerNavigationController alloc] init];
    peoplePicker.peoplePickerDelegate = self;
    [kRootViewController presentViewController:peoplePicker animated:YES completion:nil];
    
#endif
}



#pragma mark - lazy

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
- (CNContactStore *)contactStore
{
    if(!_contactStore)
    {
        _contactStore = [[CNContactStore alloc] init];
    }
    return _contactStore;
}

// 通讯录列表 - 点击某个联系人 - 详情页 - 点击一个号码, 返回
- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContactProperty:(CNContactProperty *)contactProperty {
    
    if ([contactProperty.key isEqualToString:@"phoneNumbers"]) {
        
        CNContact *contact = contactProperty.contact;
        // 创建联系人模型
        // 获取联系人全名
        NSString *fullName = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName]?:@"Z未命名";
        NSString *nickyName = contact.nickname?:@"Z未命名昵称";
        NSString *familyName = contact.familyName?:@"Z未命名姓氏";
        NSString *org = contact.organizationName?:@"";
        NSString *note = contact.note?:@"";
        NSString *type = contactProperty.label?:@"未知类型";
        type = [self removeSpecialSubString:type];
        NSString *number = [contactProperty.value stringValue]?:@"无号码";
        number = [self removeSpecialSubString:number];
        
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:fullName forKey:@"fullName"];
        [dic setValue:nickyName forKey:@"nickyName"];
        [dic setValue:familyName forKey:@"familyName"];
        [dic setValue:org forKey:@"org"];
        [dic setValue:note forKey:@"note"];
        [dic setValue:type forKey:@"type"];
        [dic setValue:number forKey:@"number"];
        DMContactBookPersonModel *model = [DMContactBookPersonModel new];
        model.fullName = dic[@"fullName"];
        model.nickyName = dic[@"nickyName"];
        model.familyName = dic[@"familyName"];
        model.org = dic[@"org"];
        model.note = dic[@"note"];
        model.type = dic[@"type"];
        model.number = dic[@"number"];
        
        if(self.singleBlock) {
            NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:3];
            [resultDic setObject:@"1" forKey:@"code"];
            [resultDic setObject:@"授权成功" forKey:@"msg"];
            [resultDic setObject:dic forKey:@"value"];
            self.singleBlock(model,resultDic);
        }
        
    } else {
        if (self.singleBlock) {
            NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:3];
            [resultDic setObject:@"-4" forKey:@"code"];
             [resultDic setObject:@"用户未选中号码" forKey:@"msg"];
            self.singleBlock(nil,resultDic);
        }
    }
    
    
}

- (void)contactPickerDidCancel:(CNContactPickerViewController *)picker {
    
    if (self.singleBlock) {
        NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:3];
        [resultDic setObject:@"-2" forKey:@"code"];
        [resultDic setObject:@"用户取消" forKey:@"msg"];
        self.singleBlock(nil,resultDic);
    }
    
}

#else

#pragma mark - ABPeoplePickerNavigationController delegate
// 在联系人详情页可直接发信息/打电话
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier{
    
    ABMultiValueRef valuesRef = ABRecordCopyValue(person, kABPersonPhoneProperty);
    CFIndex index = ABMultiValueGetIndexForIdentifier(valuesRef,identifier);
    
    if (index >= 0) {

        //获取全名
        NSString *fullName = (__bridge_transfer NSString *)ABRecordCopyCompositeName(person)?:@"Z未命名";
        //获取当前联系人的昵称
        NSString*nickyName=(__bridge NSString*)(ABRecordCopyValue(person, kABPersonNicknameProperty))?:@"Z未命名昵称";
        //获取当前联系人姓氏
        NSString*familyName=(__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty))?:@"Z未命名姓氏";
        //获取当前联系人的公司
        NSString*org=(__bridge NSString*)(ABRecordCopyValue(person, kABPersonOrganizationProperty))?:@"";
        //备注
        NSString*note=(__bridge NSString*)(ABRecordCopyValue(person, kABPersonNoteProperty))?:@"";
        
        CFStringRef value = ABMultiValueCopyValueAtIndex(valuesRef,index);
        
        NSString *firstName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        if (!firstName) {
            firstName = @""; //!!!: 注意这里firstName/lastName是 给@"" 还是 @" ", 如果姓名要求无空格, 则必须为@""
        }
        
        NSString *lastName=(__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        if (!lastName) {
            lastName = @"";
        }
        NSString *phoneNumber = (__bridge NSString*)value;
        NSString *number = [self removeSpecialSubString:phoneNumber];
        NSString *type = (__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(valuesRef, index);
        type = [self removeSpecialSubString:type];
        
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:fullName forKey:@"fullName"];
        [dic setValue:nickyName forKey:@"nickyName"];
        [dic setValue:familyName forKey:@"familyName"];
        [dic setValue:org forKey:@"org"];
        [dic setValue:note forKey:@"note"];
        [dic setValue:type forKey:@"type"];
        [dic setValue:number forKey:@"number"];
        
        DMContactBookPersonModel *model = [DMContactBookPersonModel new];
        model.fullName = dic[@"fullName"];
        model.nickyName = dic[@"nickyName"];
        model.familyName = dic[@"familyName"];
        model.org = dic[@"org"];
        model.note = dic[@"note"];
        model.type = dic[@"type"];
        model.number = dic[@"number"];
        
        if (self.singleBlock) {
            NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:3];
            [resultDic setObject:@"1" forKey:@"code"];
            [resultDic setObject:@"授权成功" forKey:@"msg"];
            [resultDic setObject:dic forKey:@"value"];
            self.singleBlock(model,resultDic);
        }

    } else {
        if (self.singleBlock) {
            NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:3];
            [resultDic setObject:@"-3" forKey:@"code"];
            [resultDic setObject:@"用户无号码" forKey:@"msg"];
            self.singleBlock(nil, resultDic);
        }
    }
    
    [kRootViewController dismissViewControllerAnimated:YES completion:^{
        
        
    }];
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    if (self.singleBlock) {
        NSMutableDictionary *resultDic = [NSMutableDictionary dictionaryWithCapacity:3];
        [resultDic setObject:@"-2" forKey:@"code"];
        [resultDic setObject:@"用户取消" forKey:@"msg"];
        self.singleBlock(nil, resultDic);
    }
}


#endif



@end
