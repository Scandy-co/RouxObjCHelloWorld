//
//  ScanView.h
//  ScandyCoreIOSExample
//
//  Created by Evan Laughlin on 2/22/18.
//  Copyright © 2018 Scandy. All rights reserved.
//

#ifndef ScanView_h
#define ScanView_h

#import <ScandyCore/ScandyCoreView.h>

@interface ScanView : ScandyCoreView
- (void)setRendererBackgroundColor:(double*) color1 :(double*) color2 :(bool) enableGradient;
@end

#endif /* ScanView_h */
