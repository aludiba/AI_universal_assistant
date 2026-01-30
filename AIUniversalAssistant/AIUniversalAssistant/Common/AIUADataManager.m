//
//  AIUADataManager.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/6/25.
//

#import "AIUADataManager.h"
#import "AIUAMBProgressManager.h"
#import "AIUAToolsManager.h"
#import "AIUAWordPackManager.h"

// 缓存清理完成通知
NSString * const AIUACacheClearedNotification = @"AIUACacheClearedNotification";

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

// "热门"模块数据
- (NSArray *)loadHotCategories {
    // pathForResource:ofType:会自动根据系统语言选择对应的.lproj目录中的文件
    NSString *path = [[NSBundle mainBundle] pathForResource:@"AIUAHotCategories" ofType:@"plist"];
    if (!path) {
        NSLog(@"AIUAHotCategories.plist 文件未找到");
        return @[];
    }
    
    // 记录加载的文件路径（用于调试，可以看到加载的是哪个语言版本）
    NSLog(@"加载热门分类文件: %@", path);
    
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
    // pathForResource:ofType:会自动根据系统语言选择对应的.lproj目录中的文件
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
    // pathForResource:ofType:会自动根据系统语言选择对应的.lproj目录中的文件
    NSString *path = [[NSBundle mainBundle] pathForResource:@"AIUAWritingCategories" ofType:@"plist"];
    if (!path) {
        NSLog(@"AIUAWritingCategories.plist 文件未找到");
        return @[];
    }
    
    // 记录加载的文件路径（用于调试，可以看到加载的是哪个语言版本）
    NSLog(@"加载写作分类文件: %@", path);
    
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
    // 安全检查：确保 writingRecord 不为 nil
    if (!writingRecord || ![writingRecord isKindOfClass:[NSDictionary class]]) {
        NSLog(@"❌ saveWritingToPlist: writingRecord 为 nil 或不是有效的字典");
        return;
    }
    
    NSLog(@"saveWritingToPlist-writingRecord:%@", writingRecord[@"content"]);
    // 获取沙盒Documents目录
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *plistPath = [documentsPath stringByAppendingPathComponent:@"AIUAWritings.plist"];
    
    // 读取现有的写作记录
    NSMutableArray *writingsArray = [NSMutableArray array];
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        NSArray *existingWritings = [NSArray arrayWithContentsOfFile:plistPath];
        if (existingWritings && [existingWritings isKindOfClass:[NSArray class]]) {
            // 确保所有元素都是字典类型
            for (id item in existingWritings) {
                if ([item isKindOfClass:[NSDictionary class]]) {
                    [writingsArray addObject:item];
                }
            }
        }
    }
    
    // 确保 writingsArray 是有效的可变数组
    if (!writingsArray || ![writingsArray isKindOfClass:[NSMutableArray class]]) {
        NSLog(@"❌ saveWritingToPlist: writingsArray 初始化失败，重新创建");
        writingsArray = [NSMutableArray array];
    }
    
    // 添加到数组开头（最新的在最前面）
    // 安全检查：确保索引有效
    if (writingsArray.count == 0) {
        [writingsArray addObject:writingRecord];
    } else {
        [writingsArray insertObject:writingRecord atIndex:0];
    }
    
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:writingsArray format:NSPropertyListXMLFormat_v1_0 options:0 error:nil];
    
    // 保存到plist文件
    if (plistData) {
        BOOL success = [plistData writeToFile:plistPath atomically:YES];
        if (success) {
            NSLog(@"✅ 写作内容已保存到: %@", plistPath);
        } else {
            NSLog(@"❌ 保存失败: 无法写入文件");
        }
    } else {
        NSLog(@"❌ 保存失败: 无法序列化数据");
    }
}

// 提供类方法用于读取所有写作记录
- (NSArray *)loadAllWritings {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *plistPath = [documentsPath stringByAppendingPathComponent:@"AIUAWritings.plist"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        NSArray *writings = [NSArray arrayWithContentsOfFile:plistPath];
        if (!writings || ![writings isKindOfClass:[NSArray class]]) {
            return @[];
        }
        
        // 兼容性修复：历史版本可能用 NSString.length 作为 wordCount，导致与“字数包扣减口径”不一致。
        // 这里统一为 AIUAWordPackManager 的统计规则（与扣减一致），并回写到 plist。
        BOOL didModify = NO;
        NSMutableArray *fixed = [NSMutableArray arrayWithCapacity:writings.count];
        for (id item in writings) {
            if (![item isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            NSMutableDictionary *m = [item mutableCopy];
            NSString *title = m[@"title"] ?: @"";
            NSString *content = m[@"content"] ?: @"";
            // 与扣减口径一致：按“标题+正文”整体统计
            NSMutableString *fullTextForCount = [NSMutableString string];
            if (title.length > 0) {
                [fullTextForCount appendString:title];
            }
            if (title.length > 0 && content.length > 0) {
                [fullTextForCount appendString:@"\n"];
            }
            if (content.length > 0) {
                [fullTextForCount appendString:content];
            }
            NSInteger recalculated = [AIUAWordPackManager countWordsInText:fullTextForCount];
            NSNumber *existing = m[@"wordCount"];
            NSInteger existingValue = [existing isKindOfClass:[NSNumber class]] ? existing.integerValue : -1;
            
            if (existingValue != recalculated) {
                NSLog(@"[DataManager] 📝 修正文档 '%@': 旧=%ld, 新=%ld", 
                      [title length] > 20 ? [[title substringToIndex:20] stringByAppendingString:@"..."] : title, 
                      (long)existingValue, (long)recalculated);
                m[@"wordCount"] = @(recalculated);
                didModify = YES;
            }
            [fixed addObject:[m copy]];
        }
        
        if (didModify) {
            NSLog(@"[DataManager] ✅ 检测到不一致，回写 plist...");
            NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:fixed
                                                                          format:NSPropertyListXMLFormat_v1_0
                                                                         options:0
                                                                           error:nil];
            if (plistData) {
                BOOL writeSuccess = [plistData writeToFile:plistPath atomically:YES];
                if (writeSuccess) {
                    NSLog(@"[DataManager] ✅ wordCount 迁移完成并已回写");
                } else {
                    NSLog(@"[DataManager] ❌ wordCount 迁移失败：无法写入文件");
                }
            } else {
                NSLog(@"[DataManager] ❌ wordCount 迁移失败：无法序列化");
            }
        } else {
            NSLog(@"[DataManager] ✓ 所有文档 wordCount 已是最新规则，无需迁移");
        }
        
        return [fixed copy];
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

- (void)exportDocument:(NSString *)title withContent:(NSString *)content {
    NSString *fullText = [NSString stringWithFormat:@"%@\n\n%@", title, content];
    
    // 创建临时文件，使用.txt格式以确保兼容性（微信、QQ等都能打开）
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.txt", L(@"creation_content"), [[AIUADataManager sharedManager] currentDateString]];
    NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    NSURL *tempFileURL = [NSURL fileURLWithPath:tempFilePath];
    
    NSError *error;
    BOOL success = [fullText writeToURL:tempFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (!success || error) {
        NSLog(@"❌ 导出文档失败: %@", error.localizedDescription);
        [AIUAMBProgressManager showTextHUD:nil withText:L(@"export_failed") andSubText:nil];
        return;
    }
    
    // 确保文件存在且可读
    if (![[NSFileManager defaultManager] fileExistsAtPath:tempFilePath]) {
        NSLog(@"❌ 导出文档失败: 文件创建失败");
        [AIUAMBProgressManager showTextHUD:nil withText:L(@"export_failed") andSubText:nil];
        return;
    }
    
    // 调用系统分享，使用文件URL和文件名
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[tempFileURL] applicationActivities:nil];
    
    // 对于iPad，需要设置popover的锚点
    if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
        UIPopoverPresentationController *popover = activityVC.popoverPresentationController;
        if (popover) {
            UIViewController *topVC = [AIUAToolsManager topViewController];
            popover.sourceView = topVC.view;
            popover.sourceRect = CGRectMake(topVC.view.bounds.size.width / 2, topVC.view.bounds.size.height / 2, 0, 0);
            popover.permittedArrowDirections = 0;
        }
    }
    
    [[AIUAToolsManager topViewController] presentViewController:activityVC animated:YES completion:nil];
}

#pragma mark - 缓存管理

- (unsigned long long)calculateCacheSize {
    unsigned long long totalSize = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    
    // 需要计算大小的文件列表
    NSArray *cacheFiles = @[
        @"AIUARecentUsed.plist",
        @"SearchHistory.plist",
        @"AIUAWritings.plist"
    ];
    
    for (NSString *fileName in cacheFiles) {
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
        if ([fileManager fileExistsAtPath:filePath]) {
            NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:nil];
            if (attributes) {
                NSNumber *fileSize = attributes[NSFileSize];
                if (fileSize) {
                    totalSize += [fileSize unsignedLongLongValue];
                }
            }
        }
    }
    
    return totalSize;
}

- (NSString *)formatCacheSize:(unsigned long long)size {
    if (size == 0) {
        return @"0 B";
    }
    
    double sizeInKB = size / 1024.0;
    if (sizeInKB < 1024) {
        return [NSString stringWithFormat:@"%.1f KB", sizeInKB];
    }
    
    double sizeInMB = sizeInKB / 1024.0;
    if (sizeInMB < 1024) {
        return [NSString stringWithFormat:@"%.2f MB", sizeInMB];
    }
    
    double sizeInGB = sizeInMB / 1024.0;
    return [NSString stringWithFormat:@"%.2f GB", sizeInGB];
}

- (void)clearCacheWithCompletion:(void(^)(BOOL success, NSString * _Nullable errorMessage))completion {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    
    // 需要清除的文件列表
    NSArray *cacheFiles = @[
        @"AIUARecentUsed.plist",
        @"SearchHistory.plist",
        @"AIUAWritings.plist"
    ];
    
    NSMutableArray *errors = [NSMutableArray array];
    
    for (NSString *fileName in cacheFiles) {
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
        if ([fileManager fileExistsAtPath:filePath]) {
            NSError *error = nil;
            BOOL success = [fileManager removeItemAtPath:filePath error:&error];
            if (!success) {
                NSString *errorMsg = [NSString stringWithFormat:@"删除 %@ 失败: %@", fileName, error.localizedDescription];
                [errors addObject:errorMsg];
                NSLog(@"[DataManager] %@", errorMsg);
            } else {
                NSLog(@"[DataManager] 成功删除缓存文件: %@", fileName);
            }
        }
    }
    
    // 发送通知，通知相关页面更新
    [[NSNotificationCenter defaultCenter] postNotificationName:AIUACacheClearedNotification object:nil];
    
    if (errors.count > 0) {
        NSString *errorMessage = [errors componentsJoinedByString:@"\n"];
        if (completion) {
            completion(NO, errorMessage);
        }
    } else {
        NSLog(@"[DataManager] 缓存清理完成");
        if (completion) {
            completion(YES, nil);
        }
    }
}

@end
