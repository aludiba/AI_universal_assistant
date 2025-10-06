//
//  UITextView+AIUAPlaceholder.h
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/6/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITextView (AIUAPlaceholder)

@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic, strong) UIColor *placeholderColor;

@end

NS_ASSUME_NONNULL_END
