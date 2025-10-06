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


@end
