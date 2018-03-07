//
//  ViewController.h
//  ScandyCoreIOSExample
//
//  Created by Evan Laughlin on 2/22/18.
//  Copyright © 2018 Scandy. All rights reserved.
//



#import "ScanView.h"

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface ViewController : GLKViewController

@property (weak, nonatomic) IBOutlet UILabel *scanSizeLabel;

@property (weak, nonatomic) IBOutlet UISlider *scanSizeSlider;

@property (weak, nonatomic) IBOutlet UIButton *startScanButton;

@property (weak, nonatomic) IBOutlet UIButton *stopScanButton;

@property (weak, nonatomic) IBOutlet UIButton *saveMeshButton;

@property (strong, nonatomic) NSTimer *m_render_loop;

@property (strong, nonatomic) EAGLContext *context;

- (void)tearDownGL;

- (void)stopScanning;

@property (nonatomic) VTKGestureHandler *vtkGestureHandler;

@end

