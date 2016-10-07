//
//  CentralManager.h
//  HealthGuard
//
//  Created by LaoTao on 15/11/2.
//  Copyright © 2015年 LaoTao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "NearbyPeripheralInfo.h"

/**
 *  设备连接状态
 */
typedef NS_ENUM(NSInteger, BleManagerState) {
    /**
     * 未连接
     */
    BleManagerStateDisconnect = 0,
    
    /**
     * 已连接
     */
    BleManagerStateConnect,
};

@protocol CentralManagerDelegate;

@interface AAA : NSObject


@end

@interface BBB : NSObject

@end

@interface CentralManager : NSObject

/**
 * 设备管理 单利
 */
+ (CentralManager *)sharedManager;

/**
 *  验证蓝牙是否可用
 */
- (BOOL)verifyCentralManagerState;

/**
 * 连接状态
 */
@property (assign, nonatomic) BleManagerState deviceBleState;

/**
 * 添加监听
 */
- (void)addEventListener:(id <CentralManagerDelegate>)listener;

/**
 * 删除监听
 */
- (void)removeEventListener:(id <CentralManagerDelegate>)listener;

/**
 *  删除所有监听
 */
- (void)removeAllEventListener;

/**
 * 取消所有蓝牙连接
 */
- (void)cancelPeripheralConnection;

/**
 * 取消蓝牙搜索
 */
- (void)stopManagerScan;

//***************************
//****设备
//***************************

/**
 * 搜索设备
 */
- (void)searchDeviceModule;

/**
 *  连接设备
 *
 *  @param peripheral 设备
 */
- (void)connectDevicePeripheralWithPeripheral:(CBPeripheral *)peripheral;

@end


@protocol CentralManagerDelegate <NSObject>

@optional

/**
 *  蓝牙未开启 或 不可用
 */
- (void)centralManagerStatePoweredOff;

//***************************
//****设备
//***************************
/**
 *  发现设备
 */
- (void)didDiscoverDevicePeripheral:(CBPeripheral *)peripheral devices:(NSArray *)deviceArray;  //发现设备

/**
 *  开始连接
 */
- (void)didStartConnectDevicePeripheral;

/**
 *  断开连接
 */
- (void)didCancelDevicePeripheralConnection;

/**
 *  发现的特征值
 */
- (void)didDiscoverDevicePeripheral:(CBPeripheral *)peripheral service:(CBService *)service;

/**
 *  连接成功
 */
- (void)didConnectDevicePeripheral:(CBPeripheral *)peripheral;
/**
 *  连接失败
 */
- (void)didFailToConnectDevicePeripheral:(CBPeripheral *)peripheral;

/**
 *  断开连接
 */
- (void)didDisconnectDevicePeripheral:(CBPeripheral *)peripheral;

/**
 *  连接超时
 */
- (void)didConnectionDeviceTimeOut;

/**
 *  接收到数据
 */
- (void)didUpdateDeviceValueForCharacteristic:(CBCharacteristic *)characteristic deviceData:(NSData *)deviceData;


@end
