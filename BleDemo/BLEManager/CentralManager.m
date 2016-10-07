//
//  CentralManager.m
//  HealthGuard
//
//  Created by LaoTao on 15/11/2.
//  Copyright © 2015年 LaoTao. All rights reserved.
//

#import "CentralManager.h"



#define UUID_DEVICE_SERVER_0  @"FFE0"
#define UUID_DEVICE_SERVER_1  @"FFE1"
#define UUID_DEVICE_SERVER_2  @"FFE2"


@interface CentralManager ()<CBCentralManagerDelegate, CBPeripheralDelegate,CentralManagerDelegate>
{
    CBPeripheral *_devicePeripheral;    //设备
    
    CBCharacteristic *_deviceCharacteristic;    //设备服务特征 （用来发送指令）
    
    CBCentralManager *_manager;         //
}
@end

@implementation CentralManager
{
    NSMutableArray *_listener;  //观察者
    NSMutableArray *_deviceArray;       //头戴设备数组
}

#pragma mark - 单例
+ (CentralManager *)sharedManager {
    static CentralManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        [self customInit];
    }
    return self;
}

- (void)customInit {
    _listener = [NSMutableArray array];
    _deviceArray = [NSMutableArray array];
    
    _deviceBleState = BleManagerStateDisconnect;
    
    //建立中心角色
    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

//添加监听
- (void)addEventListener:(id <CentralManagerDelegate>)listener {
    [_listener addObject:listener];
}

//删除监听
- (void)removeEventListener:(id <CentralManagerDelegate>)listener {
    [_listener removeObject:listener];
}

/**
 *  删除所有监听
 */
- (void)removeAllEventListener {
    [_listener removeAllObjects];
}

/**
 *  取消所有蓝牙连接
 */
- (void)cancelPeripheralConnection {
    if (_devicePeripheral) {
        [_manager cancelPeripheralConnection:_devicePeripheral];
        _devicePeripheral = nil;
    }
    
    _deviceBleState = BleManagerStateDisconnect;
    [self stopManagerScan];
    
    for (id listener in _listener) {
        if ([listener respondsToSelector:@selector(didCancelDevicePeripheralConnection)]) {
            [listener didCancelDevicePeripheralConnection];
        }
    }
}

/**
 *  取消蓝牙搜索
 */
- (void)stopManagerScan {
    if (_manager) {
        [_manager stopScan];
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSString *stateStr;
    switch (central.state) {
        case CBCentralManagerStateUnknown :
            stateStr = @"当前蓝牙状态未知，请重试";
            break;
        case CBCentralManagerStateUnsupported:
            stateStr = @"当前设备不支持蓝牙设备连接";
            break;
        case CBCentralManagerStateUnauthorized:
            stateStr = @"请前往设置开启蓝牙授权并重试";
            break;
        case CBCentralManagerStatePoweredOff:
            stateStr = @"蓝牙关闭，请开启";
            break;
            
        case CBCentralManagerStateResetting:
            
            break;
        case CBCentralManagerStatePoweredOn:
        {
            stateStr = @"正常";
            //扫描外设(discover)
            NSLog(@"扫描外设");
            
//            NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey : [NSNumber numberWithBool:YES]};
            //开始扫描设备
            [self searchDeviceModule];
            
//            [_manager scanForPeripheralsWithServices:nil options:nil];
        }
            break;
        default:
            stateStr = [NSString stringWithFormat:@"蓝牙异常 %d",(int)central.state];
            break;
    }
}

/**
 *  验证蓝牙是否可用
 */
- (BOOL)verifyCentralManagerState {
    if (_manager.state != CBCentralManagerStatePoweredOn) {
        for (id listener in _listener) {
            if ([listener respondsToSelector:@selector(centralManagerStatePoweredOff)]) {
                [listener centralManagerStatePoweredOff];
            }
        }
        
        return NO;
    }
    return YES;
}

//***************************
//****设备
//***************************
//搜索设备
- (void)searchDeviceModule {
//    if (![self verifyCentralManagerState]) {
//        return;
//    }
    
    [_manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:NO]}];
    //
}

//连接蓝牙设备
- (void)connectDevicePeripheralWithPeripheral:(CBPeripheral *)peripheral {
    if (![self verifyCentralManagerState]) {
        return;
    }
    _devicePeripheral = peripheral;
    [_manager connectPeripheral:peripheral options:@{ CBConnectPeripheralOptionNotifyOnConnectionKey : @YES}];
}

#pragma mark - *******************
/**
 *  这里开始蓝牙的代理方法
 */
#pragma mark - >> 发现蓝牙设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    if (!peripheral.name) {
        return;
    }
    
    NearbyPeripheralInfo *infoModel = [[NearbyPeripheralInfo alloc] init];
    infoModel.peripheral = peripheral;
    infoModel.advertisementData = advertisementData;
    infoModel.RSSI = RSSI;

    //设备
    NSLog(@"发现设备Device:%@, %.2f, %@, %@", peripheral.name, RSSI.floatValue, peripheral.identifier, peripheral);
    
    if (_deviceArray.count == 0) {
        [_deviceArray addObject:infoModel];
    }else {
        BOOL isExist = NO;
        for (int i = 0; i < _deviceArray.count; i++) {
            NearbyPeripheralInfo *model = _deviceArray[i];
            
            if ([model.peripheral isEqual:peripheral]) {
                isExist = YES;
                _deviceArray[i] = infoModel;
            }
        }
        if (!isExist) {
            [_deviceArray addObject:infoModel];
        }
    }
    
    if ([peripheral.name rangeOfString:@"Device"].location != NSNotFound) {
        [_manager connectPeripheral:peripheral options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:NO]}];
    }
    
//    if ([peripheral.identifier.UUIDString isEqualToString:@"35642ACB-2024-B3A0-2BBB-9194F8418967"]) {
////        [_manager connectPeripheral:peripheral options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:NO]}];
//    }else if ([peripheral.identifier.UUIDString isEqualToString:@"8E2CCE3B-95F3-F6DB-906C-E36598E53845"]) {
//        [_manager connectPeripheral:peripheral options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:NO]}];
//    }else if ([peripheral.name isEqualToString:@"CIM thermometer"]) {
//        [_manager connectPeripheral:peripheral options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:NO]}];
//    }

    
    for (id listener in _listener) {
        if ([listener respondsToSelector:@selector(didDiscoverDevicePeripheral:devices:)]) {
            [listener didDiscoverDevicePeripheral:peripheral devices:_deviceArray];
        }
    }
}

/*
 public static String CLIENT_CHARACTERISTIC_CONFIG = "00002902-0000-1000-8000-00805f9b34fb";
 
 //通用特征值
 
 public static String BLOOD_PRESSURE_CHARACTERISTIC6 = "00007480-0000-1000-8000-00805f9b34fb";
 public static String BLOOD_PRESSURE_CHARACTERISTIC7 = "00007481-0000-1000-8000-00805f9b34fb";
 public static String CHAR_NOTIFY_UUID =  BLOOD_PRESSURE_CHARACTERISTIC6;
 public static String CHAR_WRITE_UUID = BLOOD_PRESSURE_CHARACTERISTIC7;
 */

#pragma mark - >> 连接成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"连接成功:%@", peripheral.name);
    
    [self stopManagerScan];   //停止扫描设备
    
    _deviceBleState = BleManagerStateConnect;
    _devicePeripheral = peripheral;
    for (id listener in _listener) {
        if ([listener respondsToSelector:@selector(didConnectDevicePeripheral:)]) {
            [listener didConnectDevicePeripheral:peripheral];
        }
    }
    
    //因为在后面我们要从外设蓝牙那边再获取一些信息，并与之通讯，这些过程会有一些事件可能要处理，所以要给这个外设设置代理
    peripheral.delegate = self;
    //找到该设备上的指定服务 调用完该方法后会调用代理CBPeripheralDelegate（现在开始调用另一个代理的方法了）
//    [peripheral discoverServices:@[[CBUUID UUIDWithString:UUID_DEVICE_SERVER_0]]];
//    [peripheral discoverServices:@[[CBUUID UUIDWithString:@"7480"]]];
    [peripheral discoverServices:nil];
}

#pragma mark - >> 连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    _deviceBleState = BleManagerStateDisconnect;
    for (id listener in _listener) {
        if ([listener respondsToSelector:@selector(didFailToConnectDevicePeripheral:)]) {
            [listener didFailToConnectDevicePeripheral:peripheral];
        }
    }
    NSLog(@"连接失败:%@", peripheral.name);
}

#pragma mark - >> 断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"断开连接:%@", peripheral.name);
    
    for (id listener in _listener) {
        if ([listener respondsToSelector:@selector(didDisconnectDevicePeripheral:)]) {
            [listener didDisconnectDevicePeripheral:peripheral];
        }
    }
    
    // 重连
    [self connectDevicePeripheralWithPeripheral:peripheral];
}

#pragma mark - >> CBPeripheralDelegate
#pragma mark - >> 发现服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error == nil) {
        NSLog(@"发现服务");
        for (CBService *service in peripheral.services) {
            NSLog(@"服务:%@", service);
            //设备
            [peripheral discoverCharacteristics:nil forService:service];
//            if ([service.UUID isEqual:[CBUUID UUIDWithString:UUID_DEVICE_SERVER_0]]) {
//                //查询服务所带的特征值
//                //                [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:@"FFE0"]] forService:service];
//                [peripheral discoverCharacteristics:nil forService:service];
//            }
        }
    }
}

#pragma mark - >> 发现特征值
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"-----发现特征值");
    //在这里给 蓝牙设备写数据， 或者将 peripheral 和 characteristic 拿出去，可以在其他地方，发送命令
    if (error == nil) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            
            NSLog(@"发现特征值:%@", characteristic);
            if (_devicePeripheral == peripheral) {
                
                //
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                
                
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_DEVICE_SERVER_1]]) {
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                    
                }else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_DEVICE_SERVER_2]]) {
                    _deviceCharacteristic = characteristic;
                    
                    for (id listener in _listener) {
                        if ([listener respondsToSelector:@selector(didDiscoverDevicePeripheral:service:)]) {
                            [listener didDiscoverDevicePeripheral:peripheral service:service];
                        }
                    }
                }
            }
            
        }
    }
}

#pragma mark - >> 如果一个特征的值被更新，然后周边代理接收
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
}

#pragma mark - >> 读数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"接收到数据:%@,%@", peripheral.name, characteristic.value);
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"did write value For Characteristic");
    NSLog(@"%@", characteristic.value);
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    NSLog(@"did Write Value For Descriptor");
}


@end
