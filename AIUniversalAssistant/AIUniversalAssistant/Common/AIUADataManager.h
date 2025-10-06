//
//  AIUADataManager.h
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/6/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AIUADataManager : NSObject

+ (instancetype)sharedManager;
- (NSArray *)loadWritingCategories;

@end

NS_ASSUME_NONNULL_END
