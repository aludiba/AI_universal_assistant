//
//  AIUAWritingInputCell.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/6/25.
//

#import "AIUAWritingInputCell.h"
#import "UITextView+AIUAPlaceholder.h"

@interface AIUAWritingInputCell() <UITextViewDelegate>

@end

@implementation AIUAWritingInputCell

- (void)setupUI {
    [super setupUI];
    // 输入框
    self.textView = [[UITextView alloc] init];
    self.textView.backgroundColor = AIUA_BACK_COLOR;
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.delegate = self;
    self.textView.font = AIUAUIFontSystem(16);
    self.textView.layer.borderWidth = 1.0;
    self.textView.layer.borderColor = AIUAUIColorSimplifyRGB(0.9, 0.9, 0.9).CGColor;
    self.textView.layer.cornerRadius = 8.0;
    self.textView.textContainerInset = UIEdgeInsetsMake(12, 12, 12, 40); // 右侧留出空间给清空按钮
    self.textView.placeholder = L(@"please_enter");
    [self.contentView addSubview:self.textView];
    
    // 清空按钮 - 使用系统图标
    self.clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    // 使用系统图标
    UIImage *clearImage = [UIImage systemImageNamed:@"xmark.circle.fill"];
    [self.clearButton setImage:clearImage forState:UIControlStateNormal];
    [self.clearButton setTintColor:AIUA_GRAY_COLOR];
    self.clearButton.backgroundColor = [UIColor clearColor];
    [self.clearButton addTarget:self action:@selector(clearButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.clearButton.hidden = YES;
    [self.contentView addSubview:self.clearButton];
    
    // 开始创作按钮
    self.createButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.createButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.createButton setTitle:L(@"start_creating") forState:UIControlStateNormal];
    [self.createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.createButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    self.createButton.backgroundColor = AIUAUIColorSimplifyRGB(0.8, 0.8, 0.8);
    self.createButton.layer.cornerRadius = 8.0;
    [self.createButton addTarget:self action:@selector(createButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.createButton.enabled = NO;
    [self.contentView addSubview:self.createButton];
    
    [self setupConstraints];
}

- (void)setupConstraints {
    [NSLayoutConstraint activateConstraints:@[
        // 输入框约束
        [self.textView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16],
        [self.textView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.textView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        
        // 清空按钮约束 - 在textView内部右上角
        [self.clearButton.widthAnchor constraintEqualToConstant:22],
        [self.clearButton.heightAnchor constraintEqualToConstant:22],
        [self.clearButton.bottomAnchor constraintEqualToAnchor:self.textView.bottomAnchor constant:-8],
        [self.clearButton.trailingAnchor constraintEqualToAnchor:self.textView.trailingAnchor constant:-8],
        
        // 开始创作按钮约束
        [self.createButton.topAnchor constraintEqualToAnchor:self.textView.bottomAnchor constant:16],
        [self.createButton.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.createButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.createButton.heightAnchor constraintEqualToConstant:44],
        [self.createButton.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-16]
    ]];
}

- (void)updateButtonStates {
    BOOL hasText = self.textView.text.length > 0;
    // 显示/隐藏清空按钮
    self.clearButton.hidden = !hasText;
    // 更新开始创作按钮状态
    self.createButton.enabled = hasText;
    self.createButton.backgroundColor = hasText ?
    AIUAUIColorSimplifyRGB(0.2, 0.4, 0.8) :
    AIUAUIColorSimplifyRGB(0.8, 0.8, 0.8);
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [self updateButtonStates];
    if (self.onTextChange) {
        self.onTextChange(textView.text);
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    // 开始编辑时显示清空按钮（如果有文字）
    if (textView.text.length > 0) {
        self.clearButton.hidden = NO;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    // 结束编辑时隐藏清空按钮
    self.clearButton.hidden = YES;
}

#pragma mark - Button Actions

- (void)clearButtonTapped {
    self.textView.text = @"";
    [self updateButtonStates];
    // 确保清空后隐藏按钮
    self.clearButton.hidden = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self.textView];
    if (self.onClearText) {
        self.onClearText();
    }
}

- (void)createButtonTapped {
    if (self.textView.text.length > 0 && self.onStartCreate) {
        self.onStartCreate();
    }
}

@end
