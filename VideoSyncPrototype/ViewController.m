//
//  ViewController.m
//  VideoSyncPrototype
//
//  Created by Conor Linehan on 28/08/2014.
//  Copyright (c) 2014 Conor Linehan. All rights reserved.
//

// https://s3-eu-west-1.amazonaws.com/videoforaudiosyncvin/VideoVin.mp4
// https://s3-eu-west-1.amazonaws.com/videosforaudiosyncflo/VideoFlo.mp4

// https://s3-eu-west-1.amazonaws.com/nietbang/leftvideo.mp4
// https://s3-eu-west-1.amazonaws.com/nietbang/rightvideo.mp4

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "SERVICES.h"

@interface ViewController ()

{
    NSURLSession *_backgroundSession;
    NSURL *_test;
}

@end

@implementation ViewController

{
    NSString *_pathLeft;
    NSString *_pathRight;
    MPMoviePlayerController *_player;
    NSFileManager *_fileManager;
}

- (void)viewDidLoad // Need to clean up
{
    [super viewDidLoad];
    
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    [_peripheralManager startAdvertising:
     @{CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]}];
    
    _fileManager = [NSFileManager defaultManager];
    
    _player = [[MPMoviePlayerController alloc] init]; // Create Movie Player
    [[_player view] setFrame:[[self view] bounds]];
   // [[self view] addSubview:[_player view]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0];
    _pathLeft = [documentsDirectory stringByAppendingPathComponent:@"VideoLeft.mp4"];
    _pathRight = [documentsDirectory stringByAppendingPathComponent:@"VideoRight.mp4"];
    
    
    // Handle Downloading
    NSString *dataurlLeft = @"https://s3-eu-west-1.amazonaws.com/nietbang/leftvideo.mp4";
    NSURL *urlLeft = [NSURL URLWithString:dataurlLeft];
    
    NSString *dataurlRight = @"https://s3-eu-west-1.amazonaws.com/nietbang/rightvideo.mp4";
    NSURL *urlRight = [NSURL URLWithString:dataurlRight];
    
    NSURLSession *sessionLeft = [NSURLSession sharedSession];
    NSURLSession *sessionRight = [NSURLSession sharedSession];
    
    NSURLSessionDownloadTask *downloadTaskLeft = [ sessionLeft
                                          downloadTaskWithURL:urlLeft completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                              
                                              NSLog(@"Entered data download Flo");
                                              NSData *data = [NSData dataWithContentsOfURL:location];
                                              [data writeToFile:_pathLeft atomically:YES];
                                              
                                          }];
    
    
    
    [downloadTaskLeft resume];
    
    NSURLSessionDownloadTask *downloadTaskRight = [ sessionRight
                                                 downloadTaskWithURL:urlRight completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                     
                                                     NSLog(@"Entered data download Vin");
                                                     NSData *data = [NSData dataWithContentsOfURL:location];
                                                     [data writeToFile:_pathRight atomically:YES];
                                                     
                                                 }];
    
    
    
    [downloadTaskRight resume];
    
    NSLog(@"%@",_pathRight);
    
    
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillDisappear:(BOOL)animated
{
    [_centralManager stopScan];
}

-(void)playMovieLeft;
{
    
    if ([_fileManager fileExistsAtPath:_pathLeft]) {
    
    NSURL *url = [NSURL fileURLWithPath:_pathLeft];
    
   // NSURL *url = [NSURL URLWithString:@"https://s3-eu-west-1.amazonaws.com/videosforaudiosyncflo/VideoFlo.mp4"];
    
    /*
    [_player setContentURL:url];
    [[self view] addSubview:[_player view]];
    [_player play];
     */
    
        MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
        
        [self presentMoviePlayerViewControllerAnimated:moviePlayer];
        [moviePlayer.moviePlayer play];
    
    
    NSLog(@"Entered");
    } else {
        NSLog(@"File does not exist");
    }
    
}

-(void)playMovieRight
{
    if ([_fileManager fileExistsAtPath:_pathRight]) {
        
        NSURL *url = [NSURL fileURLWithPath:_pathRight];
        
        
        
        MPMoviePlayerViewController *movieController = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
        
        [self presentMoviePlayerViewControllerAnimated:movieController];
        [movieController.moviePlayer play];
        
        
        NSLog(@"Entered");
    } else {
        NSLog(@"File does not exist");
    }
    
}

-(IBAction)play
{
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

-(IBAction)downloadMovie
{
    
}

#pragma mark CBManger methods

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        return;
    } else if (central.state == CBCentralManagerStatePoweredOn) {
        // Scan for devices
        [_centralManager
         scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]
         options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
        NSLog(@"Scanning started");
    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (_discoveredPeripheral != peripheral) {
        // Save Local copy of peripheral, so CoreBluetooth doesnt get rid of it
        _discoveredPeripheral = peripheral;
        
        // Connect
        NSLog(@"Connecting to peripheral %@",peripheral);
        [_centralManager connectPeripheral:peripheral options:nil];
    }
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
    
    peripheral.delegate = self;

    
   // [self playMovieVin];
}



#pragma mark peripheral methods

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if(error) {
        // [self cleanup];
        return;
    }
    
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
    }
    // Discover other characterstics
    [self playMovieRight];
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
     //   [self cleanup];
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}



-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
        return;
    }
    
    if(characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    } else {
        // Notification has stopped
        [_centralManager cancelPeripheralConnection:peripheral];
    }
}

#pragma mark Peripheral manager methods

-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"Peripheral did update state");
    
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        
        self.transferCharacteristic = [[CBMutableCharacteristic alloc]
                                       initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]
                                       properties:CBCharacteristicPropertyNotify
                                       value:nil
                                       permissions:CBAttributePermissionsReadable];
        
        CBMutableService *transferService = [[CBMutableService alloc]
                                             initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID] primary:YES];
        
        transferService.characteristics = @[_transferCharacteristic];
        
        [_peripheralManager addService:transferService];
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Should play flo");
    
    [self playMovieLeft];
}

-(void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    [self playMovieLeft];
}



@end
