//
//  AIUADataManager.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/6/25.
//

#import "AIUADataManager.h"
#import "AIUAMBProgressManager.h"

@implementation AIUADataManager

+ (instancetype)sharedManager {
    static AIUADataManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - 热门

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

- (BOOL)isFavoriteCategory:(NSDictionary *)category {
    return [category[@"isFavoriteCategory"] boolValue];
}

#pragma mark - 写作

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

#pragma mark - 写作详情

// 保存写作详情到plist文件
- (void)saveWritingToPlist:(NSDictionary *)writingRecord {
    NSLog(@"saveWritingToPlist-writingRecord:%@", writingRecord[@"content"]);
    // 获取沙盒Documents目录
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *plistPath = [documentsPath stringByAppendingPathComponent:@"AIUAWritings.plist"];
    
    // 读取现有的写作记录
    NSMutableArray *writingsArray = [NSMutableArray array];
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        NSArray *existingWritings = [NSArray arrayWithContentsOfFile:plistPath];
        if (existingWritings) {
            [writingsArray addObjectsFromArray:existingWritings];
        }
    }
    
    // 添加到数组开头（最新的在最前面）
    [writingsArray insertObject:writingRecord atIndex:0];
    
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:writingsArray format:NSPropertyListXMLFormat_v1_0 options:0 error:nil];
    
    // 保存到plist文件
    BOOL success = [plistData writeToFile:plistPath atomically:YES];
    
    if (success) {
        NSLog(@"写作内容已保存到: %@", plistPath);
    } else {
        NSLog(@"保存失败");
    }
}

// 提供类方法用于读取所有写作记录
- (NSArray *)loadAllWritings {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *plistPath = [documentsPath stringByAppendingPathComponent:@"AIUAWritings.plist"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        NSArray *writings = [NSArray arrayWithContentsOfFile:plistPath];
        return writings ?: @[];
    }
    
    return @[];
}

- (NSArray *)loadWritingsByType:(NSString *)type {
    NSArray *allWritings = [self loadAllWritings];
    
    if (!type || type.length == 0) {
        // 如果type为空，返回type为空或没有type字段的记录
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *writing, NSDictionary *bindings) {
            return writing[@"type"] == nil || [writing[@"type"] isEqualToString:@""];
        }];
        return [allWritings filteredArrayUsingPredicate:predicate];
    } else {
        // 返回指定type的记录
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %@", type];
        return [allWritings filteredArrayUsingPredicate:predicate];
    }
}

// 根据ID删除写作记录
- (BOOL)deleteWritingWithID:(NSString *)writingID {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *plistPath = [documentsPath stringByAppendingPathComponent:@"AIUAWritings.plist"];
    
    NSMutableArray *writingsArray = [NSMutableArray arrayWithArray:[self loadAllWritings]];
    
    // 查找并删除指定ID的记录
    NSUInteger indexToDelete = NSNotFound;
    for (NSUInteger i = 0; i < writingsArray.count; i++) {
        NSDictionary *writing = writingsArray[i];
        if ([writing[@"id"] isEqualToString:writingID]) {
            indexToDelete = i;
            break;
        }
    }
    
    if (indexToDelete != NSNotFound) {
        [writingsArray removeObjectAtIndex:indexToDelete];
        return [writingsArray writeToFile:plistPath atomically:YES];
    }
    
    return NO;
}

#pragma mark - 提示词处理

- (NSString *)extractRequirementFromPrompt:(NSString *)prompt {
    if (prompt.length == 0) {
        return @"";
    }
    
    NSString *cleanedPrompt = [prompt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // 模式1: 提取"要求："后面的内容
    NSArray *requirementPrefixes = @[@"要求：", @"要求:", @"要求"];
    
    for (NSString *prefix in requirementPrefixes) {
        NSRange prefixRange = [cleanedPrompt rangeOfString:prefix];
        if (prefixRange.location != NSNotFound) {
            NSString *requirement = [cleanedPrompt substringFromIndex:prefixRange.location + prefixRange.length];
            requirement = [requirement stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            // 如果要求内容过长，进行截断
            if (requirement.length > 0) {
                return [self truncateRequirementIfNeeded:requirement];
            }
        }
    }
    
    // 模式2: 使用正则表达式匹配"要求：XXX"格式
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"要求[:：]\\s*([^，。！？]+)" options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:cleanedPrompt options:0 range:NSMakeRange(0, cleanedPrompt.length)];
    if (match && [match rangeAtIndex:1].location != NSNotFound) {
        NSString *requirement = [cleanedPrompt substringWithRange:[match rangeAtIndex:1]];
        requirement = [requirement stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (requirement.length > 0) {
            return [self truncateRequirementIfNeeded:requirement];
        }
    }
    
    // 模式3: 如果没有明确的要求，提取主题后的合理部分
    return [self extractReasonablePartFromPrompt:cleanedPrompt];
}

- (NSString *)extractReasonablePartFromPrompt:(NSString *)prompt {
    if (prompt.length == 0) {
        return @"";
    }
    
    // 移除主题部分（如果存在）
    NSString *theme = [self extractThemeFromPrompt:prompt];
    if (theme && theme.length > 0) {
        // 找到主题在prompt中的位置
        NSRange themeRange = [prompt rangeOfString:theme];
        if (themeRange.location != NSNotFound) {
            // 获取主题后面的内容
            NSString *contentAfterTheme = [prompt substringFromIndex:themeRange.location + themeRange.length];
            contentAfterTheme = [contentAfterTheme stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            // 移除可能的分隔符
            NSCharacterSet *separators = [NSCharacterSet characterSetWithCharactersInString:@"，：:；;"];
            contentAfterTheme = [contentAfterTheme stringByTrimmingCharactersInSet:separators];
            
            if (contentAfterTheme.length > 0) {
                return [self truncateRequirementIfNeeded:contentAfterTheme];
            }
        }
    }
    
    // 模式4: 如果prompt本身不长，直接使用
    if (prompt.length <= 50) {
        return [self truncateRequirementIfNeeded:prompt];
    }
    
    // 模式5: 截取前50个字符作为预览
    return [self truncateRequirementIfNeeded:prompt];
}

- (NSString *)truncateRequirementIfNeeded:(NSString *)requirement {
    if (requirement.length <= 60) {
        return requirement;
    }
    
    // 截取前60个字符并在末尾添加省略号
    NSString *truncated = [requirement substringToIndex:60];
    truncated = [truncated stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return [truncated stringByAppendingString:@"..."];
}

// 更新之前提取主题的方法，使其更准确
- (NSString *)extractThemeFromPrompt:(NSString *)prompt {
    if (prompt.length == 0) {
        return nil;
    }
    
    NSString *cleanedPrompt = [prompt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // 模式1: "主题：XXX，要求：XXX"
    NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:@"主题[:：]\\s*([^，要求]+?)(?:，|$|要求)" options:0 error:nil];
    NSTextCheckingResult *match1 = [regex1 firstMatchInString:cleanedPrompt options:0 range:NSMakeRange(0, cleanedPrompt.length)];
    if (match1 && [match1 rangeAtIndex:1].location != NSNotFound) {
        NSString *theme = [cleanedPrompt substringWithRange:[match1 rangeAtIndex:1]];
        return [theme stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    // 模式2: "XXX:XXX" 格式
    NSRegularExpression *regex2 = [NSRegularExpression regularExpressionWithPattern:@"^([^:：]+?)[:：]\\s*([^，]+)" options:0 error:nil];
    NSTextCheckingResult *match2 = [regex2 firstMatchInString:cleanedPrompt options:0 range:NSMakeRange(0, cleanedPrompt.length)];
    if (match2 && [match2 rangeAtIndex:1].location != NSNotFound) {
        NSString *firstPart = [cleanedPrompt substringWithRange:[match2 rangeAtIndex:1]];
        if ([firstPart containsString:@"主题"] || firstPart.length <= 10) {
            NSString *theme = [cleanedPrompt substringWithRange:[match2 rangeAtIndex:2]];
            theme = [theme stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            // 移除可能的要求部分
            NSRange requirementRange = [theme rangeOfString:@"要求"];
            if (requirementRange.location != NSNotFound) {
                theme = [theme substringToIndex:requirementRange.location];
            }
            return [theme stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"，"]];
        }
    }
    
    // 模式3: 直接返回第一个逗号前的内容（如果内容较短）
    NSRange commaRange = [cleanedPrompt rangeOfString:@"，"];
    if (commaRange.location != NSNotFound && commaRange.location < 20) {
        NSString *possibleTheme = [cleanedPrompt substringToIndex:commaRange.location];
        return [possibleTheme stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    // 模式4: 如果整个prompt很短，直接返回
    if (cleanedPrompt.length <= 25) {
        return cleanedPrompt;
    }
    
    return nil;
}

#pragma mark - 辅助方法

- (NSString *)getItemId:(NSDictionary *)item {
    // 使用 type + title 作为唯一标识
    NSString *type = item[@"type"] ?: @"";
    NSString *title = item[@"title"] ?: @"";
    return [NSString stringWithFormat:@"%@_%@", type, title];
}

- (NSString *)generateUniqueID {
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"%.0f", timestamp * 1000];
}

- (NSString *)currentTimeString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [formatter stringFromDate:[NSDate date]];
}

// 获取plist文件路径
- (NSString *)getPlistFilePath:(NSString *)fileName {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [documentsPath stringByAppendingPathComponent:fileName];
}

- (NSString *)currentDateString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
    return [formatter stringFromDate:[NSDate date]];
}

@end
