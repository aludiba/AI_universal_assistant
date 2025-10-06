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

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = AIUA_BACK_COLOR;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // 输入框
    self.textView = [[UITextView alloc] init];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.delegate = self;
    self.textView.font = [UIFont systemFontOfSize:16];
    self.textView.layer.borderWidth = 1.0;
    self.textView.layer.borderColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0].CGColor;
    self.textView.layer.cornerRadius = 8.0;
    self.textView.textContainerInset = UIEdgeInsetsMake(12, 12, 12, 12);
    self.textView.placeholder = @"请输入";
    [self.contentView addSubview:self.textView];
    
    // 清空按钮
    self.clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.clearButton setTitle:@"清空" forState:UIControlStateNormal];
    [self.clearButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [self.clearButton addTarget:self action:@selector(clearButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.clearButton.hidden = YES;
    [self.contentView addSubview:self.clearButton];
    
    // 开始创作按钮
    self.createButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.createButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.createButton setTitle:@"开始创作" forState:UIControlStateNormal];
    [self.createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.createButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    self.createButton.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
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
        [self.textView.heightAnchor constraintEqualToConstant:120],
        
        // 清空按钮约束
        [self.clearButton.topAnchor constraintEqualToAnchor:self.textView.bottomAnchor constant:8],
        [self.clearButton.trailingAnchor constraintEqualToAnchor:self.textView.trailingAnchor constant:-8],
        [self.clearButton.heightAnchor constraintEqualToConstant:30],
        
        // 开始创作按钮约束
        [self.createButton.topAnchor constraintEqualToAnchor:self.clearButton.bottomAnchor constant:16],
        [self.createButton.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.createButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.createButton.heightAnchor constraintEqualToConstant:44],
        [self.createButton.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-16]
    ]];
}

- (void)updateButtonStates {
    BOOL hasText = self.textView.text.length > 0;
    self.clearButton.hidden = !hasText;
    self.createButton.enabled = hasText;
    self.createButton.backgroundColor = hasText ?
        [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:1.0] :
        [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [self updateButtonStates];
    if (self.onTextChange) {
        self.onTextChange(textView.text);
    }
}

#pragma mark - Button Actions

- (void)clearButtonTapped {
    self.textView.text = @"";
    [self updateButtonStates];
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
