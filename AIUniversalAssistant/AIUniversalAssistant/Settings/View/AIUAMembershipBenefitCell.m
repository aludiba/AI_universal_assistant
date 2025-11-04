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
    self.contentView.backgroundColor = [UIColor whiteColor];
    
    // 图标背景
    self.iconBgView = [[UIView alloc] init];
    self.iconBgView.backgroundColor = AIUAUIColorRGB(219, 234, 254);
    self.iconBgView.layer.cornerRadius = 20;
    self.iconBgView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.iconBgView];
    
    // 图标
    self.iconView = [[UIImageView alloc] init];
    self.iconView.tintColor = AIUAUIColorRGB(59, 130, 246);
    [self.iconBgView addSubview:self.iconView];
    
    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = AIUAUIFontBold(16);
    self.titleLabel.textColor = AIUAUIColorRGB(17, 24, 39);
    [self.contentView addSubview:self.titleLabel];
    
    // 描述
    self.descLabel = [[UILabel alloc] init];
    self.descLabel.font = AIUAUIFontSystem(13);
    self.descLabel.textColor = AIUAUIColorRGB(107, 114, 128);
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

