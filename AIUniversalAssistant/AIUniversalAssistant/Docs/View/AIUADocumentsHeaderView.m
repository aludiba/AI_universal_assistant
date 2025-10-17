// AIUADocumentsHeaderView.m
#import "AIUADocumentsHeaderView.h"

@implementation AIUADocumentsHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.contentView.backgroundColor = AIUA_BACK_COLOR;
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = AIUAUIFontBold(20);
    self.titleLabel.textColor = AIUAUIColorRGB(34, 34, 34);
    [self.contentView addSubview:self.titleLabel];
    
    [self setupConstraints];
}

- (void)setupConstraints {
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8]
    ]];
}

@end