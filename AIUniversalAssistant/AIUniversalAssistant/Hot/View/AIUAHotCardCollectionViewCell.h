#import <UIKit/UIKit.h>
#import "AIUASuperCollectionViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface AIUAHotCardCollectionViewCell : AIUASuperCollectionViewCell

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView *gradientView;

- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle iconName:(NSString *)iconName;

@end

NS_ASSUME_NONNULL_END
