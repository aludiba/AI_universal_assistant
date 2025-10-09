//
//  AIUASearchResultCell.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/9/25.
//

#import "AIUASearchResultCell.h"

@implementation AIUASearchResultCell

- (void)setupUI {
    [super setupUI];
    
    self.contentView.backgroundColor = [UIColor whiteColor];
    
    // 图标
    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconImageView.tintColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:1.0];
    [self.contentView addSubview:self.iconImageView];
    
    // 标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.titleLabel.textColor = [UIColor darkTextColor];
    [self.contentView addSubview:self.titleLabel];
    
    // 副标题标签
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.font = [UIFont systemFontOfSize:13];
    self.subtitleLabel.textColor = [UIColor grayColor];
    self.subtitleLabel.numberOfLines = 1;
    [self.contentView addSubview:self.subtitleLabel];
    
    // 分隔线
    self.separatorView = [[UIView alloc] init];
    self.separatorView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    [self.contentView addSubview:self.separatorView];
    
    // 设置约束
    [self setupConstraints];
}

- (void)setupConstraints {
    self.iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.separatorView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // 图标约束
        [self.iconImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.iconImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.iconImageView.widthAnchor constraintEqualToConstant:24],
        [self.iconImageView.heightAnchor constraintEqualToConstant:24],
        
        // 标题约束
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.iconImageView.trailingAnchor constant:12],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
        
        // 副标题约束
        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],
        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:4],
        [self.subtitleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-12],
        
        // 分隔线约束
        [self.separatorView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.separatorView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.separatorView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        [self.separatorView.heightAnchor constraintEqualToConstant:0.5]
    ]];
}

@end
