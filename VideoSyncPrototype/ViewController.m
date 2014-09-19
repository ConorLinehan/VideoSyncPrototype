//
//  ViewController.m
//  VideoSyncPrototype
//
//  Created by Conor Linehan on 28/08/2014.
//  Copyright (c) 2014 Conor Linehan. All rights reserved.
//

// https://s3-eu-west-1.amazonaws.com/videoforaudiosyncvin/VideoVin.mp4
// https://s3-eu-west-1.amazonaws.com/videosforaudiosyncflo/VideoFlo.mp4

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "SERVICES.h"

@interface ViewController ()

{
    NSURLSession *_backgroundSession;
}

@end

@implementation ViewController

{
    NSString *_pathFlo;
    NSString *_pathVin;
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
    _pathFlo = [documentsDirectory stringByAppendingPathComponent:@"floMovie.mp4"];
    _pathVin = [documentsDirectory stringByAppendingPathComponent:@"vinMovie.mp4"];
    
    
    // Handle Downloading
    NSString *dataurlFlo = @"https://s3-eu-west-1.amazonaws.com/videosforaudiosyncflo/VideoFlo.mp4";
    NSURL *urlFlo = [NSURL URLWithString:dataurlFlo];
    
    NSString *dataurlVin = @"https://s3-eu-west-1.amazonaws.com/videoforaudiosyncvin/VideoVin.mp4";
    NSURL *urlVin = [NSURL URLWithString:dataurlVin];
    
    NSURLSession *sessionFlo = [NSURLSession sharedSession];
    NSURLSession *sessionVin = [NSURLSession sharedSession];
    
    NSURLSessionDownloadTask *downloadTaskFlo = [ sessionFlo
                                          downloadTaskWithURL:urlFlo completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                              
                                              NSLog(@"Entered data download Flo");
                                              NSData *data = [NSData dataWithContentsOfURL:location];
                                              [data writeToFile:_pathFlo atomically:YES];
                                              
                                          }];
    
    
    
    [downloadTaskFlo resume];
    
    NSURLSessionDownloadTask *downloadTaskVin = [ sessionVin
                                                 downloadTaskWithURL:urlVin completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                     
                                                     NSLog(@"Entered data download Vin");
                                                     NSData *data = [NSData dataWithContentsOfURL:location];
                                                     [data writeToFile:_pathVin atomically:YES];
                                                     
                                                 }];
    
    
    
    [downloadTaskVin resume];
    
    NSLog(@"%@",_pathVin);
    
    
    
    
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

-(void)playMovieFlo;
{
    
    if ([_fileManager fileExistsAtPath:_pathFlo]) {
    
    NSURL *url = [NSURL fileURLWithPath:_pathFlo];
    
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

-(void)playMovieVin
{
    if ([_fileManager fileExistsAtPath:_pathVin]) {
        
        NSURL *url = [NSURL fileURLWithPath:_pathVin];
        
        
        
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
    [self playMovieVin];
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
    
    [self playMovieFlo];
}

-(void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    [self playMovieFlo];
}



@end
