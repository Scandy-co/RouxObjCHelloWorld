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

@property (weak, nonatomic) IBOutlet UIButton *connectToMirrorDeviceButton;
@property (weak, nonatomic) IBOutlet UITextField *IPAddressInput;
@property (weak, nonatomic) IBOutlet UILabel *IPAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *connectedNetworkLabel;
@property (weak, nonatomic) IBOutlet UIButton *changeHostButton;
@property (weak, nonatomic) IBOutlet UIButton *restartScannerButton;

@end

