//
//  ViewController.m
//  ScandyCoreIOSExample
//
//  Created by Evan Laughlin on 2/22/18.
//  Copyright © 2018 Scandy. All rights reserved.
//

#include <scandy/core/IScandyCore.h>
#include <scandy/core/IScandyCoreConfiguration.h>

#import <ScandyCore/ScandyCore.h>

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>


// Easily switch between scan modes for demoing
#define SCAN_MODE_V2 1

@interface ViewController () <ScandyCoreManagerDelegate>
@end

@implementation ViewController

  // NOTE: if using the default bounding box offset of 0 meters from the sensor, then the
  // minimum scan size should be at least 0.2 meters for bare minimum surface scans because
  // the iPhone X's TrueDepth absolute minimum depth perception is about 0.15 meters.

  // the minimum size of scan volume's dimensions in meters
  float minSize = 0.2;

  // the maximum size of scan volume's dimensions in meters
  float maxSize = 5;

- (void)onVisualizerReady:(bool)createdVisualizer {
  NSLog(@"onVisualizerReady");
}
- (void) onScannerReady:(scandy::core::Status) status {
  NSLog(@"onScannerReady");
}
- (void) onPreviewStart:(scandy::core::Status) status {
  NSLog(@"onPreviewStart");
}
- (void) onScannerStart:(scandy::core::Status) status {
  NSLog(@"onScannerStart");
}
- (void) onScannerStop:(scandy::core::Status) status {
  NSLog(@"onScannerStop");
  dispatch_async(dispatch_get_main_queue(), ^{
    if( status == scandy::core::Status::SUCCESS) {
      // Generate mesh and display it in the view
      [ScandyCoreManager generateMesh];
    }
  });
}
- (void) onGenerateMesh:(scandy::core::Status) status {
  NSLog(@"onGenerateMesh");
  dispatch_async(dispatch_get_main_queue(), ^{
    if( status == scandy::core::Status::SUCCESS) {
      // Change the background to a slight gradient
      double color1[3] = {0.1,0.1,0.1};
      double color2[3] = {0.2,0.2,0.23};
      [(ScanView*)self.view setRendererBackgroundColor:color1 :color2 :true];

      [(ScanView*)self.view resizeView];

      bool should_uninitialize = false;
      if( should_uninitialize ){
        // Nullify the internal scanning configurations and pipeline. This
        // isn't completely necessary if you'll be creating another scan right
        // after, but should be called when moving on to another portion of the
        // application.
        [ScandyCoreManager uninitializeScanner];
      }
    }
  });
}
- (void) onSaveMesh:(scandy::core::Status) status {
  NSLog(@"onSaveMesh");
}
// NOTE: only used in scan mode v2, which is currently experimental
- (void) onVolumeMemoryDidUpdate:(const float) percent_full {
  // NOTE: this is a very active callback, so don't log it as it will slow everything to a crawl
  //NSLog(@"ScandyCoreViewController::onVolumeMemoryDidUpdate %f", percent_full);
}
// Network client connected callback
- (void)onClientConnected:(NSString *)host {
  NSLog(@"onClientConnected");
}

- (void)onTrackingDidUpdate:(bool)is_tracking {
  // NOTE: this is a very active callback, so don't log it as it will slow everything to a crawl
  // NSLog(@"onTrackingDidUpdate");
}


// update scan size based on slider
- (IBAction)scanSizeChanged:(id)sender {
  
  float range = maxSize - minSize;
  
  // normalize the scan size based on default slider value range [0, 1]
  float scan_size = (range * self.scanSizeSlider.value) + minSize;

#if SCAN_MODE_V2
  // For scan mode v2, the resolution should be
  scan_size *= 0.004; // Scale the 0.0 - 1.0 value to be a max of 4mm
  scan_size = std::max(scan_size, 0.0005f);
  ScandyCoreManager.scandyCorePtr->setVoxelSize(scan_size);
#else
  // update the scan size to a cube of scan_size x scan_size x scan_size
  ScandyCoreManager.scandyCorePtr->setScanSize(scan_size);
#endif
  self.scanSizeLabel.text = [NSString stringWithFormat:@"Scan Size: %.03f m", scan_size];
}


- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:(BOOL)animated];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [(ScanView*)self.view resizeView];
  });
}

- (void)setLicense {
  // Get license to use ScandyCore
  NSString *licensePath = [[NSBundle mainBundle] pathForResource:@"ScandyCoreLicense" ofType:@"txt"];
  NSString *licenseString = [NSString stringWithContentsOfFile:licensePath encoding:NSUTF8StringEncoding error:NULL];

  // convert license to cString
  const char* licenseCString = [licenseString cStringUsingEncoding:NSUTF8StringEncoding];

  // Get access to use ScandyCore
  ScandyCoreManager.scandyCorePtr->setLicense(licenseCString);
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setLicense];

  // Make ourselves into a ScandyCoreManagerDelegate
  [ScandyCoreManager setScandyCoreDelegate:self];

  self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
  
  if (!self.context) {
    NSLog(@"Failed to create ES context");
  }

  [EAGLContext setCurrentContext:self.context];
  
  [self loadScanView];
  
  [self.stopScanButton setHidden:true];
  
  [self startPreview];
}

- (void)loadScanView{
  // Connect our ScanView with this ViewController
  ScanView *view = (ScanView *)self.view;
  view.context = self.context;
  view.drawableDepthFormat = GLKViewDrawableDepthFormat16;

  // Have ScandyCoreView create our visualizer
  [view createVisualizer];

  // Make sure the ScandyCoreManager has a reference to our view to control it's rendering
  [ScandyCoreManager setScandyCoreView:view];
}

// here you can set the initial scan state with things like scan size, resolution, bounding box offset
// from camera, viewport orientation and so on. All these things can be changed programmatically while
// the preview is running as well, but they cannot change during an active scan.
- (void)setupScanConfiguration{

  // The scan size represents the width, height, and depth (in meters) of the scan volume's bounding box, which
  // must all be the same value.
  // set the initial scan size to 0.5m x 0.5m x 0.5m
  float scan_size = 0.5;
  ScandyCoreManager.scandyCorePtr->setScanSize(scan_size);

  // Set the bounding box offset 0.2 meters from the sensor to be able to use the full bounding box for
  // scanning since the TrueDepth sensor can't see before about 0.15m
  // We recommend not setting this too much farther than you need to because the quality of depth data
  // degrades farther away from the sensor
  float offset = 0.2;
  ScandyCoreManager.scandyCorePtr->setBoundingBoxOffset(offset);

  // update the scan slider to match for the sake of this example
  self.scanSizeLabel.text = [NSString stringWithFormat:@"Scan Size: %.02f m", scan_size];
  self.scanSizeSlider.value = (scan_size - minSize)/(maxSize - minSize);
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}


- (void)requestCamera {
  if ( [ScandyCoreManager.scandyCameraDelegate hasPermission]  )
  {
    NSLog(@"user has granted permission to camera!");
  } else {
    NSLog(@"user has denied permission to camera");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera permission"
                                                    message:@"We need to access the camera to make a 3D scan. Go to settings and allow permission."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
  }
}

- (IBAction)startPreviewPressed:(id)sender {
  
  // clear out memory from previous session and reload the view
  [ScandyCoreManager reset];

  // Make sure we put our license back in after reseting
  [self setLicense];

  // reload the view and connect it to ScandyCore after reset
  [self loadScanView];
  
  [self startPreview];
}

- (IBAction)startScanningPressed:(id)sender {
  [self startScanning];
}

- (IBAction)stopScanningPressed:(id)sender {
  [self stopScanning];
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
  auto status = [ScandyCoreManager saveMesh:filePath];
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

- (void)startPreview {
  
  [self.scanSizeLabel setHidden:false];
  [self.scanSizeSlider setHidden:false];
  [self.startScanButton setHidden:false];
  
  [self.startPreviewButton setHidden:true];
  [self.saveMeshButton setHidden:true];

  // Make sure we are not already running and that we have a valid capture directory
  if( !ScandyCoreManager.scandyCorePtr->isRunning()){
    dispatch_async(dispatch_get_main_queue(), ^{

      // Make sure we have camera permissions
      [self requestCamera];

      auto config = ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration();

#if SCAN_MODE_V2
      // In Scandy Pro this is called scan mode v2. It sets the scan into a resolution mode, into scan size
      config->m_use_unbounded = true;
#else
      config->m_use_unbounded = false;
#endif

      auto scannerType = scandy::core::ScannerType::TRUE_DEPTH;
      auto status = [ScandyCoreManager initializeScanner:scannerType];
      if (status != scandy::core::Status::SUCCESS) {
        auto reason = [[NSString alloc] initWithFormat:@"%s", scandy::core::getStatusString(status).c_str() ];
        NSLog(@"failed to initialize scanner with reason: %@", reason);
      }

      // NOTE: it's important to call this after [ScandyCoreManager initializeScanner] because
      // we need the scanner to have been initialized so that the configuration changes will persist
      [self setupScanConfiguration];

      // Actually start the preview
      [ScandyCoreManager startPreview];
    });
  }
}

- (void)startScanning{
  
  [self.scanSizeLabel setHidden:true];
  [self.scanSizeSlider setHidden:true];
  [self.startScanButton setHidden:true];
  
  [self.stopScanButton setHidden:false];
  
  // Make sure we are running from preview first
  if( ScandyCoreManager.scandyCorePtr->isRunning()){
    dispatch_async(dispatch_get_main_queue(), ^{
      [ScandyCoreManager startScanning];
    });
  }
}

- (void)stopScanning{
  
  [self.stopScanButton setHidden:true];
  
  // Make sure we are running before trying to stop
  if( ScandyCoreManager.scandyCorePtr->isRunning()){
    dispatch_async(dispatch_get_main_queue(), ^{
      [ScandyCoreManager stopScanning];
    });
  }
  
  [self.saveMeshButton setHidden:false];
  [self.startPreviewButton setHidden:false];
}


@end
