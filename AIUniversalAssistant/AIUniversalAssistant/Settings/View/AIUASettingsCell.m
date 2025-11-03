//
//  AIUASettingsCell.m
//  AIUniversalAssistant
//
//  Created by AI Assistant on 2025/11/3.
//

#import "AIUASettingsCell.h"
#import <Masonry/Masonry.h>

@interface AIUASettingsCell ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;

@end

@implementation AIUASettingsCell

- (void)setupUI {
    [super setupUI];
    
    self.backgroundColor = [UIColor clearColor];
    
    // 容器视图
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor whiteColor];
    self.containerView.layer.cornerRadius = 12;
    self.containerView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.containerView];
    
    // 图标
    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.contentMode = UIViewContentModeCenter;
    self.iconImageView.layer.cornerRadius = 8;
    self.iconImageView.layer.masksToBounds = YES;
    [self.containerView addSubview:self.iconImageView];
    
    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = AIUAUIFontSystem(16);
    self.titleLabel.textColor = AIUAUIColorRGB(31, 35, 41);
    [self.containerView addSubview:self.titleLabel];
    
    // 副标题
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.font = AIUAUIFontSystem(13);
    self.subtitleLabel.textColor = AIUAUIColorRGB(156, 163, 175);
    [self.containerView addSubview:self.subtitleLabel];
    
    // 箭头
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:12
                                                                                         weight:UIImageSymbolWeightMedium];
    UIImage *arrowImage = [UIImage systemImageNamed:@"chevron.right" withConfiguration:config];
    self.arrowImageView = [[UIImageView alloc] initWithImage:arrowImage];
    self.arrowImageView.tintColor = AIUAUIColorRGB(209, 213, 219);
    [self.containerView addSubview:self.arrowImageView];
    
    [self setupConstraints];
}

- (void)setupConstraints {
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(6);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.bottom.equalTo(self.contentView).offset(-6);
        make.height.greaterThanOrEqualTo(@60);
    }];
    
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.containerView).offset(16);
        make.centerY.equalTo(self.containerView);
        make.width.height.equalTo(@36);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.iconImageView.mas_right).offset(12);
        make.centerY.equalTo(self.containerView);
    }];
    
    [self.arrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.containerView).offset(-16);
        make.centerY.equalTo(self.containerView);
        make.width.equalTo(@12);
        make.height.equalTo(@16);
    }];
    
    [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.arrowImageView.mas_left).offset(-8);
        make.centerY.equalTo(self.containerView);
    }];
}

- (void)configureWithIcon:(UIImage *)icon
                    title:(NSString *)title
                 subtitle:(nullable NSString *)subtitle {
    self.iconImageView.image = icon;
    self.titleLabel.text = title;
    self.subtitleLabel.text = subtitle;
    self.subtitleLabel.hidden = (subtitle == nil || subtitle.length == 0);
}

@end

