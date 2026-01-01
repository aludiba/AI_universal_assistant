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
    
    self.contentView.backgroundColor = AIUA_CARD_BACKGROUND_COLOR; // 使用系统卡片背景色，自动适配暗黑模式
    
    // 渐变背景视图
    self.gradientView = [[UIView alloc] init];
    self.gradientView.translatesAutoresizingMaskIntoConstraints = NO;
    self.gradientView.layer.cornerRadius = 12;
    self.gradientView.backgroundColor = [self randomGradientColor];
    [self.contentView addSubview:self.gradientView];
    
    // 图标
    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconImageView.tintColor = [UIColor whiteColor];
    [self.gradientView addSubview:self.iconImageView];
    
    // 标题标签（适配暗黑模式）
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = AIUAUIFontMedium(16);
    self.titleLabel.textColor = AIUA_LABEL_COLOR; // 使用系统标签颜色，自动适配暗黑模式
    [self.contentView addSubview:self.titleLabel];
    
    // 副标题标签（适配暗黑模式）
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.font = AIUAUIFontSystem(13);
    self.subtitleLabel.textColor = AIUA_SECONDARY_LABEL_COLOR; // 使用系统二级标签颜色，自动适配暗黑模式
    self.subtitleLabel.numberOfLines = 1;
    [self.contentView addSubview:self.subtitleLabel];
    
    // 分隔线
    self.separatorView = [[UIView alloc] init];
    self.separatorView.backgroundColor = AIUA_DIVIDER_COLOR;
    [self.contentView addSubview:self.separatorView];
    
    // 设置约束
    [self setupConstraints];
}

- (void)setupConstraints {
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.separatorView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // 渐变背景视图约束
        [self.gradientView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.gradientView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.gradientView.widthAnchor constraintEqualToConstant:40],
        [self.gradientView.heightAnchor constraintEqualToConstant:40],
        
        // 图标约束
        [self.iconImageView.centerXAnchor constraintEqualToAnchor:self.gradientView.centerXAnchor],
        [self.iconImageView.centerYAnchor constraintEqualToAnchor:self.gradientView.centerYAnchor],
        [self.iconImageView.widthAnchor constraintEqualToConstant:24],
        [self.iconImageView.heightAnchor constraintEqualToConstant:24],
        
        // 标题约束
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.gradientView.trailingAnchor constant:12],
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

- (UIColor *)randomGradientColor {
    NSArray *colors = @[
        AIUA_BLUE_COLOR,   // 蓝色
        AIUAUIColorSimplifyRGB(0.8, 0.4, 0.2),   // 橙色
        AIUAUIColorSimplifyRGB(0.4, 0.6, 0.2),   // 绿色
        AIUAUIColorSimplifyRGB(0.8, 0.2, 0.4),   // 粉色
        AIUAUIColorSimplifyRGB(0.6, 0.2, 0.8),   // 紫色
        AIUAUIColorSimplifyRGB(0.2, 0.6, 0.6)    // 青色
    ];
    return colors[arc4random_uniform((uint32_t)colors.count)];
}

@end
