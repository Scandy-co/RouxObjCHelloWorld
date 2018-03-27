//
//  ViewController.m
//  ScandyCoreIOSExample
//
//  Created by Evan Laughlin on 2/22/18.
//  Copyright © 2018 Scandy. All rights reserved.
//

#include <scandy/core/IScandyCore.h>

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>

#define RENDER_REFRESH_RATE 1.0/30.0

@implementation ViewController

  // NOTE: if using the default bounding box offset of 0 meters from the sensor, then the
  // minimum scan size should be at least 0.2 meters for bare minimum surface scans because
  // the iPhone X's TrueDepth absolute minimum depth perception is about 0.15 meters.

  // the minimum size of scan volume's dimensions in meters
  float minSize = 0.2;

  // the maximum size of scan volume's dimensions in meters
  float maxSize = 5;

// update scan size based on slider
- (IBAction)scanSizeChanged:(id)sender {
  
  float range = maxSize - minSize;
  
  // normalize the scan size based on default slider value range [0, 1]
  float scan_size = (range * self.scanSizeSlider.value) + minSize;
  
  self.scanSizeLabel.text = [NSString stringWithFormat:@"Scan Size: %.02f m", scan_size];
  
  // update the scan size to a cube of scan_size x scan_size x scan_size
  ScandyCoreManager.scandyCorePtr->setScanSize(scan_size);
}


- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:(BOOL)animated];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [(ScanView*)self.view resizeView];
  });
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Get license to use ScandyCore
  NSString *licensePath = [[NSBundle mainBundle] pathForResource:@"ScandyCoreLicense" ofType:@"txt"];
  NSString *licenseString = [NSString stringWithContentsOfFile:licensePath encoding:NSUTF8StringEncoding error:NULL];
  
  // convert license to cString
  const char* licenseCString = [licenseString cStringUsingEncoding:NSUTF8StringEncoding];
  
  // Get access to use ScandyCore
  ScandyCoreManager.scandyCorePtr->setLicense(licenseCString);
  
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
  
  // Tell vtk to handle touch events
  self.vtkGestureHandler = [[VTKGestureHandler alloc] initWithView:self.view];
}

// here you can set the initial scan state with things like scan size, resolution, bounding box offset
// from camera, viewport orientation and so on. All these things can be changed programmatically while
// the preview is running as well, but they cannot change during an active scan.
- (void)setupScanConfiguration{

  // make sure this runs in the same queue as initializeScanner, so our configurations won't get reset
  dispatch_async(dispatch_get_main_queue(), ^{
    
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
    
    // Set the orientation to up upright and mirrored (EXIFOrienation::SIX). This is the default orientation
    // that's set for the TrueDepth sensor in initializeScanner because it's easiest to use when scanning with
    // the front-facing sensor while looking at the screen. You can change it to one of the other seven orientations
    // here. For example, if you want to cast the screen while scanning, using EXIFOrientation::SEVEN would allow a
    // more natural view for when the sensor is facing away from you.
    ScandyCoreManager.scandyCorePtr->setDepthCameraEXIFOrientation(scandy::utilities::EXIFOrientation::SIX);
  });
  
  
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}


- (void)requestCamera {
  switch ( [ScandyCoreManager.scandyCameraDelegate startCamera:AVCaptureDevicePositionFront ]  )
  {
    case AVCamSetupResultSuccess:
    {
      dispatch_async( dispatch_get_main_queue(), ^{
        
        // Initialize the TrueDepth scanner before starting preview
        ScandyCoreManager.scandyCorePtr->initializeScanner(scandy::core::ScannerType::TRUE_DEPTH);
        
        ScandyCoreManager.scandyCorePtr->startPreview();
        
        // Tell our ScanView when to render
        self.m_render_loop = [NSTimer scheduledTimerWithTimeInterval:RENDER_REFRESH_RATE target:(ScanView*)self.view selector:@selector(render) userInfo:nil repeats:YES];
      } );
      break;
    }
    case AVCamSetupResultCameraNotAuthorized:
    {
      break;
    }
    case AVCamSetupResultSessionConfigurationFailed:
    {
      break;
    }
  }
}

- (IBAction)startPreviewPressed:(id)sender {
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
  
  NSString *fileName = [NSString stringWithFormat:@"scandycoreiosexample_%@.ply", iso8601String];
  
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
  NSLog(@"save file to: %@", filePath);

  // save the mesh!
  ScandyCoreManager.scandyCorePtr->saveMesh(std::string([filePath UTF8String]));
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
      
      // Request access to TrueDepth camera
      [ScandyCoreManager.scandyCameraDelegate setDeviceTypes:@[AVCaptureDeviceTypeBuiltInTrueDepthCamera]];
      [self requestCamera];
      
      // NOTE: it's important to call this after scandyCorePtr->initializeScanner() because
      // we need the scanner to have been initialized so that the configuration changes will persist
      [self setupScanConfiguration];
      
      // Make sure our view is the right size
      dispatch_async(dispatch_get_main_queue(), ^{
      [(ScanView*)self.view resizeView];
      });
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
      
      ScandyCoreManager.scandyCorePtr->startScanning();
    });
  }
}

- (void)stopScanning{
  
  [self.stopScanButton setHidden:true];
  
  // Make sure we are running before trying to stop
  if( ScandyCoreManager.scandyCorePtr->isRunning()){
    dispatch_async(dispatch_get_main_queue(), ^{
      ScandyCoreManager.scandyCorePtr->stopScanning();
      [ScandyCoreManager.scandyCameraDelegate stopCamera];
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [(ScanView*)self.view resizeView];
    });
    
    // Make sure the pipeline has fully stopped before calling generate mesh
    // this is why we dispatch_async on main queue separately
    dispatch_async(dispatch_get_main_queue(), ^{
      // Generate mesh and display it in the view
      ScandyCoreManager.scandyCorePtr->generateMesh();
    });
    
    // Nullify the internal scanning configurations and pipeline. This
    // isn't completely necessary if you'll be creating another scan right
    // after, but should be called when moving on to another portion of the
    // application.
    dispatch_async(dispatch_get_main_queue(), ^{
      ScandyCoreManager.scandyCorePtr->uninitializeScanner();
    });
  }
  
  [self.saveMeshButton setHidden:false];
  [self.startPreviewButton setHidden:false];
}


@end
