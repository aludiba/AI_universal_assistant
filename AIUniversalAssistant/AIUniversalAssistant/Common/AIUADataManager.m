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
