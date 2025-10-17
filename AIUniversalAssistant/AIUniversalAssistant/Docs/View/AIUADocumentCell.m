// AIUADocumentCell.m
#import "AIUADocumentCell.h"

@interface AIUADocumentCell ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *documentIcon;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *wordCountLabel;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIView *separatorView;

@end

@implementation AIUADocumentCell

- (void)setupUI {
    [super setupUI];
        
    // 容器视图
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor whiteColor];
    [self.contentView addSubview:self.containerView];
    
    // 文档图标
    self.documentIcon = [[UIImageView alloc] init];
    self.documentIcon.image = [UIImage systemImageNamed:@"doc.text"];
    self.documentIcon.tintColor = AIUAUIColorRGB(239, 239, 239);
    self.documentIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.containerView addSubview:self.documentIcon];
    
    // 标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = AIUAUIFontSystem(16);
    self.titleLabel.textColor = AIUAUIColorRGB(34, 34, 34);
    self.titleLabel.numberOfLines = 1;
    [self.containerView addSubview:self.titleLabel];
    
    // 时间标签
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = AIUAUIFontSystem(13);
    self.timeLabel.textColor = AIUAUIColorRGB(156, 163, 175);
    [self.containerView addSubview:self.timeLabel];
    
    // 字数标签
    self.wordCountLabel = [[UILabel alloc] init];
    self.wordCountLabel.font = AIUAUIFontSystem(13);
    self.wordCountLabel.textColor = AIUAUIColorRGB(156, 163, 175);
    [self.containerView addSubview:self.wordCountLabel];
    
    // 更多按钮
    self.moreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.moreButton setImage:[UIImage systemImageNamed:@"ellipsis"] forState:UIControlStateNormal];
    self.moreButton.tintColor = AIUAUIColorRGB(156, 163, 175);
    [self.moreButton addTarget:self action:@selector(moreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.moreButton];
    
    // 分隔线
    self.separatorView = [[UIView alloc] init];
    self.separatorView.backgroundColor = AIUAUIColorRGB(243, 244, 246);
    [self.containerView addSubview:self.separatorView];
    
    [self setupConstraints];
}

- (void)setupConstraints {
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.documentIcon.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.wordCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.separatorView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // 容器视图
        [self.containerView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.containerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.containerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.containerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        
        // 文档图标
        [self.documentIcon.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:16],
        [self.documentIcon.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor],
        [self.documentIcon.widthAnchor constraintEqualToConstant:44],
        [self.documentIcon.heightAnchor constraintEqualToConstant:44],
        
        // 标题标签
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:16],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.documentIcon.trailingAnchor constant:12],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.moreButton.leadingAnchor constant:-8],
        
        // 时间标签
        [self.timeLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:8],
        [self.timeLabel.leadingAnchor constraintEqualToAnchor:self.documentIcon.trailingAnchor constant:12],
        [self.timeLabel.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor constant:-16],
        
        // 字数标签
        [self.wordCountLabel.leadingAnchor constraintEqualToAnchor:self.timeLabel.trailingAnchor constant:8],
        [self.wordCountLabel.centerYAnchor constraintEqualToAnchor:self.timeLabel.centerYAnchor],
        
        // 更多按钮
        [self.moreButton.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-16],
        [self.moreButton.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor],
        [self.moreButton.widthAnchor constraintEqualToConstant:24],
        [self.moreButton.heightAnchor constraintEqualToConstant:24],
        
        // 分隔线
        [self.separatorView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:16],
        [self.separatorView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-16],
        [self.separatorView.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor],
        [self.separatorView.heightAnchor constraintEqualToConstant:1]
    ]];
}

- (void)configureWithDocument:(NSDictionary *)document {
    // 标题
    NSString *title = document[@"title"] ?: L(@"untitled_document");
    self.titleLabel.text = title;
    
    // 时间显示优化
    NSString *createTime = document[@"createTime"] ?: @"";
    self.timeLabel.text = [self formatTimeDisplay:createTime];
    
    // 字数
    NSNumber *wordCount = document[@"wordCount"] ?: @0;
    self.wordCountLabel.text = [NSString stringWithFormat:@"|  %@ %@", wordCount, L(@"words")];
}

- (NSString *)formatTimeDisplay:(NSString *)timeString {
    if (timeString.length == 0) {
        return @"";
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *createDate = [formatter dateFromString:timeString];
    
    if (!createDate) {
        return timeString;
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    if ([calendar isDateInToday:createDate]) {
        // 今天显示时间
        [formatter setDateFormat:[NSString stringWithFormat:@"%@ HH:mm",L(@"today")]];
        return [formatter stringFromDate:createDate];
    } else if ([calendar isDateInYesterday:createDate]) {
        // 昨天显示昨天
        [formatter setDateFormat:[NSString stringWithFormat:@"%@ HH:mm",L(@"yesterday")]];
        return [formatter stringFromDate:createDate];
    } else {
        // 其他日期显示完整日期
        return timeString;
    }
}

- (void)moreButtonTapped:(UIButton *)sender {
    if (self.moreButtonTapped) {
        self.moreButtonTapped();
    }
}

@end
