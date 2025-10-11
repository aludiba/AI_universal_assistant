//
//  AIUADataManager.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/6/25.
//

#import "AIUADataManager.h"

@implementation AIUADataManager

+ (instancetype)sharedManager {
    static AIUADataManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

// “热门”模块数据
- (NSArray *)loadHotCategories {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"AIUAHotCategories" ofType:@"plist"];
    if (!path) {
        NSLog(@"AIUAHotCategories.plist 文件未找到");
        return @[];
    }
    
    NSArray *categories = [NSArray arrayWithContentsOfFile:path];
    if (!categories) {
        NSLog(@"无法解析 AIUAHotCategories.plist 文件");
        return @[];
    }
    
    return categories;
}

// 获取收藏文件路径
- (NSString *)favoritesFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    return [documentsDirectory stringByAppendingPathComponent:@"AIUAFavorites.plist"];
}

// 获取最近使用文件路径
- (NSString *)recentUsedFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    return [documentsDirectory stringByAppendingPathComponent:@"AIUARecentUsed.plist"];
}

#pragma mark - 收藏功能

- (NSArray *)loadFavorites {
    NSString *filePath = [self favoritesFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return [NSArray arrayWithContentsOfFile:filePath];
    }
    return @[];
}

- (void)addFavorite:(NSDictionary *)item {
    NSMutableArray *favorites = [[self loadFavorites] mutableCopy];
    
    // 检查是否已经收藏
    NSString *itemId = [self getItemId:item];
    for (NSDictionary *favItem in favorites) {
        if ([[self getItemId:favItem] isEqualToString:itemId]) {
            return; // 已经收藏，直接返回
        }
    }
    
    // 添加收藏时间
    NSMutableDictionary *itemWithTime = [item mutableCopy];
    [itemWithTime setObject:[NSDate date] forKey:@"favoriteDate"];
    
    [favorites insertObject:itemWithTime atIndex:0]; // 最新收藏放在最前面
    [favorites writeToFile:[self favoritesFilePath] atomically:YES];
}

- (void)removeFavorite:(NSString *)itemId {
    NSMutableArray *favorites = [[self loadFavorites] mutableCopy];
    NSMutableArray *itemsToRemove = [NSMutableArray array];
    
    for (NSDictionary *item in favorites) {
        if ([[self getItemId:item] isEqualToString:itemId]) {
            [itemsToRemove addObject:item];
        }
    }
    
    [favorites removeObjectsInArray:itemsToRemove];
    [favorites writeToFile:[self favoritesFilePath] atomically:YES];
}

- (BOOL)isFavorite:(NSString *)itemId {
    NSArray *favorites = [self loadFavorites];
    for (NSDictionary *item in favorites) {
        if ([[self getItemId:item] isEqualToString:itemId]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - 最近使用功能

- (NSArray *)loadRecentUsed {
    NSString *filePath = [self recentUsedFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return [NSArray arrayWithContentsOfFile:filePath];
    }
    return @[];
}

- (void)addRecentUsed:(NSDictionary *)item {
    NSMutableArray *recentUsed = [[self loadRecentUsed] mutableCopy];
    
    // 检查是否已经存在
    NSString *itemId = [self getItemId:item];
    NSMutableArray *itemsToRemove = [NSMutableArray array];
    for (NSDictionary *recentItem in recentUsed) {
        if ([[self getItemId:recentItem] isEqualToString:itemId]) {
            [itemsToRemove addObject:recentItem];
        }
    }
    [recentUsed removeObjectsInArray:itemsToRemove];
    
    // 添加使用时间
    NSMutableDictionary *itemWithTime = [item mutableCopy];
    [itemWithTime setObject:[NSDate date] forKey:@"usedDate"];
    
    [recentUsed insertObject:itemWithTime atIndex:0]; // 最新使用的放在最前面
    
    // 限制最近使用数量为20个
    if (recentUsed.count > 20) {
        recentUsed = [[recentUsed subarrayWithRange:NSMakeRange(0, 20)] mutableCopy];
    }
    
    [recentUsed writeToFile:[self recentUsedFilePath] atomically:YES];
}

- (void)clearRecentUsed {
    [[NSArray array] writeToFile:[self recentUsedFilePath] atomically:YES];
}

#pragma mark - 搜索
- (NSArray *)loadSearchCategoriesData {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"AIUAHotCategories" ofType:@"plist"];
    NSArray *categoriesArray = [NSArray arrayWithContentsOfFile:path];
    
    NSMutableArray *allItems = [NSMutableArray array];
    for (NSDictionary *category in categoriesArray) {
        NSArray *items = category[@"items"];
        for (NSDictionary *item in items) {
            [allItems addObject:item];
        }
    }
    
    if (allItems.count > 0) {
        return allItems;
    }
    return @[];
}

- (NSArray *)loadSearchHistorySearches {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *historyPath = [documentsPath stringByAppendingPathComponent:@"SearchHistory.plist"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:historyPath]) {
        NSArray *history = [NSArray arrayWithContentsOfFile:historyPath];
        return history;
    }
    return @[];
}

- (void)saveHistorySearches:(NSArray *)datas {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *historyPath = [documentsPath stringByAppendingPathComponent:@"SearchHistory.plist"];
    
    [datas writeToFile:historyPath atomically:YES];
}
#pragma mark - 辅助方法

- (NSString *)getItemId:(NSDictionary *)item {
    // 使用 type + title 作为唯一标识
    NSString *type = item[@"type"] ?: @"";
    NSString *title = item[@"title"] ?: @"";
    return [NSString stringWithFormat:@"%@_%@", type, title];
}

- (BOOL)isFavoriteCategory:(NSDictionary *)category {
    return [category[@"isFavoriteCategory"] boolValue];
}

- (NSArray *)loadWritingCategories {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"AIUAWritingCategories" ofType:@"plist"];
    if (!path) {
        NSLog(@"AIUAWritingCategories.plist 文件未找到");
        return @[];
    }
    
    NSArray *categories = [NSArray arrayWithContentsOfFile:path];
    if (!categories) {
        NSLog(@"无法解析 AIUAWritingCategories.plist 文件");
        return @[];
    }
    
    return categories;
}

- (NSArray *)getItemsForCategory:(NSString *)categoryId {
    NSArray *categories = [self loadHotCategories];
    for (NSDictionary *category in categories) {
        if ([category[@"id"] isEqualToString:categoryId]) {
            return category[@"items"] ?: @[];
        }
    }
    return @[];
}

@end
