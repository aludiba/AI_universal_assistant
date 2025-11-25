//
//  AIUATextViewController.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 2025/11/24.
//

#import "AIUATextViewController.h"
#import <Masonry/Masonry.h>

@interface AIUATextViewController ()

@property (nonatomic, strong) UITextView *textView;

@end

@implementation AIUATextViewController

- (void)setText:(NSString *)text {
    _text = text;
    self.textView.text = text;
    // 确保文本视图滚动到顶部
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.textView setContentOffset:CGPointZero animated:NO];
    });
}

- (UITextView *)textView {
    if (!_textView) {
        UITextView *textView = [[UITextView alloc] init];
        textView.font = AIUAUIFontSystem(14);
        textView.textColor = AIUAUIColorRGB(75, 85, 99);
        textView.editable = NO;
        textView.textContainerInset = UIEdgeInsetsMake(16, 16, 16, 16);
        textView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
        [self.view addSubview:textView];
        
        [textView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            make.right.bottom.left.equalTo(self.view);
        }];
        _textView = textView;
    }
    return _textView;
}

@end
