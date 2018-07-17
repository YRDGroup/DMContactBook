//
//  ViewController.m
//  DMContactBookDemo
//
//  Created by 李二狗 on 2018/7/11.
//  Copyright © 2018年 李二狗. All rights reserved.
//

#import "ViewController.h"
#import "DMGetAddressBook.h"
#import "DMContactBookHandle.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)buttonPressed:(id)sender {
    
    [DMGetAddressBook getAllAddressBookDataViaJSON:^(NSString *json) {
        NSLog(@"%@",json);
    }];
    
    
}
- (IBAction)getsingleButtonPressed:(id)sender {
    
    [DMGetAddressBook callContactsHandler:^(DMContactBookPersonModel *contact, NSDictionary *info) {
        NSLog(@"info  %@",info);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
