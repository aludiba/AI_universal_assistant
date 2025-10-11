//
//  AIUAWritingCategoryCell.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/6/25.
//

#import "AIUAWritingCategoryCell.h"

@interface AIUAWritingCategoryCell()

@end

@implementation AIUAWritingCategoryCell

- (void)setupUI {
    [super setupUI];
    // 使用系统向上箭头图标
    UIImage *chevronUpImage = [UIImage systemImageNamed:@"chevron.up"];
    UIImageView *accessoryView = [[UIImageView alloc] initWithImage:chevronUpImage];
    accessoryView.tintColor = AIUA_GRAY_COLOR;
    self.accessoryView = accessoryView;
    // 标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.font = AIUAUIFontBold(16);
    self.titleLabel.textColor = AIUA_BLUE_COLOR;
    self.titleLabel.numberOfLines = 1;
    [self.contentView addSubview:self.titleLabel];
    
    // 内容标签
    self.contentLabel = [[UILabel alloc] init];
    self.contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentLabel.font = AIUAUIFontSystem(14);
    self.contentLabel.textColor = [UIColor darkGrayColor];
    self.contentLabel.numberOfLines = 2;
    [self.contentView addSubview:self.contentLabel];
    
    [self setupConstraints];
    
    [self setupTapGesture];
}

- (void)setupConstraints {
    [NSLayoutConstraint activateConstraints:@[
        // 标题标签约束
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-30],
        
        // 内容标签约束
        [self.contentLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:6],
        [self.contentLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.contentLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-30],
        [self.contentLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-12]
    ]];
}

- (void)setupTapGesture {
    // 添加点击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [self.contentView addGestureRecognizer:tapGesture];
}

- (void)configureWithTitle:(NSString *)title content:(NSString *)content {
    self.titleLabel.text = title;
    self.contentLabel.text = content;
}

- (void)setTapBlock:(AIUACategoryCellTapBlock)tapBlock {
    _tapBlock = tapBlock;
}

#pragma mark - 点击处理方法

- (void)handleTap {
    // 构建完整文本
    NSString *fullText = [NSString stringWithFormat:@"%@：%@", self.titleLabel.text, self.contentLabel.text];    
    // 执行回调
    if (self.tapBlock) {
        self.tapBlock(fullText);
    }
}

@end
