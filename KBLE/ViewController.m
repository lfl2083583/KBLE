//
//  ViewController.m
//  KBLE
//
//  Created by liufulin on 2019/8/4.
//  Copyright © 2019 technology. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()


@property (nonatomic, strong) CBDescriptor *descriptor;//描述
@property (nonatomic, strong) CBCentralManager *centeralManager;//移动设备
@property (nonatomic, strong) CBPeripheral *peripheral;//蓝牙设备
@property (nonatomic, strong) CBCharacteristic *characteristic;//特征
@property (nonatomic, strong) CBService *service;//服务

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CBCentralManager *manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.centeralManager = manager;
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillDisappear:(BOOL)animated {
    [self stopScan];
    [super viewWillDisappear:animated];
}

- (void)sendBlue {
    NSString *str = @"*********";
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    if (self.characteristic) {
        [self.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

- (void)stopScan {
    [self.centeralManager stopScan];
    if (self.centeralManager && self.peripheral.state == CBPeripheralStateConnected) {
        [self.centeralManager cancelPeripheralConnection:self.peripheral];
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@"CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStatePoweredOn: {
            // 搜索外设 services:通过某些服务筛选外设 传nil=搜索附近所有设备
            [self.centeralManager scanForPeripheralsWithServices:nil options:nil];
            NSLog(@"CBCentralManagerStatePoweredOn");
        }
            break;
        default:
            break;
    }
}

#pragma mark CBCentralManagerDelegate
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"\n设备名称：%@",peripheral.name);
    
    //1、使用设备mac地址判断
    NSData *data  =[advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
    NSString *mac =[[self convertNSString:data] uppercaseString];
    if([mac rangeOfString:K_BLE_MAC].location != NSNotFound){
        self.peripheral = peripheral;
        // 连接外设
        [self.centeralManager connectPeripheral:peripheral options:nil];
    }
    
    //2、使用设备名字判断
    
     if ([peripheral.name isEqualToString:K_BLE_NAME]) {
         self.peripheral = peripheral;
        [self.centeralManager connectPeripheral:peripheral options:nil];
     }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self.centeralManager stopScan];
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self.centeralManager scanForPeripheralsWithServices:nil options:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self.centeralManager scanForPeripheralsWithServices:nil options:nil];
}

#pragma mark CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (!error) {
        for (CBService *service in peripheral.services) {
            self.service = service;
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error {
    if (!error) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            [peripheral discoverDescriptorsForCharacteristic:characteristic];
            [peripheral readValueForCharacteristic:characteristic];
            
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"蓝牙特征"]]) {
                self.characteristic = characteristic;
            } else {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    for (CBDescriptor *descriptor in characteristic.descriptors) {
        [peripheral readValueForDescriptor:descriptor];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSString *value = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"特征值(%@),数据(%@)",characteristic,value);
    //获取描述
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFE2"]]) {
        NSData *data =characteristic.value;
        NSLog(@"%@",[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if(error){
        NSLog(@"改变通知状态");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if (!error) {
        [peripheral readValueForCharacteristic:characteristic];
    }
}


#pragma mark - Convert NSString
- (NSString *)convertNSString:(NSData *)data {
    NSMutableString *strTemp = [NSMutableString stringWithCapacity:[data length]*2];
    const unsigned char *szBuffer = [data bytes];
    for (NSInteger i=0; i < [data length]; ++i) {
        [strTemp appendFormat:@"%02lx",(unsigned long)szBuffer[i]];
    }
    return strTemp;
}
@end
