//
//  ViewController.m
//  RouxObjCHelloWorld
//
//  Created by Evan Laughlin on 2/22/18.
//  Copyright © 2018 Scandy. All rights reserved.
//


#include "ViewController.h"

@interface ViewController () <ScandyCoreDelegate>
@end

@implementation ViewController

bool SCAN_MODE_V2 = true;
NSString* meshPath = @"";

- (void)onVisualizerReady:(bool)createdVisualizer {
    NSLog(@"onVisualizerReady");
}

- (void) onScannerReady:(scandy::core::Status) status {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"onScannerReady");
        if(status == ScandyCoreStatus::SUCCESS){
            if([self requestCamera]){
                [ScandyCore startPreview];
                [self setResolution];
            }
        }
    });
}

- (void) onPreviewStart:(scandy::core::Status) status {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"onPreviewStart");
        if(status == ScandyCoreStatus::SUCCESS){
            [self renderPreviewScreen];
        }
    });
}

- (void) onScannerStart:(scandy::core::Status) status {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"onScannerStart");
        if(status == ScandyCoreStatus::SUCCESS){
            [self renderScanningScreen];
        }
    });
}

- (void) onScannerStop:(scandy::core::Status) status {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"onScannerStop");
        if(status == scandy::core::Status::SUCCESS) {
            [ScandyCore generateMesh];
        }
    });
}

- (void) onGenerateMesh:(scandy::core::Status) status {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"onGenerateMesh");
        if(status == scandy::core::Status::SUCCESS) {
            [self renderMeshScreen];
        }
    });
}

- (void) onSaveMesh:(scandy::core::Status) status {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"onSaveMesh");
        NSString* message;
        
        if( status == ScandyCoreStatus::SUCCESS ){
            message = [NSString stringWithFormat:@"Saved to: %@", meshPath];
        } else {
            message = [NSString stringWithFormat:@"Failed to save because: %@", [NSString stringWithUTF8String:scandy::core::getStatusString(status).c_str()]];
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Finished saving"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [ScandyCore startPreview];
    });
}

- (void)onLoadMesh:(ScandyCoreStatus)status {
    NSLog(@"onLoadMesh");
}

// Network client connected callback
- (void)onClientConnected:(NSString *)host {
    NSLog(@"onClientConnected");
}

- (void)onClientDisconnected:(NSString *)host {
    NSLog(@"onClientDisconnected");
}

- (void)onHostDiscovered:(NSString *)host {
    NSLog(@"onHostDiscovered");
}

- (void)onTrackingDidUpdate:(float)confidence withTracking:(bool)is_tracking {
    NSLog(@"Tracking did update. Confidence: %f is_tracking: %s", confidence, is_tracking ? "true" : "false" );
}

- (void) onVolumeMemoryDidUpdate:(const float) percent_full {
    // NOTE: this is a very active callback, so don't log it as it will slow everything to a crawl
    //NSLog(@"ScandyCoreViewController::onVolumeMemoryDidUpdate %f", percent_full);
}


- (IBAction)startScanningPressed:(id)sender {
    [ScandyCore startScanning];
}

- (IBAction)stopScanningPressed:(id)sender {
    [ScandyCore stopScanning];
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
    meshPath = [documentsDirectory stringByAppendingPathComponent:fileName];
    NSLog(@"saving file to: %@", meshPath);
    
    // save the mesh!
    [ScandyCore saveMesh:meshPath];
}
- (IBAction)startPreviewPressed:(id)sender {
    [ScandyCore startPreview];
}
- (IBAction)scanSizeChanged:(id)sender {
    [self setResolution];
}

- (IBAction)v2ModeToggled:(id)sender {
    SCAN_MODE_V2 = self.v2ModeSwitch.isOn;
    //Need to uninitialize & reinitialize
    [ScandyCore uninitializeScanner];
    [ScandyCore toggleV2Scanning:self.v2ModeSwitch.isOn];
    [ScandyCore initializeScanner];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [ScandyCore setDelegate:self];      //So we can use event listeners
    [ScandyCore setLicense];            //Searches main bundle for ScandyCoreLicense.txt
    [ScandyCore initializeScanner];     //Initialize scanner (true depth by default)
    // [ScandyCore initializeScanner:ScandyCoreScannerType::TRUE_DEPTH]; //Initialize as true depth scanner - same as [ScandyCore initializeScanner];
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
