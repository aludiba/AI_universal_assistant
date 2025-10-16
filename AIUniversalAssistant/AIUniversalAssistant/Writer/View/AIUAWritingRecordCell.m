#import "AIUAWritingRecordCell.h"
#import "AIUADataManager.h"

@interface AIUAWritingRecordCell ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *promptLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UILabel *metaLabel;

@end

@implementation AIUAWritingRecordCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
        [self setupConstraints];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    // 容器视图
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor whiteColor];
    self.containerView.layer.cornerRadius = 12;
    self.containerView.layer.masksToBounds = YES;
    self.containerView.layer.borderWidth = 1;
    self.containerView.layer.borderColor = AIUAUIColorRGB(229, 231, 235).CGColor;
    [self.contentView addSubview:self.containerView];
    
    // 标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = AIUAUIFontBold(18);
    self.titleLabel.textColor = AIUAUIColorRGB(34, 34, 34);
    self.titleLabel.numberOfLines = 1;
    [self.containerView addSubview:self.titleLabel];
    
    // 提示词标签
    self.promptLabel = [[UILabel alloc] init];
    self.promptLabel.font = AIUAUIFontSystem(14);
    self.promptLabel.textColor = AIUAUIColorRGB(107, 114, 128);
    self.promptLabel.numberOfLines = 2;
    [self.containerView addSubview:self.promptLabel];
    
    // 内容标签
    self.contentLabel = [[UILabel alloc] init];
    self.contentLabel.font = AIUAUIFontSystem(15);
    self.contentLabel.textColor = AIUAUIColorRGB(68, 68, 68);
    self.contentLabel.numberOfLines = 3;
    [self.containerView addSubview:self.contentLabel];
    
    // 分隔线
    self.separatorView = [[UIView alloc] init];
    self.separatorView.backgroundColor = AIUAUIColorRGB(243, 244, 246);
    [self.containerView addSubview:self.separatorView];
    
    // 元信息标签（时间和字数）
    self.metaLabel = [[UILabel alloc] init];
    self.metaLabel.font = AIUAUIFontSystem(12);
    self.metaLabel.textColor = AIUAUIColorRGB(156, 163, 175);
    [self.containerView addSubview:self.metaLabel];
}

- (void)setupConstraints {
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.promptLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.separatorView.translatesAutoresizingMaskIntoConstraints = NO;
    self.metaLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // 容器视图
        [self.containerView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8],
        [self.containerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.containerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.containerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8],
        
        // 标题标签
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:16],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:16],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-16],
        
        // 提示词标签
        [self.promptLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:8],
        [self.promptLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:16],
        [self.promptLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-16],
        
        // 内容标签
        [self.contentLabel.topAnchor constraintEqualToAnchor:self.promptLabel.bottomAnchor constant:12],
        [self.contentLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:16],
        [self.contentLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-16],
        
        // 分隔线
        [self.separatorView.topAnchor constraintEqualToAnchor:self.contentLabel.bottomAnchor constant:12],
        [self.separatorView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:16],
        [self.separatorView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-16],
        [self.separatorView.heightAnchor constraintEqualToConstant:1],
        
        // 元信息标签
        [self.metaLabel.topAnchor constraintEqualToAnchor:self.separatorView.bottomAnchor constant:12],
        [self.metaLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:16],
        [self.metaLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-16],
        [self.metaLabel.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor constant:-16]
    ]];
}

- (void)configureWithWriting:(NSDictionary *)writing {
    // 标题
    self.titleLabel.text = writing[@"title"] ?: L(@"no_title");
    
    // 提示词（处理可能的多余字符）
    NSString *prompt = writing[@"prompt"] ?: @"";
    NSString *requirement = [[AIUADataManager sharedManager] extractRequirementFromPrompt:prompt];
    
    if (requirement.length > 0) {
        self.promptLabel.text = requirement;
    } else {
        // 如果没有提取到要求，显示简化的prompt
        self.promptLabel.text = [self simplifyPrompt:prompt];
    }
    
    // 内容（截取前100个字符作为预览）
    NSString *content = writing[@"content"] ?: @"";
    if (content.length > 100) {
        content = [[content substringToIndex:100] stringByAppendingString:@"..."];
    }
    self.contentLabel.text = content;
    
    // 元信息（时间和字数）
    NSString *time = writing[@"createTime"] ?: @"";
    NSNumber *wordCount = writing[@"wordCount"] ?: @0;
    self.metaLabel.text = [NSString stringWithFormat:@"%@ · %@%@", time, wordCount, L(@"words")];
}

- (NSString *)simplifyPrompt:(NSString *)prompt {
    if (prompt.length == 0) {
        return @"";
    }
    
    // 移除主题部分
    NSString *theme = [[AIUADataManager sharedManager] extractThemeFromPrompt:prompt];
    if (theme && theme.length > 0) {
        // 找到主题在prompt中的位置
        NSRange themeRange = [prompt rangeOfString:theme];
        if (themeRange.location != NSNotFound) {
            NSString *simplified = [prompt substringFromIndex:themeRange.location + themeRange.length];
            simplified = [simplified stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"，：:"]];
            
            if (simplified.length > 0) {
                return [[AIUADataManager sharedManager] truncateRequirementIfNeeded:simplified];
            }
        }
    }
    
    // 如果无法简化，直接截断
    return [[AIUADataManager sharedManager] truncateRequirementIfNeeded:prompt];
}

@end
