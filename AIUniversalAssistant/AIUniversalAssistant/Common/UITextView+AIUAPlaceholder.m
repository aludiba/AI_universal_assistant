//
//  UITextView+AIUAPlaceholder.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/6/25.
//

#import "UITextView+AIUAPlaceholder.h"
#import <objc/runtime.h>

@implementation UITextView (AIUAPlaceholder)

static const void *placeholderKey = &placeholderKey;
static const void *placeholderColorKey = &placeholderColorKey;
static const void *placeholderLabelKey = &placeholderLabelKey;

- (void)setPlaceholder:(NSString *)placeholder {
    objc_setAssociatedObject(self, placeholderKey, placeholder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self updatePlaceholder];
}

- (NSString *)placeholder {
    return objc_getAssociatedObject(self, placeholderKey);
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    objc_setAssociatedObject(self, placeholderColorKey, placeholderColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self updatePlaceholder];
}

- (UIColor *)placeholderColor {
    return objc_getAssociatedObject(self, placeholderColorKey) ?: [UIColor lightGrayColor];
}

- (UILabel *)placeholderLabel {
    UILabel *label = objc_getAssociatedObject(self, placeholderLabelKey);
    if (!label) {
        label = [[UILabel alloc] init];
        label.font = self.font;
        label.textColor = self.placeholderColor;
        label.numberOfLines = 0;
        label.hidden = (self.text.length > 0);
        
        [self addSubview:label];
        [self setPlaceholderLabel:label];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(updatePlaceholder)
                                                    name:UITextViewTextDidChangeNotification
                                                  object:self];
    }
    return label;
}

- (void)setPlaceholderLabel:(UILabel *)placeholderLabel {
    objc_setAssociatedObject(self, placeholderLabelKey, placeholderLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)updatePlaceholder {
    self.placeholderLabel.text = self.placeholder;
    self.placeholderLabel.font = self.font;
    self.placeholderLabel.textColor = self.placeholderColor;
    self.placeholderLabel.hidden = (self.text.length > 0);
    
    CGFloat lineFragmentPadding = self.textContainer.lineFragmentPadding;
    UIEdgeInsets textContainerInset = self.textContainerInset;
    
    CGFloat x = lineFragmentPadding + textContainerInset.left;
    CGFloat y = textContainerInset.top;
    
    // 使用完整宽度，避免文字挤压
    CGFloat maxWidth = self.bounds.size.width;
    if (maxWidth <= 0) {
        maxWidth = [UIScreen mainScreen].bounds.size.width;
    }
    CGFloat width = maxWidth - x - lineFragmentPadding - textContainerInset.right;
    
    // 确保宽度合理
    if (width < 100) {
        width = maxWidth - 20; // 最小留20的边距
    }
    
    CGFloat height = [self.placeholderLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height;
    
    self.placeholderLabel.frame = CGRectMake(x, y, width, height);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updatePlaceholder];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
