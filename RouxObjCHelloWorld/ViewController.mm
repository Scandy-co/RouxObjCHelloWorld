//
//  ViewController.m
//  RouxObjCHelloWorld
//
//  Created by Evan Laughlin on 2/22/18.
//  Copyright © 2018 Scandy. All rights reserved.
//


#include "ViewController.h"

@interface ViewController ()
@end

@implementation ViewController

bool SCAN_MODE_V2 = true;
// NOTE: if using the default bounding box offset of 0 meters from the sensor, then the
// minimum scan size should be at least 0.2 meters for bare minimum surface scans because
// the iPhone X's TrueDepth absolute minimum depth perception is about 0.15 meters.

- (IBAction)startScanningPressed:(id)sender {
    [self startScanning];
}
- (IBAction)stopScanningPressed:(id)sender {
    [self stopScanning];
}
- (IBAction)saveMeshPressed:(id)sender {
    [self saveMesh];
}
- (IBAction)startPreviewPressed:(id)sender {
    [self turnOnScanner];
}
- (IBAction)scanSizeChanged:(id)sender {
    [self setResolution];
}

- (IBAction)v2ModeToggled:(id)sender {
    SCAN_MODE_V2 = self.v2ModeSwitch.isOn;
    //Need to uninitialize & reinitialize
    [ScandyCore uninitializeScanner];
    [ScandyCore toggleV2Scanning:self.v2ModeSwitch.isOn];
    auto scannerType = scandy::core::ScannerType::TRUE_DEPTH;
    [ScandyCore initializeScanner:scannerType];
    [ScandyCore startPreview];
}
- (IBAction)connectToMirrorDevicePressed:(id)sender {
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [ScandyCore setLicense];
    
    [self turnOnScanner];
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

- (void)turnOnScanner {
    [self renderPreviewScreen];
    if([self requestCamera]){
        [ScandyCore toggleV2Scanning:SCAN_MODE_V2];
        [ScandyCore initializeScanner];
        [ScandyCore setSendRenderedStream:true];
        [ScandyCore setReceiveNetworkCommands:true];
        [self setResolution];
    }
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

- (void)startScanning{
    [self renderScanningScreen];
    [ScandyCore startScanning];
}

- (void)stopScanning{
    [self renderMeshScreen];
    [ScandyCore stopScanning];
    [ScandyCore generateMesh];
}

-(void)saveMesh{
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
}


-(void) renderPreviewScreen{
    [self.scanSizeLabel setHidden:false];
    [self.scanSizeSlider setHidden:false];
    [self.v2ModeSwitch setHidden:false];
    [self.v2ModeLabel setHidden:false];
    [self.startScanButton setHidden:false];
    [self.connectToMirrorDeviceButton setHidden:false];
    
    [self.stopScanButton setHidden:true];
    [self.startPreviewButton setHidden:true];
    [self.saveMeshButton setHidden:true];
    
}

-(void) renderScanningScreen{
    [self.stopScanButton setHidden:false];
    
    [self.connectToMirrorDeviceButton setHidden:true];
    [self.scanSizeLabel setHidden:true];
    [self.scanSizeSlider setHidden:true];
    [self.v2ModeSwitch setHidden:true];
    [self.v2ModeLabel setHidden:true];
    [self.startScanButton setHidden:true];
    [self.startPreviewButton setHidden:true];
    [self.saveMeshButton setHidden:true];
}

-(void) renderMeshScreen{
    [self.startPreviewButton setHidden:false];
    [self.saveMeshButton setHidden:false];
    
    [self.connectToMirrorDeviceButton setHidden:true];
    [self.stopScanButton setHidden:true];
    [self.scanSizeLabel setHidden:true];
    [self.scanSizeSlider setHidden:true];
    [self.v2ModeSwitch setHidden:true];
    [self.v2ModeLabel setHidden:true];
    [self.startScanButton setHidden:true];
}


@end
