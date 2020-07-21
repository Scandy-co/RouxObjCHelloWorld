//
//  ViewController.m
//  RouxObjCHelloWorld
// Network demo - Scanning Device
//  Created by Evan Laughlin on 2/22/18.
//  Copyright © 2018 Scandy. All rights reserved.
//


#include "ViewController.h"

@interface ViewController ()
@end

@implementation ViewController

- (IBAction)connectToMirrorDevicePressed:(id)sender {
    [self.view endEditing:YES];
    NSArray* discovered_hosts = [ScandyCore getDiscoveredHosts];
    NSLog(@"Discovered hosts: %@",discovered_hosts);
    if([discovered_hosts containsObject:self.IPAddressInput.text]){
        [ScandyCore connectToCommandHost:self.IPAddressInput.text];
        [ScandyCore setServerHost:self.IPAddressInput.text];
        self.connectedNetworkLabel.text = [[NSString alloc] initWithFormat:@"%s %@","Connected to:",self.IPAddressInput.text];
        [self turnOnScanner];
    }
    else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: [[NSString alloc] initWithFormat:@"No host found at %@", self.IPAddressInput.text]
                                                        message:@"Please enter the IP address of your mirror device."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}
- (IBAction)changeHostButtonPressed:(id)sender {
    [self renderConnectToDeviceScreen];
}
- (IBAction)restartScannerButtonPressed:(id)sender {
    [self turnOnScanner];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [ScandyCore setLicense];
    [ScandyCore setSendRenderedStream:true];
    [ScandyCore setReceiveNetworkCommands:true];
    [ScandyCore initializeScanner];
    [self renderConnectToDeviceScreen];
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
        [ScandyCore startPreview];
    }
}


-(void) renderConnectToDeviceScreen{
    [self.IPAddressInput setHidden:false];
    [self.IPAddressLabel setHidden:false];
    [self.connectToMirrorDeviceButton setHidden:false];
    
    [self.changeHostButton setHidden:true];
    [self.restartScannerButton setHidden:true];

    
}

-(void) renderPreviewScreen{
    [self.changeHostButton setHidden:false];
    [self.restartScannerButton setHidden:false];


    [self.IPAddressInput setHidden:true];
    [self.IPAddressLabel setHidden:true];
    [self.connectToMirrorDeviceButton setHidden:true];
}


@end
