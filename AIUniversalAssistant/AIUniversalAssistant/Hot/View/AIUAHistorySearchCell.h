//
//  AIUAHistorySearchCell.h
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/9/25.
//

#import "AIUASuperTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface AIUAHistorySearchCell : AIUASuperTableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *historyIcon;
@property (nonatomic, strong) UIView *separatorView;

@end

NS_ASSUME_NONNULL_END
