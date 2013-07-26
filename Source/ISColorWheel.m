/*
 By: Justin Meiners
 
 Copyright (c) 2013 Inline Studios
 Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
 */

#import "ISColorWheel.h"

typedef struct
{
    unsigned char r;
    unsigned char g;
    unsigned char b;
    
} PixelRGB;

static float ISColorWheel_PointDistance (CGPoint p1, CGPoint p2)
{
    return sqrtf((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y));
}


static PixelRGB ISColorWheel_HSBToRGB (float h, float s, float v)
{
    h *= 6.0f;
    int i = floorf(h);
    float f = h - (float)i;
    float p = v *  (1.0f - s);
    float q = v * (1.0f - s * f);
    float t = v * (1.0f - s * (1.0f - f));
    
    float r;
    float g;
    float b;
    
    switch (i)
    {
        case 0:
            r = v;
            g = t;
            b = p;
            break;
        case 1:
            r = q;
            g = v;
            b = p;
            break;
        case 2:
            r = p;
            g = v;
            b = t;
            break;
        case 3:
            r = p;
            g = q;
            b = v;
            break;
        case 4:
            r = t;
            g = p;
            b = v;
            break;
        default:        // case 5:
            r = v;
            g = p;
            b = q;
            break;
    }
    
    PixelRGB pixel;
    pixel.r = r * 255.0f;
    pixel.g = g * 255.0f;
    pixel.b = b * 255.0f;
    
    return pixel;
}

@interface ISColorKnob : UIView

@end

@implementation ISColorKnob

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctx, 2.0);
    CGContextSetStrokeColorWithColor(ctx, [UIColor blackColor].CGColor);
    CGContextAddEllipseInRect(ctx, CGRectInset(self.bounds, 2.0, 2.0));
    CGContextStrokePath(ctx);
}
@end


@interface ISColorWheel ()
{
    PixelRGB* _imageData;
    int _imageDataLength;
    CGImageRef _radialImage;
    float _radius;
    CGPoint _touchPoint;
}

- (PixelRGB)colorAtPoint:(CGPoint)point;
- (CGPoint)viewToImageSpace:(CGPoint)point;
- (void)updateKnob;

@end



@implementation ISColorWheel

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        _radialImage = NULL;
        _imageData = NULL;
        
        _imageDataLength = 0;
        
        _brightness = 1.0;
        _knobSize = CGSizeMake(20, 20);
        _touchPoint = CGPointMake(CGRectGetWidth(self.bounds) / 2.0, CGRectGetHeight(self.bounds) / 2.0);
                
        ISColorKnob* knob = [[ISColorKnob alloc] init];
        self.knobView = knob;
        self.backgroundColor = [UIColor clearColor];
        
        _continuous = false;
    }
    return self;
}

- (void)dealloc
{
    if (_radialImage)
    {
        CGImageRelease(_radialImage);
    }
    
    if (_imageData)
    {
        free(_imageData);
    }
}


- (PixelRGB)colorAtPoint:(CGPoint)point
{
    CGPoint center = CGPointMake(_radius, _radius);
    
    float angle = atan2(point.x - center.x, point.y - center.y) + M_PI;
    float dist = ISColorWheel_PointDistance(point, CGPointMake(center.x, center.y));
        
    float hue = angle / (M_PI * 2.0f);
    
    hue = MIN(hue, 1.0f - .0000001f);
    hue = MAX(hue, 0.0f);
    
    float sat = dist / (_radius);
    
    sat = MIN(sat, 1.0f);
    sat = MAX(sat, 0.0f);
    
    return ISColorWheel_HSBToRGB(hue, sat, self.brightness);
}

- (CGPoint)viewToImageSpace:(CGPoint)point
{    
    float width = CGRectGetWidth(self.bounds);
    float height = CGRectGetHeight(self.bounds);
    
    point.y = height - point.y;
        
    CGPoint min = CGPointMake(width / 2.0 - _radius, height / 2.0 - _radius);
    
    point.x = point.x - min.x;
    point.y = point.y - min.y;
    
    return point;
}

- (void)updateKnob
{
    if (!self.knobView)
    {
        return;
    }
    
    self.knobView.bounds = CGRectMake(0, 0, self.knobSize.width, self.knobSize.height);
    self.knobView.center = _touchPoint;
}

- (void)updateImage
{
    if (CGRectGetWidth(self.bounds) == 0 || CGRectGetHeight(self.bounds) == 0)
    {
        return;
    }
    
    if (_radialImage)
    {
        CGImageRelease(_radialImage);
        _radialImage = nil;
    }
    
    int width = _radius * 2.0;
    int height = _radius * 2.0;
    
    int dataLength = sizeof(PixelRGB) * width * height;
    
    if (dataLength != _imageDataLength)
    {
        if (_imageData)
        {
            free(_imageData);
        }
        _imageData = malloc(dataLength);
        
        _imageDataLength = dataLength;
    }
    
    for (int y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++)
        {
            _imageData[x + y * width] = [self colorAtPoint:CGPointMake(x, y)];
        }
    }
    
    CGBitmapInfo bitInfo = kCGBitmapByteOrderDefault;
    
	CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, _imageData, dataLength, NULL);
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
	_radialImage = CGImageCreate(width,
                                    height,
                                    8,
                                    24,
                                    width * 3,
                                    colorspace,
                                    bitInfo,
                                    ref,
                                    NULL,
                                    true,
                                    kCGRenderingIntentDefault);
        
    CGColorSpaceRelease(colorspace);
    CGDataProviderRelease(ref);
    
    [self setNeedsDisplay];
}

- (UIColor*)currentColor
{
    PixelRGB pixel = [self colorAtPoint:[self viewToImageSpace:_touchPoint]];    
    return [UIColor colorWithRed:pixel.r / 255.0f green:pixel.g / 255.0f blue:pixel.b / 255.0f alpha:1.0];
}

- (void)setCurrentColor:(UIColor*)color
{
    float h = 0.0;
    float s = 0.0;
    float b = 1.0;
    float a = 1.0;
    
    [color getHue:&h saturation:&s brightness:&b alpha:&a];
    
    self.brightness = b;
    
    CGPoint center = CGPointMake(_radius, _radius);
    
    float angle = (h * (M_PI * 2.0)) + M_PI / 2;
    float dist = s * _radius;
        
    CGPoint point;
    point.x = center.x + (cosf(angle) * dist);
    point.y = center.y + (sinf(angle) * dist);
    
    [self setTouchPoint: point];
    [self updateImage];
}

- (void)setKnobView:(UIView *)knobView
{
    if (_knobView)
    {
        [_knobView removeFromSuperview];
    }
    
    _knobView = knobView;
    
    if (_knobView)
    {
        [self addSubview:_knobView];
    }
    
    [self updateKnob];
}

- (void)drawRect:(CGRect)rect
{
    int width = CGRectGetWidth(self.bounds);
    int height = CGRectGetHeight(self.bounds);
    
    CGPoint center = CGPointMake(width / 2.0, height / 2.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState (ctx);
    
    CGContextAddEllipseInRect(ctx, CGRectMake(center.x - _radius, center.y - _radius, _radius * 2.0, _radius * 2.0));
    CGContextClip(ctx);
    
    if (_radialImage)
    {
        CGContextDrawImage(ctx, CGRectMake(center.x - _radius, center.y - _radius, _radius * 2.0, _radius * 2.0), _radialImage);
    }
    
    CGContextSetLineWidth(ctx, 2.0);
    CGContextSetStrokeColorWithColor(ctx, [[UIColor blackColor] CGColor]);
    CGContextAddEllipseInRect(ctx, CGRectMake(center.x - _radius, center.y - _radius, _radius * 2.0, _radius * 2.0));
    CGContextStrokePath(ctx);

    CGContextRestoreGState (ctx);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _radius = (MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) / 2.0) - 1.0;
    [self updateImage];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setTouchPoint:[[touches anyObject] locationInView:self]];
    
    [self.delegate colorWheelDidChangeColor:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setTouchPoint:[[touches anyObject] locationInView:self]];
    
    if (self.continuous)
    {
        [self.delegate colorWheelDidChangeColor:self];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.delegate colorWheelDidChangeColor:self];
}

- (void)setTouchPoint:(CGPoint)point
{
    float width = CGRectGetWidth(self.bounds);
    float height = CGRectGetHeight(self.bounds);
    
    CGPoint center = CGPointMake(width / 2.0, height / 2.0);
    
    // Check if the touch is outside the wheel
    if (ISColorWheel_PointDistance(center, point) < _radius)
    {
        _touchPoint = point;
    }
    else
    {
        // If so we need to create a drection vector and calculate the constrained point
        CGPoint vec = CGPointMake(point.x - center.x, point.y - center.y);
        
        float extents = sqrtf((vec.x * vec.x) + (vec.y * vec.y));
        
        vec.x /= extents;
        vec.y /= extents;
        
        _touchPoint = CGPointMake(center.x + vec.x * _radius, center.y + vec.y * _radius);
    }
    
    [self updateKnob];
}

@end
