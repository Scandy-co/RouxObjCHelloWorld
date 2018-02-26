//
//  ViewController.h
//  ScandyCoreIOSExample
//
//  Created by Evan Laughlin on 2/22/18.
//  Copyright © 2018 Scandy. All rights reserved.
//



#import "ScanView.h"
#import <ScandyCoreIOS/VTKGestureHandler.h>

#import <ScandyCoreIOS/ScandyCoreFramework.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface ViewController : GLKViewController

@property (strong, nonatomic) NSTimer *m_render_loop;

@property (strong, nonatomic) EAGLContext *context;

- (void)tearDownGL;

- (void)stopScanning;

@property (nonatomic) VTKGestureHandler *vtkGestureHandler;

@end

