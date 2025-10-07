//
//  AIUASuperTableViewCell.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/7/25.
//

#import "AIUASuperTableViewCell.h"

@implementation AIUASuperTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = AIUA_BACK_COLOR;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

@end
