//
//  AIUASuperViewController.h
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/3/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AIUASuperViewController : UIViewController

- (void)setupUI;

- (void)setupData;

// 返回按钮点击事件
- (void)backButtonTapped;

@end

NS_ASSUME_NONNULL_END
