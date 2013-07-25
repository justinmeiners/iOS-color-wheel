/*
 By: Justin Meiners
 
 Copyright (c) 2013 Inline Studios
 Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
*/

#import <UIKit/UIKit.h>

@class ISColorWheel;

@protocol ISColorWheelDelegate <NSObject>
- (void)colorWheelDidChangeColor:(ISColorWheel*)colorWheel;
@end


@interface ISColorWheel : UIView

@property(nonatomic, strong) UIView* knobView;
@property(nonatomic, assign) CGSize knobSize;
@property(nonatomic, assign) CGFloat brightness;
@property(nonatomic, assign) BOOL continuous;
@property(nonatomic, weak) id <ISColorWheelDelegate> delegate;
@property (nonatomic, assign) UIColor* currentColor;

- (void)updateImage;
- (void)setTouchPoint:(CGPoint)point;

@end
