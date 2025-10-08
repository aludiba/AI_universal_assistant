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
// 获取“热门”数据
- (NSArray *)loadHotCategories;
// 收藏功能
- (NSArray *)loadFavorites;
- (void)addFavorite:(NSDictionary *)item;
- (void)removeFavorite:(NSString *)itemId;
- (BOOL)isFavorite:(NSString *)itemId;
// 最近使用功能
- (NSArray *)loadRecentUsed;
- (void)addRecentUsed:(NSDictionary *)item;
- (void)clearRecentUsed;
- (NSString *)getItemId:(NSDictionary *)item;
// 判断是否为收藏分类
- (BOOL)isFavoriteCategory:(NSDictionary *)category;

// 获取“写作”数据
- (NSArray *)loadWritingCategories;
// 获取“写作”分类数据
- (NSArray *)getItemsForCategory:(NSString *)categoryId;

@end

NS_ASSUME_NONNULL_END
