#import "AIUAHotCardCollectionViewCell.h"

@implementation AIUAHotCardCollectionViewCell

- (void)setupUI {
    self.contentView.backgroundColor = [UIColor clearColor];
    
    // 卡片视图（适配暗黑模式）
    self.cardView = [[UIView alloc] init];
    self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardView.backgroundColor = AIUA_CARD_BACKGROUND_COLOR;
    self.cardView.layer.cornerRadius = 16;
    self.cardView.layer.shadowColor = AIUAUIColorSimplifyRGBA(0.0, 0.0, 0.0, 0.1).CGColor;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 2);
    self.cardView.layer.shadowRadius = 8;
    self.cardView.layer.shadowOpacity = 1;
    self.cardView.layer.masksToBounds = NO;
    [self.contentView addSubview:self.cardView];
    
    // 渐变背景视图
    self.gradientView = [[UIView alloc] init];
    self.gradientView.translatesAutoresizingMaskIntoConstraints = NO;
    self.gradientView.layer.cornerRadius = 12;
    self.gradientView.backgroundColor = [self randomGradientColor];
    [self.cardView addSubview:self.gradientView];
    
    // 图标
    self.iconView = [[UIImageView alloc] init];
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconView.tintColor = [UIColor whiteColor];
    [self.gradientView addSubview:self.iconView];
    
    // 标题（适配暗黑模式）
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.font = AIUAUIFontSemibold(16);
    self.titleLabel.textColor = AIUA_LABEL_COLOR;
    self.titleLabel.numberOfLines = 2;
    [self.cardView addSubview:self.titleLabel];
    
    // 副标题（适配暗黑模式）
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.font = AIUAUIFontSystem(12);
    self.subtitleLabel.textColor = AIUA_SECONDARY_LABEL_COLOR;
    self.subtitleLabel.numberOfLines = 3;
    [self.cardView addSubview:self.subtitleLabel];
    
    // 收藏按钮（适配暗黑模式）
    self.favoriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.favoriteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.favoriteButton addTarget:self action:@selector(favoriteButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.favoriteButton.backgroundColor = AIUA_CARD_BACKGROUND_COLOR;
    self.favoriteButton.layer.cornerRadius = 12;
    self.favoriteButton.layer.shadowColor = AIUAUIColorSimplifyRGBA(0.0, 0.0, 0.0, 0.1).CGColor;
    self.favoriteButton.layer.shadowOffset = CGSizeMake(0, 1);
    self.favoriteButton.layer.shadowRadius = 3;
    self.favoriteButton.layer.shadowOpacity = 1;
    [self.cardView addSubview:self.favoriteButton];
    
    [self setupConstraints];
}

- (void)setupConstraints {
    [NSLayoutConstraint activateConstraints:@[
        // 卡片视图
        [self.cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        
        // 渐变背景
        [self.gradientView.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:16],
        [self.gradientView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:16],
        [self.gradientView.widthAnchor constraintEqualToConstant:40],
        [self.gradientView.heightAnchor constraintEqualToConstant:40],
        
        // 图标
        [self.iconView.centerXAnchor constraintEqualToAnchor:self.gradientView.centerXAnchor],
        [self.iconView.centerYAnchor constraintEqualToAnchor:self.gradientView.centerYAnchor],
        [self.iconView.widthAnchor constraintEqualToConstant:20],
        [self.iconView.heightAnchor constraintEqualToConstant:20],
        
        // 标题
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.gradientView.topAnchor],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.gradientView.trailingAnchor constant:16],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-16],
        
        // 副标题
        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:4],
        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:self.gradientView.trailingAnchor constant:16],
        [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-16],
        
        // 收藏按钮
        [self.favoriteButton.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:16],
        [self.favoriteButton.widthAnchor constraintEqualToConstant:24],
        [self.favoriteButton.heightAnchor constraintEqualToConstant:24],
        [self.favoriteButton.bottomAnchor constraintLessThanOrEqualToAnchor:self.cardView.bottomAnchor constant:-16]
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

- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle iconName:(NSString *)iconName {
    self.titleLabel.text = title;
    self.subtitleLabel.text = subtitle;
    
    // 使用 SF Symbols
    UIImage *iconImage = [UIImage systemImageNamed:iconName];
    if (!iconImage) {
        // 如果系统图标不存在，使用默认图标
        iconImage = [UIImage systemImageNamed:@"doc.text"];
    }
    self.iconView.image = iconImage;
}

- (void)setFavorite:(BOOL)isFavorite {
    UIImage *heartImage = [UIImage systemImageNamed:isFavorite ? @"heart.fill" : @"heart"];
    [self.favoriteButton setImage:heartImage forState:UIControlStateNormal];
    self.favoriteButton.tintColor = isFavorite ? AIUAUIColorSimplifyRGB(1.0, 0.2, 0.2) : AIUAUIColorSimplifyRGB(0.6, 0.6, 0.6);
}

- (void)setFavoriteButtonHidden:(BOOL)hidden {
    self.favoriteButton.hidden = hidden;
}

- (void)favoriteButtonTapped {
    // 通过代理处理收藏事件
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:favoriteButtonTapped:)]) {
        [self.delegate cell:self favoriteButtonTapped:self.favoriteButton];
    }
}

@end
