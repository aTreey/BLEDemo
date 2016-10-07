//
//  RootViewController.m
//  BleDemo
//
//  Created by LaoTao on 16/1/12.
//  Copyright © 2016年 LaoTao. All rights reserved.
//

#import "RootViewController.h"
#import "CentralManager.h"

@interface RootViewController ()<UITableViewDataSource, UITableViewDelegate, CentralManagerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableview;

@end

@implementation RootViewController {
    NSArray *_deviceArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = @"蓝牙列表";
    _tableview.delegate = self;
    _tableview.dataSource = self;
    
    //添加监听 （实则为代理，每个添加监听的类，可以收到蓝牙发出的代理通知）
    [[CentralManager sharedManager] addEventListener:self];
    
    //如果视图需要销毁，需要先调用remove
//    [[CIMCentralManager sharedManager] removeEventListener:self];
    
    //搜索蓝牙设备
//    [[CIMCentralManager sharedManager] searchDeviceModule];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //连接选中的设备， 备注：本项目只是一个Demo工程，只是简单实现业务逻辑, 功能并不强大
    NearbyPeripheralInfo *infoModel = _deviceArray[indexPath.row];
    [[CentralManager sharedManager] connectDevicePeripheralWithPeripheral:infoModel.peripheral];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _deviceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIde = @"cellIde";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIde];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIde];
        
    }
    
    NearbyPeripheralInfo *infoModel = _deviceArray[indexPath.row];
    cell.textLabel.text = infoModel.peripheral.name;
    
    return cell;
}

- (void)didDiscoverDevicePeripheral:(CBPeripheral *)peripheral devices:(NSArray *)deviceArray {
    _deviceArray = deviceArray;
    [_tableview reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
