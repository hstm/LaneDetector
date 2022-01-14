//
//  LaneDetectorBridge.h
//  LaneDetector
//
//  Created by Helge Stahlmann on 14.01.22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LaneDetectorBridge : NSObject
    
- (UIImage *) detectLaneIn: (UIImage *) image;
    
@end
