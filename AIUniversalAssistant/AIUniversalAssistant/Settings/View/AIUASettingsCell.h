//
//  AIUASettingsCell.h
//  AIUniversalAssistant
//
//  Created by AI Assistant on 2025/11/3.
//

#import "AIUASuperTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface AIUASettingsCell : AIUASuperTableViewCell

- (void)configureWithIcon:(UIImage *)icon
                    title:(NSString *)title
                 subtitle:(nullable NSString *)subtitle;

@end

NS_ASSUME_NONNULL_END

