//
//  ViewController.m
//  ScandyCoreIOSExample
//
//  Created by Evan Laughlin on 2/22/18.
//  Copyright © 2018 Scandy. All rights reserved.
//

#include <scandy/core/IScandyCore.h>

#import "ViewController.h"

#import <ScandyCoreIOS/ScandyCoreFramework.h>
#import <ScandyCoreIOS/ScandyCoreView.h>

#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>

#define RENDER_REFRESH_RATE 1.0/30.0

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:(BOOL)animated];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [(ScanView*)self.view resizeView];
  });
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
  
  // Get our ScandyCore object
  // TODO get proper licent here
  ScandyCoreManager.scandyCorePtr->setLicense("");
  
  self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
  
  if (!self.context) {
    NSLog(@"Failed to create ES context");
  }
  
  ScanView *view = (ScanView *)self.view;
  view.context = self.context;
  view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
  
  [EAGLContext setCurrentContext:self.context];
  
  self.vtkGestureHandler = [[VTKGestureHandler alloc] initWithView:self.view vtkView:view];
  
  [EAGLContext setCurrentContext:self.context];
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


- (void)requestCamera {
  switch ( [ScandyCoreManager.scandyCameraDelegate startCamera:AVCaptureDevicePositionFront ]  )
  {
    case AVCamSetupResultSuccess:
    {
      dispatch_async( dispatch_get_main_queue(), ^{
        ScandyCoreManager.scandyCorePtr->initializeScanner(scandy::core::ScannerType::TRUE_DEPTH);
        
        ScandyCoreManager.scandyCorePtr->startPreview();
        
        NSLog(@"starting render");
        self.m_render_loop = [NSTimer scheduledTimerWithTimeInterval:RENDER_REFRESH_RATE target:(ScanView*)self.view selector:@selector(render) userInfo:nil repeats:YES];
      } );
      break;
    }
    case AVCamSetupResultCameraNotAuthorized:
    {
        //      dispatch_async( dispatch_get_main_queue(), ^{
        //        NSString *message = NSLocalizedString( @"Scandy Core doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
        //        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Scandy Core" message:message preferredStyle:UIAlertControllerStyleAlert];
        //        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
        //        [alertController addAction:cancelAction];
        //        // Provide quick access to Settings.
        //        UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
        //          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
        //        }];
        //        [alertController addAction:settingsAction];
        //        [self presentViewController:alertController animated:YES completion:nil];
        //      } );
      break;
    }
    case AVCamSetupResultSessionConfigurationFailed:
    {
        //      dispatch_async( dispatch_get_main_queue(), ^{
        //        NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
        //        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Scandy Core" message:message preferredStyle:UIAlertControllerStyleAlert];
        //        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
        //        [alertController addAction:cancelAction];
        //        [self presentViewController:alertController animated:YES completion:nil];
        //      } );
      break;
    }
  }
}

- (IBAction)startPreviewPressed:(id)sender {
  [self startPreview];
}

- (void)startPreview {
    // Make sure we are not already running and that we have a valid capture directory
  if( !ScandyCoreManager.scandyCorePtr->isRunning()){
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      
      [ScandyCoreManager.scandyCameraDelegate setDeviceTypes:@[AVCaptureDeviceTypeBuiltInTrueDepthCamera]];

      [self requestCamera];
        // Make sure we're the right size
      dispatch_async(dispatch_get_main_queue(), ^{
      [(ScanView*)self.view resizeView];
      });
    });
  }
}


@end
