//
//  ScanView.m
//  ScandyCoreIOSExample
//
//  Created by Evan Laughlin on 2/22/18.
//  Copyright © 2018 Scandy. All rights reserved.
//

#include <scandy/core/IScandyCore.h>

#import "ScanView.h"

#import <GLKit/GLKit.h>
#import <Foundation/Foundation.h>
#import <ScandyCore/ScandyCore.h>
#import <ScandyCore/ScandyCoreManager.h>

@implementation ScanView

- (void)setRendererBackgroundColor
:(double*) color1
:(double*) color2
:(bool) enableGradient
{
  if( ScandyCoreManager.scandyCorePtr->getVisualizer() != nullptr ){
    for( auto viewport : ScandyCoreManager.scandyCorePtr->getVisualizer()->getViewports() ){
      viewport->renderer()->SetGradientBackground(enableGradient);
      if( color1 != nullptr ){
        viewport->renderer()->SetBackground(color1);
      }
      if( color2 != nullptr ){
        viewport->renderer()->SetBackground2(color2);
      }
    }
    [self render];
  }
}


@end
