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
    self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.titleLabel.numberOfLines = 0; // 多行展示，避免截断
    // 允许标题在水平方向被压缩
    [self.titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self.containerView addSubview:self.titleLabel];
    
    // 副标题
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.font = AIUAUIFontSystem(13);
    self.subtitleLabel.textColor = AIUAUIColorRGB(156, 163, 175);
    self.subtitleLabel.numberOfLines = 1;
    // 副标题优先完整展示
    [self.subtitleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.subtitleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
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
    
    [self.arrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.containerView).offset(-16);
        make.centerY.equalTo(self.containerView);
        make.width.equalTo(@12);
        make.height.equalTo(@16);
    }];
    
    // 默认有副标题的布局
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.containerView).offset(12);
        make.left.equalTo(self.iconImageView.mas_right).offset(12);
        make.right.lessThanOrEqualTo(self.arrowImageView.mas_left).offset(-16);
    }];
    
    [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(4);
        make.left.equalTo(self.titleLabel);
        make.right.lessThanOrEqualTo(self.arrowImageView.mas_left).offset(-16);
        make.bottom.lessThanOrEqualTo(self.containerView).offset(-12);
    }];
}

- (void)configureWithIcon:(UIImage *)icon
                    title:(NSString *)title
                 subtitle:(nullable NSString *)subtitle {
    self.iconImageView.image = icon;
    self.titleLabel.text = title;
    self.subtitleLabel.text = subtitle;
    BOOL hasSubtitle = !(subtitle == nil || subtitle.length == 0);
    self.subtitleLabel.hidden = !hasSubtitle;
    
    // 依据是否有副标题动态更新布局
    if (hasSubtitle) {
        // 标题顶端，副标题在下
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.containerView).offset(12);
            make.left.equalTo(self.iconImageView.mas_right).offset(12);
            make.right.lessThanOrEqualTo(self.arrowImageView.mas_left).offset(-16);
        }];
        [self.subtitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleLabel.mas_bottom).offset(4);
            make.left.equalTo(self.titleLabel);
            make.right.lessThanOrEqualTo(self.arrowImageView.mas_left).offset(-16);
            make.bottom.lessThanOrEqualTo(self.containerView).offset(-12);
        }];
    } else {
        // 无副标题：标题垂直居中
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.containerView);
            make.left.equalTo(self.iconImageView.mas_right).offset(12);
            make.right.lessThanOrEqualTo(self.arrowImageView.mas_left).offset(-16);
        }];
        // 收起副标题高度，避免占位
        [self.subtitleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@0);
            make.top.equalTo(self.titleLabel.mas_bottom);
            make.left.equalTo(self.titleLabel);
            make.right.lessThanOrEqualTo(self.arrowImageView.mas_left).offset(-16);
            make.bottom.lessThanOrEqualTo(self.containerView).offset(-12);
        }];
    }
}

@end

