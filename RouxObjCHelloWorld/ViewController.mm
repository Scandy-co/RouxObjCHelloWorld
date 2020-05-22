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

// the minimum size of scan volume's dimensions in millimeters
double minSize = 0.2;

// the maximum size of scan volume's dimensions in millimeters
double maxSize = 5;

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
    double range = maxSize - minSize;
    
    // normalize the scan size based on default slider value range [0, 1]
    double scan_size = (range * self.scanSizeSlider.value) + minSize;
    NSLog(@"scan size: %@", [NSString stringWithFormat:@"%f", scan_size]);
    
    if (SCAN_MODE_V2)
    {// For scan mode v2, the resolution should be
        scan_size *= 0.004; // Scale the 0.0 - 1.0 value to be a max of 4mm
        scan_size = std::max(float(scan_size), 0.0005f);
        [ScandyCore setVoxelSize:scan_size];}
    else{
        NSLog(@"scan size: %@", [NSString stringWithFormat:@"%f", scan_size]);
        [ScandyCore setScanSize:scan_size];
    }
    self.scanSizeLabel.text = [NSString stringWithFormat:@"Scan Size: %.03f m", scan_size];
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
        auto scannerType = scandy::core::ScannerType::TRUE_DEPTH;
        [ScandyCore initializeScanner:scannerType];
        [ScandyCore startPreview];
        // Set the voxel size to 1.0m
        double mm = 1.0;
        [ScandyCore setVoxelSize:(mm*1e-3)];
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
    
    [self.stopScanButton setHidden:true];
    [self.startPreviewButton setHidden:true];
    [self.saveMeshButton setHidden:true];
    
}

-(void) renderScanningScreen{
    [self.stopScanButton setHidden:false];
    
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
    
    [self.stopScanButton setHidden:true];
    
    [self.scanSizeLabel setHidden:true];
    [self.scanSizeSlider setHidden:true];
    [self.v2ModeSwitch setHidden:true];
    [self.v2ModeLabel setHidden:true];
    [self.startScanButton setHidden:true];
}


@end
