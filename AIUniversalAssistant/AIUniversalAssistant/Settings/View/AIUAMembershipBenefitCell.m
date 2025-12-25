//
//  AIUAMembershipBenefitCell.m
//  AIUniversalAssistant
//
//  Created by AI Assistant on 2025/11/4.
//

#import "AIUAMembershipBenefitCell.h"
#import <Masonry/Masonry.h>

@interface AIUAMembershipBenefitCell ()

@property (nonatomic, strong) UIView *iconBgView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;

@end

@implementation AIUAMembershipBenefitCell

- (void)setupUI {
    [super setupUI];
    
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    // 图标背景（适配暗黑模式）
    self.iconBgView = [[UIView alloc] init];
    // 使用动态颜色，适配暗黑模式
    self.iconBgView.backgroundColor = AIUA_DynamicColor(
        AIUAUIColorRGB(219, 234, 254),  // 浅色模式：浅蓝色
        AIUAUIColorRGB(30, 58, 138)      // 暗黑模式：深蓝色
    );
    self.iconBgView.layer.cornerRadius = 20;
    self.iconBgView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.iconBgView];
    
    // 图标（适配暗黑模式）
    self.iconView = [[UIImageView alloc] init];
    self.iconView.tintColor = AIUA_DynamicColor(
        AIUAUIColorRGB(59, 130, 246),   // 浅色模式：蓝色
        AIUAUIColorRGB(147, 197, 253)   // 暗黑模式：浅蓝色
    );
    [self.iconBgView addSubview:self.iconView];
    
    // 标题（适配暗黑模式）
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = AIUAUIFontBold(16);
    self.titleLabel.textColor = AIUA_LABEL_COLOR; // 使用系统标签颜色，自动适配暗黑模式
    [self.contentView addSubview:self.titleLabel];
    
    // 描述（适配暗黑模式）
    self.descLabel = [[UILabel alloc] init];
    self.descLabel.font = AIUAUIFontSystem(13);
    self.descLabel.textColor = AIUA_SECONDARY_LABEL_COLOR; // 使用系统二级标签颜色，自动适配暗黑模式
    self.descLabel.numberOfLines = 0;
    [self.contentView addSubview:self.descLabel];
    
    // 布局
    [self.iconBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(20);
        make.centerY.equalTo(self.contentView);
        make.width.height.equalTo(@40);
    }];
    
    [self.iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.iconBgView);
        make.width.height.equalTo(@20);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.iconBgView.mas_right).offset(12);
        make.top.equalTo(self.contentView).offset(14);
        make.right.equalTo(self.contentView).offset(-20);
    }];
    
    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleLabel);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(4);
        make.right.equalTo(self.contentView).offset(-20);
    }];
}

- (void)configureWithIcon:(NSString *)iconName title:(NSString *)title desc:(NSString *)desc {
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightMedium];
    UIImage *icon = [UIImage systemImageNamed:iconName withConfiguration:config];
    self.iconView.image = icon;
    self.titleLabel.text = title;
    self.descLabel.text = desc;
}

@end

