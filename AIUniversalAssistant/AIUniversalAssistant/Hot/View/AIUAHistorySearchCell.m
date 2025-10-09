//
//  AIUAHistorySearchCell.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/9/25.
//

#import "AIUAHistorySearchCell.h"

@implementation AIUAHistorySearchCell

- (void)setupUI {
    [super setupUI];
    
    self.contentView.backgroundColor = [UIColor whiteColor];
    
    // 历史搜索图标
    self.historyIcon = [[UIImageView alloc] init];
    self.historyIcon.image = [UIImage systemImageNamed:@"clock"];
    self.historyIcon.tintColor = [UIColor grayColor];
    self.historyIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.historyIcon];
    
    // 标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:16];
    self.titleLabel.textColor = [UIColor darkTextColor];
    [self.contentView addSubview:self.titleLabel];
    
    // 分隔线
    self.separatorView = [[UIView alloc] init];
    self.separatorView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    [self.contentView addSubview:self.separatorView];
    
    // 设置约束
    [self setupConstraints];
}

- (void)setupConstraints {
    self.historyIcon.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.separatorView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // 历史图标约束
        [self.historyIcon.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.historyIcon.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.historyIcon.widthAnchor constraintEqualToConstant:20],
        [self.historyIcon.heightAnchor constraintEqualToConstant:20],
        
        // 标题约束
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.historyIcon.trailingAnchor constant:12],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        
        // 分隔线约束
        [self.separatorView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.separatorView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.separatorView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        [self.separatorView.heightAnchor constraintEqualToConstant:0.5]
    ]];
}
@end
