// AIUADocumentCell.h
#import "AIUASuperTableViewCell.h"

typedef void (^MoreButtonTappedBlock)(void);

@interface AIUADocumentCell : AIUASuperTableViewCell

@property (nonatomic, copy) MoreButtonTappedBlock moreButtonTapped;

- (void)configureWithDocument:(NSDictionary *)document;

@end