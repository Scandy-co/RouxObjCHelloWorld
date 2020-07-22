//
//  ViewController.m
//  RouxObjCHelloWorld
//  Networking Demo
//  Created by April Polubiec on 7/22/20.
//  Copyright © 2018 Scandy. All rights reserved.
//


#include "ViewController.h"

@interface ViewController ()
@end

@implementation ViewController
bool SCAN_MODE_V2 = true;
- (IBAction)selectDeviceTypeToggled:(id)sender {
    [ScandyCore uninitializeScanner];
    NSInteger deviceType = [self.selectDeviceType selectedSegmentIndex];
    switch(deviceType){
        case 0:
            [self initializeMirrorDevice];
            break;
        case 1:
            [self initializeScanningDevice];
            break;
        default:
            return;
    }
}

//MARK: Mirror Device Actions
- (IBAction)startScanningPressed:(id)sender {
    [self renderScanningScreen];
    [ScandyCore startScanning];
}

- (IBAction)scanSizeChanged:(id)sender {
    [self setResolution];
}

- (IBAction)toggleV2:(id)sender {
    SCAN_MODE_V2 = self.v2ModeSwitch.isOn;
    //Need to uninitialize & reinitialize
    [ScandyCore uninitializeScanner];
    [ScandyCore toggleV2Scanning:self.v2ModeSwitch.isOn];
    [ScandyCore initializeScanner:ScandyCoreScannerType::NETWORK];
    [ScandyCore startPreview];
}

- (IBAction)stopScanningPressed:(id)sender {
    [ScandyCore stopScanning];
    [ScandyCore generateMesh];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Scanning Complete"
                                                    message:@"Mesh has been generated on scanning device."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [self initializeMirrorDevice];

}

//MARK: Scanning Device Actions
- (IBAction)connectToMirrorDeviceButtonPressed:(id)sender {
    [self.view endEditing:YES];
    NSArray* discovered_hosts = [ScandyCore getDiscoveredHosts];
    NSLog(@"Discovered hosts: %@",discovered_hosts);
    if([discovered_hosts containsObject:self.IPAddressInput.text]){
        [ScandyCore connectToCommandHost:self.IPAddressInput.text];
        [ScandyCore setServerHost:self.IPAddressInput.text];
        self.IPAddressLabel.text = [[NSString alloc] initWithFormat:@"%s %@","Connected to:",self.IPAddressInput.text];
        [self renderPreviewScreen:1];
        [ScandyCore startPreview];
    }
    else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: [[NSString alloc] initWithFormat:@"No host found at %@", self.IPAddressInput.text]
                                                        message:@"Please enter the IP address of your mirror device."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}
- (IBAction)saveMeshPressed:(id)sender {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
    
    NSDate *now = [NSDate date];
    NSString *iso8601String = [dateFormatter stringFromDate:now];
    
    // NOTE: You can change this to: obj, ply, or stl
    NSString *fileTypeExt = @"ply";
    
    NSString *fileName = [NSString stringWithFormat:@"scandycoreiosexample_%@.%@", iso8601String, fileTypeExt];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    NSLog(@"save file to: %@", filePath);
    
    // save the mesh!
    auto status = [ScandyCore saveMesh:filePath];
    NSString* message;
    
    if( status == scandy::core::Status::SUCCESS ){
        message = [NSString stringWithFormat:@"Saved to: %@", filePath];
    } else {
        message = [NSString stringWithFormat:@"Failed to save because: %@", [NSString stringWithUTF8String:scandy::core::getStatusString(status).c_str()]];
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Finished saving"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [self renderPreviewScreen:1];
    [ScandyCore startPreview];
}
- (IBAction)startPreviewPressed:(id)sender {
    [self renderPreviewScreen:1];
    [ScandyCore startPreview];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [ScandyCore setLicense];
    [self initializeMirrorDevice];
}

- (void)initializeMirrorDevice {
    [self.mirrorDeviceView setHidden:false];
    [self.scanningDeviceView setHidden: true];
    [self renderPreviewScreen:0];
    if([self requestCamera]){
        [ScandyCore setSendRenderedStream:false];
        [ScandyCore setReceiveNetworkCommands:false];
        [ScandyCore setReceiveRenderedStream:true];
        [ScandyCore setSendNetworkCommands:true];
        [ScandyCore initializeScanner:ScandyCoreScannerType::NETWORK];
        [ScandyCore startPreview];
        NSString* IPAddress = [ScandyCore getIPAddress];
        [self.IPAddressLabel setText:[NSString stringWithFormat:@"IP Address: %@", IPAddress]];
        [self setResolution];
        [ScandyCore setServerHost:IPAddress];
    }
}

- (void)initializeScanningDevice{
    [self.mirrorDeviceView setHidden:true];
    [self.scanningDeviceView setHidden:false];
    if([self requestCamera]){
        [ScandyCore setReceiveRenderedStream:false];
        [ScandyCore setSendNetworkCommands:false];
        [ScandyCore setSendRenderedStream:true];
        [ScandyCore setReceiveNetworkCommands:true];
        
        [ScandyCore initializeScanner];
        [self.IPAddressLabel setText:@"Connected to: "];
        [self renderConnectToDeviceScreen];
    }
}

- (bool)requestCamera {
    if ( [ScandyCore hasCameraPermission]  )
    {
        NSLog(@"user has granted permission to camera!");
        return true;
    } else {
        NSLog(@"user has denied permission to camera");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera permission"
                                                        message:@"We need to access the camera to make a 3D scan. Go to settings and allow permission."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    return false;
}

- (void)setResolution{
    if (SCAN_MODE_V2){
        float minRes = 0.0005; // == 0.5 mm
        float maxRes = 0.006; // == 6 mm
        float range = maxRes - minRes;
        double voxelRes = (range * double(self.scanSizeSlider.value)) + minRes;
        [ScandyCore setVoxelSize:voxelRes];
        self.scanSizeLabel.text =  [NSString stringWithFormat:@"Scan Size: %.01f mm", voxelRes*1000];
    } else {
        // the minimum size of scan volume's dimensions in meters
        double minSize = 0.2;
        // the maximum size of scan volume's dimensions in meters
        double maxSize = 5.0;
        double range = maxSize - minSize;
        //Make sure we are passing a Double to setScanSize
        double scan_size = (range * double(self.scanSizeSlider.value)) + minSize;
        [ScandyCore setScanSize:scan_size];
        self.scanSizeLabel.text =  [NSString stringWithFormat:@"Scan Size: %.03f m", scan_size];
    }
}


- (void)renderPreviewScreen:(int) device_type {
    switch(device_type){
        case 0:
            //Mirror Device
            [self.startScanButton setHidden:false];
            [self.scanSizeLabel setHidden:false];
            [self.scanSizeSlider setHidden:false];
            [self.v2ModeSwitch setHidden:false];
            [self.v2ModeLabel setHidden:false];
            
            [self.stopScanButton setHidden:true];
            [self.startPreviewButton setHidden:true];
            break;
        case 1:
            //Scanning Device
            [self.changeHostButton setHidden:false];
            [self.saveMeshButton setHidden:false];
            [self.startPreviewButton setHidden:false];
            
            [self.IPAddressInputLabel setHidden:true];
            [self.IPAddressInput setHidden:true];
            [self.connectToMirrorDeviceButton setHidden:true];
            break;
        default:
            break;
    }
}

-(void) renderConnectToDeviceScreen{
    [self.IPAddressInput setHidden:false];
    [self.IPAddressInputLabel setHidden:false];
    [self.connectToMirrorDeviceButton setHidden:false];
    
    [self.changeHostButton setHidden:true];
    [self.saveMeshButton setHidden:true];
    [self.startPreviewButton setHidden:true];
}

-(void) renderScanningScreen {
    [self.stopScanButton setHidden:false];
    
    [self.startScanButton setHidden:true];
    [self.scanSizeLabel setHidden:true];
    [self.scanSizeSlider setHidden:true];
    [self.v2ModeLabel setHidden:true];
    [self.v2ModeSwitch setHidden:true];
}

@end
