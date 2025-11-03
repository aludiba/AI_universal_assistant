#import "AIUASuperViewController.h"

@interface AIUAWritingRecordsViewController : AIUASuperViewController

@property (nonatomic, assign) BOOL isAllRecords; // 如果传入YES则显示所有记录

@property (nonatomic, copy) NSString *type; // 传入的类型，如果为空则显示所有无类型的记录

@end
