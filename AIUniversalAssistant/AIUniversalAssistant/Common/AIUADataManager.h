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

#pragma mark - 热门

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

#pragma mark - 搜索

// 搜索模块加载所有类别数据
- (NSArray *)loadSearchCategoriesData;
// 搜索模块加载历史搜索数据
- (NSArray *)loadSearchHistorySearches;
// 搜索模块保存搜索记录
- (void)saveHistorySearches:(NSArray *)datas;
// 判断是否为收藏分类
- (BOOL)isFavoriteCategory:(NSDictionary *)category;

#pragma mark - 写作

// 获取“写作”数据
- (NSArray *)loadWritingCategories;
// 获取“写作”分类数据
- (NSArray *)getItemsForCategory:(NSString *)categoryId;

#pragma mark - 写作

// 保存写作详情到plist文件
- (void)saveWritingToPlist:(NSDictionary *)writingRecord;
- (NSArray *)loadAllWritings;
// 根据类型加载写作记录
- (NSArray *)loadWritingsByType:(NSString *)type;
// 根据ID删除写作记录
- (BOOL)deleteWritingWithID:(NSString *)writingID;

#pragma mark - 提示词处理
- (NSString *)extractRequirementFromPrompt:(NSString *)prompt;
- (NSString *)extractReasonablePartFromPrompt:(NSString *)prompt;
- (NSString *)truncateRequirementIfNeeded:(NSString *)requirement;
- (NSString *)extractThemeFromPrompt:(NSString *)prompt;

#pragma mark - 辅助方法
- (NSString *)getItemId:(NSDictionary *)item;
- (NSString *)generateUniqueID;
- (NSString *)currentTimeString;
// 获取plist文件路径
- (NSString *)getPlistFilePath:(NSString *)fileName;
- (NSString *)currentDateString;
- (void)exportDocument:(NSString *)title withContent:(NSString *)content;
@end

NS_ASSUME_NONNULL_END
