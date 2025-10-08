#import <UIKit/UIKit.h>
#import "AIUASuperCollectionViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@class AIUAHotCardCollectionViewCell;

@protocol AIUAHotCardCollectionViewCellDelegate <NSObject>

@optional
- (void)cell:(AIUAHotCardCollectionViewCell *)cell favoriteButtonTapped:(UIButton *)button;

@end

@interface AIUAHotCardCollectionViewCell : AIUASuperCollectionViewCell

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView *gradientView;
@property (nonatomic, strong) UIButton *favoriteButton;
@property (nonatomic, weak) id<AIUAHotCardCollectionViewCellDelegate> delegate;

- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle iconName:(NSString *)iconName;
- (void)setFavorite:(BOOL)isFavorite;
- (void)setFavoriteButtonHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
