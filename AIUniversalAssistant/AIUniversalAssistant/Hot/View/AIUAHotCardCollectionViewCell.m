//
//  AIUAHotCardCollectionViewCell.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/3/25.
//

#import "AIUAHotCardCollectionViewCell.h"

@implementation AIUAHotCardCollectionViewCell


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
        self.contentView.layer.cornerRadius = 10;
        self.contentView.layer.masksToBounds = YES;
        
        // icon
        _iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _iconView.translatesAutoresizingMaskIntoConstraints = NO;
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_iconView];
        
        // title
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = AIUAUIFontBold(16);
        [self.contentView addSubview:_titleLabel];
        
        // subtitle
        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _subtitleLabel.font = AIUAUIFontSystem(12);
        _subtitleLabel.textColor = [UIColor darkGrayColor];
        [self.contentView addSubview:_subtitleLabel];
        
        // constraints
        [NSLayoutConstraint activateConstraints:@[
            [_iconView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:12],
            [_iconView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
            [_iconView.widthAnchor constraintEqualToConstant:28],
            [_iconView.heightAnchor constraintEqualToConstant:28],
            
            [_titleLabel.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:10],
            [_titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12],
            [_titleLabel.centerYAnchor constraintEqualToAnchor:_iconView.centerYAnchor],
            
            [_subtitleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:12],
            [_subtitleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12],
            [_subtitleLabel.topAnchor constraintEqualToAnchor:_iconView.bottomAnchor constant:12],
        ]];
    }
    return self;
}

@end
