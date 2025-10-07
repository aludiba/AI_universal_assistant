//
//  UIVieW+AIUA.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/6/25.
//

#import "UIView+AIUA.h"

@implementation UIView(AIUA)

- (CGFloat)left { return self.frame.origin.x; }
- (CGFloat)right { return CGRectGetMaxX(self.frame); }
- (CGFloat)top { return self.frame.origin.y; }
- (CGFloat)bottom { return CGRectGetMaxY(self.frame); }
- (CGFloat)width { return self.frame.size.width; }
- (CGFloat)height { return self.frame.size.height; }
- (CGPoint)origin { return self.frame.origin; }
- (CGSize)size { return self.frame.size; }

@end
