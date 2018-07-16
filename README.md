
# [DMContactBook](https://github.com/YRDGroup/DMContactBook)

## Usage

Example apps for iOS are included with the project. Here is one simple usage pattern:

```objective-c
  [DMGetAddressBook getAllAddressBookDataViaJSON:^(NSString *json) {
        NSLog(@"%@",json);
    }];
{
  "msg" : "授权成功",
  "code" : "1",
  "dataArray" : [
    {
      "number" : "无号码",
      "org" : "",
      "familyName" : "A",
      "type" : "未知类型",
      "note" : "",
      "fullName" : "A",
      "nickyName" : "Z未命名昵称"
    },
    {
      "number" : "无号码",
      "org" : "",
      "familyName" : "B",
      "type" : "未知类型",
      "note" : "",
      "fullName" : "B",
      "nickyName" : "Z未命名昵称"
    },
    {
      "number" : "无号码",
      "org" : "",
      "familyName" : "C",
      "type" : "未知类型",
      "note" : "",
      "fullName" : "C",
      "nickyName" : "Z未命名昵称"
    },
    {
      "number" : "18888854486",
      "org" : "",
      "familyName" : "名字",
      "type" : "Home",
      "note" : "",
      "fullName" : "名字",
      "nickyName" : "Z未命名昵称"
    },
    {
      "number" : "18214148525",
      "org" : "",
      "familyName" : "Nznzb",
      "type" : "Home",
      "note" : "",
      "fullName" : "Nznzb",
      "nickyName" : "Z未命名昵称"
    },
    {
      "number" : "15532308745",
      "org" : "",
      "familyName" : "Nznzb",
      "type" : "Work",
      "note" : "",
      "fullName" : "Nznzb",
      "nickyName" : "Z未命名昵称"
    },
    {
      "number" : "18888854381",
      "org" : "",
      "familyName" : "Z未命名姓氏",
      "type" : "Home",
      "note" : "",
      "fullName" : "Z未命名",
      "nickyName" : "Z未命名昵称"
    }
  ]
}
```

While simple, the above example is complete. A clock view creates a KVO controller to observe the clock date property. A block callback is used to handle initial and change notification. Unobservation happens implicitly on controller deallocation, since a strong reference to the `KVOController` is kept. 

Note: the observer specified must support weak references. The zeroing weak reference guards against notification of a deallocated observer instance.

#### NSObject Category
For an even easier usage, just `#import <KVOController/NSObject+FBKVOController.h>` for an automatic `KVOController` property on all objects.

```objc
[self.KVOController observe:clock keyPath:@"date" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew action:@selector(updateClockWithDateChange:)];
```

## Swift

KVOController works great in Swift but there are few requirements:

- Your observer should subclass `NSObject`.
- Properties that you observe must be marked as `dynamic`.

## Installation

To install using [CocoaPods](https://github.com/cocoapods/cocoapods), add the following to your project Podfile:

```ruby
pod 'DMContactBook', '~>1.0.1'
```

## License

DMContactBook is released under a BSD License. See LICENSE file for details.
