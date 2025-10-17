// AIUACreateDocumentCell.m
#import "AIUACreateDocumentCell.h"

@interface AIUACreateDocumentCell ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation AIUACreateDocumentCell

- (void)setupUI {
    [super setupUI];
    
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    // 容器视图
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor whiteColor];
    self.containerView.layer.cornerRadius = 12;
    self.containerView.layer.masksToBounds = YES;
    self.containerView.layer.borderWidth = 1;
    self.containerView.layer.borderColor = AIUAUIColorRGB(229, 231, 235).CGColor;
    [self.contentView addSubview:self.containerView];
    
    // 图标
    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.image = [UIImage systemImageNamed:@"plus"];
    self.iconImageView.tintColor = AIUAUIColorRGB(157, 161, 167);
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.containerView addSubview:self.iconImageView];
    
    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = L(@"new_document");
    self.titleLabel.font = AIUAUIFontSystem(16);
    self.titleLabel.textColor = AIUAUIColorRGB(162, 166, 177);
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.containerView addSubview:self.titleLabel];
    
    [self setupConstraints];
}

- (void)setupConstraints {
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // 容器视图
        [self.containerView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8],
        [self.containerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.containerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.containerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8],
        [self.containerView.heightAnchor constraintEqualToConstant:120], // 增加高度以容纳上下布局
        
        // 图标 - 居中显示
        [self.iconImageView.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [self.iconImageView.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor constant:-15], // 向上偏移15点
        [self.iconImageView.widthAnchor constraintEqualToConstant:32], // 稍微增大图标
        [self.iconImageView.heightAnchor constraintEqualToConstant:32],
        
        // 标题 - 在图标下方
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.iconImageView.bottomAnchor constant:8],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [self.titleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.containerView.trailingAnchor constant:-20]
    ]];
}

@end
