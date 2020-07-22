//
//  ViewController.h
//  RouxObjCHelloWorld
//
//  Created by Evan Laughlin on 2/22/18.
//  Copyright © 2018 Scandy. All rights reserved.
//

#import <ScandyCore/ScandyCore.h>
#import <GLKit/GLKit.h>

@interface ViewController : GLKViewController

//Scanning Device UI
@property (weak, nonatomic) IBOutlet UIView *scanningDeviceView;
@property (weak, nonatomic) IBOutlet UIButton *changeHostButton;
@property (weak, nonatomic) IBOutlet UIButton *startPreviewButton;
@property (weak, nonatomic) IBOutlet UIButton *saveMeshButton;
@property (weak, nonatomic) IBOutlet UITextField *IPAddressInput;
@property (weak, nonatomic) IBOutlet UILabel *IPAddressInputLabel;
@property (weak, nonatomic) IBOutlet UIButton *connectToMirrorDeviceButton;

//Mirror Device UI
@property (weak, nonatomic) IBOutlet UIView *mirrorDeviceView;
@property (weak, nonatomic) IBOutlet UIButton *startScanButton;
@property (weak, nonatomic) IBOutlet UIButton *stopScanButton;
@property (weak, nonatomic) IBOutlet UILabel *scanSizeLabel;
@property (weak, nonatomic) IBOutlet UISlider *scanSizeSlider;
@property (weak, nonatomic) IBOutlet UISwitch *v2ModeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *v2ModeLabel;


@end

