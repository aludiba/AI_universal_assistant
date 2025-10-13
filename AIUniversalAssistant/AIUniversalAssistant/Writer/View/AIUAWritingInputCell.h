//
//  AIUAWritingInputCell.h
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/6/25.
//

#import <UIKit/UIKit.h>
#import "AIUASuperTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

// 输入框Cell
@interface AIUAWritingInputCell : AIUASuperTableViewCell

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UIButton *createButton;
@property (nonatomic, copy) void (^onTextChange)(NSString *text);
@property (nonatomic, copy) void (^onClearText)(void);
@property (nonatomic, copy) void (^onStartCreate)(NSString *text);

- (void)updateButtonStates;

@end

NS_ASSUME_NONNULL_END
