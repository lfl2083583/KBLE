//
//  ViewController.h
//  KBLE
//
//  Created by liufulin on 2019/8/4.
//  Copyright © 2019 technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define K_BLE_NAME @"作为判断搜索到蓝牙，设备名称"
#define K_BLE_MAC @"作为判断搜索到蓝牙，设备MAC地址"

@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>


@end

