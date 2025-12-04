#import "AIUAWritingDetailViewController.h"
#import "AIUADataManager.h"
#import "AIUADeepSeekWriter.h"
#import "AIUAAlertHelper.h"
#import "AIUAMBProgressManager.h"
#import "AIUADocDetailViewController.h"
#import "AIUAWordPackManager.h"
#import "AIUAWordPackViewController.h"

@interface AIUAWritingDetailViewController ()

@property (nonatomic, copy) NSString *prompt;
@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, assign) NSInteger wordCount;
@property (nonatomic, strong) AIUADeepSeekWriter *writer;

// UI Components
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextView *contentTextView; // 改为UITextView
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) UIView *separatorLine;

// Bottom Buttons
@property (nonatomic, strong) UIView *bottomButtonContainer;
@property (nonatomic, strong) UIButton *rewriteButton;
@property (nonatomic, strong) UIButton *duplicateButton;
@property (nonatomic, strong) UIButton *exportButton;
@property (nonatomic, strong) UIButton *editButton;

@property (nonatomic, assign) BOOL isGenerating;
@property (nonatomic, copy) NSString *finalContent;
@property (nonatomic, copy) NSString *finalTitle;
@property (nonatomic, copy) NSString *currentWritingID; // 当前写作记录的ID
@property (nonatomic, copy) NSDictionary *currentWritingDocParam; // 当前要保存的文档参数

@end

@implementation AIUAWritingDetailViewController

#pragma mark - 初始化

- (instancetype)initWithPrompt:(NSString *)prompt apiKey:(NSString *)apiKey {
    self = [super init];
    if (self) {
        _prompt = [prompt copy];
        _apiKey = [apiKey copy];
        _isGenerating = YES;
    }
    return self;
}

- (instancetype)initWithPrompt:(NSString *)prompt apiKey:(NSString *)apiKey wordCount:(NSInteger)wordCount {
    self = [super init];
    if (self) {
        _prompt = [prompt copy];
        _apiKey = [apiKey copy];
        _wordCount = wordCount;
        _isGenerating = YES;
        
    }
    return self;
}

- (instancetype)initWithPrompt:(NSString *)prompt apiKey:(NSString *)apiKey type:(NSString *)type {
    self = [super init];
    if (self) {
        _prompt = [prompt copy];
        _apiKey = [apiKey copy];
        _type = [type copy];
        _isGenerating = YES;
    }
    return self;
}

- (instancetype)initWithPrompt:(NSString *)prompt apiKey:(NSString *)apiKey type:(NSString *)type wordCount:(NSInteger)wordCount {
    self = [super init];
    if (self) {
        _prompt = [prompt copy];
        _apiKey = [apiKey copy];
        _type = [type copy];
        _wordCount = wordCount;
        _isGenerating = YES;
    }
    return self;
}

- (void)setupUI {
    [super setupUI];
    self.title = L(@"creation_details");
    
    // 滚动视图
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];
    
    // 内容视图
    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.contentView.layer.cornerRadius = 12;
    self.contentView.layer.masksToBounds = YES;
    [self.scrollView addSubview:self.contentView];
    
    // 标题标签
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = AIUAUIFontSystem(20);
    self.titleLabel.textColor = AIUAUIColorRGB(34, 34, 34);
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.titleLabel];
    
    // 分隔线
    self.separatorLine = [[UIView alloc] init];
    self.separatorLine.backgroundColor = AIUAUIColorRGB(229, 231, 235);
    [self.contentView addSubview:self.separatorLine];
    
    // 内容TextView - 使用UITextView支持富文本
    self.contentTextView = [[UITextView alloc] init];
    self.contentTextView.font = AIUAUIFontSystem(16);
    self.contentTextView.textColor = AIUAUIColorRGB(68, 68, 68);
    self.contentTextView.editable = NO; // 不可编辑，只用于显示
    self.contentTextView.scrollEnabled = NO; // 禁用自身滚动，使用外部scrollView
    self.contentTextView.backgroundColor = [UIColor clearColor];
    self.contentTextView.textContainerInset = UIEdgeInsetsZero; // 移除内边距
    self.contentTextView.textContainer.lineFragmentPadding = 0; // 移除行间距
    [self.contentView addSubview:self.contentTextView];
    
    // 停止生成按钮
    UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
    config.title = L(@"stop_generating");
    config.image = [self stopButtonImage];
    config.imagePadding = 4;
    config.baseForegroundColor = AIUAUIColorRGB(239, 68, 68);
    config.background.backgroundColor = AIUAUIColorRGB(254, 242, 242);
    config.contentInsets = NSDirectionalEdgeInsetsMake(8, 16, 8, 16);
    config.cornerStyle = UIButtonConfigurationCornerStyleMedium;

    UIButton *stopButton = [UIButton buttonWithType:UIButtonTypeSystem];
    stopButton.configuration = config;
    stopButton.layer.cornerRadius = 6;
    stopButton.layer.borderWidth = 1;
    stopButton.layer.borderColor = AIUAUIColorRGB(254, 202, 202).CGColor;
    [self.view addSubview:stopButton];
    [stopButton addTarget:self action:@selector(stopButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.stopButton = stopButton;
    
    // 底部按钮容器
    self.bottomButtonContainer = [[UIView alloc] init];
    self.bottomButtonContainer.backgroundColor = [UIColor whiteColor];
    self.bottomButtonContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.bottomButtonContainer.layer.shadowOffset = CGSizeMake(0, -2);
    self.bottomButtonContainer.layer.shadowOpacity = 0.1;
    self.bottomButtonContainer.layer.shadowRadius = 4;
    [self.view addSubview:self.bottomButtonContainer];
    
    // 重新创作按钮（图标）
    self.rewriteButton = [self createIconButtonWithImageName:@"arrow.clockwise" title:L(@"rewrite")];
    [self.rewriteButton addTarget:self action:@selector(rewriteButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomButtonContainer addSubview:self.rewriteButton];
    
    // 复制全文按钮
    self.duplicateButton = [self createIconButtonWithImageName:@"doc.on.doc" title:L(@"copy")];
    [self.duplicateButton addTarget:self action:@selector(duplicateButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomButtonContainer addSubview:self.duplicateButton];
    
    // 导出Word按钮
    self.exportButton = [self createIconButtonWithImageName:@"square.and.arrow.up" title:L(@"export")];
    [self.exportButton addTarget:self action:@selector(exportButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomButtonContainer addSubview:self.exportButton];
    
    // 智能编辑按钮
    self.editButton = [self createIconButtonWithImageName:@"pencil" title:L(@"edit")];
    [self.editButton addTarget:self action:@selector(editButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomButtonContainer addSubview:self.editButton];
    
    // 初始状态
    [self updateUIState];
    
    [self setupConstraints];
    [self startWriting];
}

- (void)backButtonTapped {
    [super backButtonTapped];
    self.isGenerating = NO;
}

- (UIButton *)createIconButtonWithImageName:(NSString *)imageName title:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    
    // 设置符号图标大小与颜色
    UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:16
                                                                                               weight:UIImageSymbolWeightMedium];
    UIImage *image = [UIImage systemImageNamed:imageName withConfiguration:symbolConfig];
    image = [image imageWithTintColor:[UIColor grayColor] renderingMode:UIImageRenderingModeAlwaysOriginal];
    
    UIButtonConfiguration *btnConfig = [UIButtonConfiguration plainButtonConfiguration];
    btnConfig.title = title;
    btnConfig.image = image;
    btnConfig.imagePlacement = NSDirectionalRectEdgeTop; // 图标在上方
    btnConfig.imagePadding = 4; // 图标和标题间距为4
    btnConfig.baseForegroundColor = [UIColor grayColor]; // 设置图标和标题颜色为灰色
    
    button.configuration = btnConfig;
    
    return button;
}

- (UIImage *)stopButtonImage {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(12, 12), NO, [UIScreen mainScreen].scale);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 12, 12)];
    [[UIColor grayColor] setFill];
    [path fill];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


- (void)setupConstraints {
    CGFloat btnPadding = (AIUAScreenWidth - 4 * 60) / 5;
    
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.separatorLine.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stopButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomButtonContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.rewriteButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.duplicateButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.exportButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.editButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // 滚动视图
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.bottomButtonContainer.topAnchor],
        
        // 内容视图
        [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor],
        
        // 标题
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:24],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
        
        // 分隔线
        [self.separatorLine.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:16],
        [self.separatorLine.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
        [self.separatorLine.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
        [self.separatorLine.heightAnchor constraintEqualToConstant:1],
        
        // 内容TextView
        [self.contentTextView.topAnchor constraintEqualToAnchor:self.separatorLine.bottomAnchor constant:20],
        [self.contentTextView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
        [self.contentTextView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
        [self.contentTextView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-24],
        
        // 停止按钮
        [self.stopButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.stopButton.bottomAnchor constraintEqualToAnchor:self.bottomButtonContainer.topAnchor constant:-16],
        [self.stopButton.widthAnchor constraintEqualToConstant:120],
        [self.stopButton.heightAnchor constraintEqualToConstant:40],
        
        // 底部按钮容器
        [self.bottomButtonContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.bottomButtonContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.bottomButtonContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.bottomButtonContainer.heightAnchor constraintEqualToConstant:80],
        
        // 底部按钮布局
        [self.rewriteButton.leadingAnchor constraintEqualToAnchor:self.bottomButtonContainer.leadingAnchor constant:btnPadding],
        [self.rewriteButton.centerYAnchor constraintEqualToAnchor:self.bottomButtonContainer.centerYAnchor],
        [self.rewriteButton.widthAnchor constraintEqualToConstant:60],
        [self.rewriteButton.heightAnchor constraintEqualToConstant:50],
        
        [self.duplicateButton.leadingAnchor constraintEqualToAnchor:self.rewriteButton.trailingAnchor constant:btnPadding],
        [self.duplicateButton.centerYAnchor constraintEqualToAnchor:self.bottomButtonContainer.centerYAnchor],
        [self.duplicateButton.widthAnchor constraintEqualToConstant:60],
        [self.duplicateButton.heightAnchor constraintEqualToConstant:50],
        
        [self.exportButton.leadingAnchor constraintEqualToAnchor:self.duplicateButton.trailingAnchor constant:btnPadding],
        [self.exportButton.centerYAnchor constraintEqualToAnchor:self.bottomButtonContainer.centerYAnchor],
        [self.exportButton.widthAnchor constraintEqualToConstant:60],
        [self.exportButton.heightAnchor constraintEqualToConstant:50],
        
        [self.editButton.leadingAnchor constraintEqualToAnchor:self.exportButton.trailingAnchor constant:btnPadding],
        [self.editButton.centerYAnchor constraintEqualToAnchor:self.bottomButtonContainer.centerYAnchor],
        [self.editButton.widthAnchor constraintEqualToConstant:60],
        [self.editButton.heightAnchor constraintEqualToConstant:50],
        [self.editButton.trailingAnchor constraintLessThanOrEqualToAnchor:self.bottomButtonContainer.trailingAnchor constant:-btnPadding]
    ]];
}

- (void)updateUIState {
    if (self.isGenerating) {
        // 生成中状态
        self.stopButton.hidden = NO;
        self.bottomButtonContainer.hidden = YES;
        self.titleLabel.text = L(@"creating_in_progress");
    } else {
        // 生成完成状态
        self.stopButton.hidden = YES;
        self.bottomButtonContainer.hidden = NO;
    }
}

#pragma mark - 写作逻辑

- (void)startWriting {
    // 估算需要消耗的字数（输入 + 输出）
    NSInteger inputWords = [AIUAWordPackManager countWordsInText:self.prompt ?: @""];
    NSInteger estimatedOutputWords = self.wordCount > 0 ? self.wordCount : 1000; // 默认估算输出1000字
    NSInteger estimatedTotalWords = inputWords + estimatedOutputWords;
    
    // 检查字数是否足够
    if (![[AIUAWordPackManager sharedManager] hasEnoughWords:estimatedTotalWords]) {
        NSInteger availableWords = [[AIUAWordPackManager sharedManager] totalAvailableWords];
        NSString *message = [NSString stringWithFormat:L(@"insufficient_words_message"), @(estimatedTotalWords), @(availableWords)];
        
        [AIUAAlertHelper showAlertWithTitle:L(@"insufficient_words")
                                   message:message
                             cancelBtnText:L(@"cancel")
                            confirmBtnText:L(@"purchase_word_pack")
                              inController:self
                              cancelAction:nil
                             confirmAction:^{
            // 跳转到字数包购买页面
            AIUAWordPackViewController *wordPackVC = [[AIUAWordPackViewController alloc] init];
            [self.navigationController pushViewController:wordPackVC animated:YES];
        }];
        return;
    }
    
    self.isGenerating = YES;
    [self updateUIState];
    
    // 初始化写作引擎
    self.writer = [[AIUADeepSeekWriter alloc] initWithAPIKey:self.apiKey];
    
    // 开始流式写作
    WeakType(self);
    [self.writer generateFullStreamWritingWithPrompt:[NSString stringWithFormat:@"%@/n%@:1、%@；2、%@。", self.prompt, L(@"format"), L(@"first_line"), L(@"body_below")]
                                           wordCount:self.wordCount > 0 ? self.wordCount : 0
                                     streamHandler:^(NSString *chunk, BOOL finished, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            StrongType(self);
            [strongself handleStreamChunk:chunk finished:finished error:error];
        });
    }];
}

- (void)clearCurrentContent {
    // 清除UI显示的内容
    self.titleLabel.text = L(@"creating_in_progress");
    self.contentTextView.attributedText = [[NSAttributedString alloc] initWithString:@""];
    
    // 清除内存中的内容
    self.finalContent = nil;
    self.finalTitle = nil;
}

- (void)handleStreamChunk:(NSString *)chunk finished:(BOOL)finished error:(NSError *)error {
    if (error) {
        [self writingCompletedWithError:error];
        return;
    }
    
    if (finished) {
        [self writingCompletedWithContent:self.contentTextView.attributedText.string];
    } else {
        // 处理Markdown格式并转换为富文本
        NSAttributedString *attributedChunk = [self processMarkdownToAttributedString:chunk];
        
        // 实时更新内容
        NSMutableAttributedString *currentContent = [self.contentTextView.attributedText mutableCopy] ?: [[NSMutableAttributedString alloc] init];
        [currentContent appendAttributedString:attributedChunk];
        self.contentTextView.attributedText = currentContent;
        
        // 自动滚动到最新内容
        [self scrollToBottomIfNeeded];
        
        // 如果是刚开始，尝试提取标题
        if (currentContent.length == 0 && attributedChunk.length > 0) {
            [self tryExtractTitleFromContent:attributedChunk.string];
        }
    }
}

// 将Markdown转换为富文本
- (NSAttributedString *)processMarkdownToAttributedString:(NSString *)text {
    if (!text || text.length == 0) {
        return [[NSAttributedString alloc] initWithString:@""];
    }
    
    // 先移除所有Markdown符号，获取纯文本
    NSString *cleanText = [AIUAToolsManager removeMarkdownSymbols:text];
    
    // 创建基础富文本
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:cleanText];
    NSRange fullRange = NSMakeRange(0, cleanText.length);
    
    // 基础字体样式
    UIFont *baseFont = AIUAUIFontSystem(16);
    UIColor *baseColor = AIUAUIColorRGB(68, 68, 68);
    
    [attributedString addAttribute:NSFontAttributeName value:baseFont range:fullRange];
    [attributedString addAttribute:NSForegroundColorAttributeName value:baseColor range:fullRange];
    
    return attributedString;
}

// 自动滚动到内容底部
- (void)scrollToBottomIfNeeded {
    // UITextView会自动处理滚动，我们只需要确保外部scrollView滚动到底部
    CGFloat contentHeight = [self.contentTextView sizeThatFits:CGSizeMake(self.contentTextView.frame.size.width, CGFLOAT_MAX)].height;
    CGFloat containerHeight = self.scrollView.frame.size.height;
    
    if (contentHeight > containerHeight) {
        CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.scrollView.contentInset.bottom);
        [self.scrollView setContentOffset:bottomOffset animated:YES];
    }
}

- (void)writingCompletedWithContent:(NSString *)content {
    self.isGenerating = NO;
    [self updateUIState];
    
    // 最终处理内容格式
    NSAttributedString *attributedContent = [self processMarkdownToAttributedString:content];
    NSString *finalText = attributedContent.string;
    [self processFinalContent:finalText];
    
    // 计算实际消耗的字数（输入 + 输出）
    NSInteger inputWords = [AIUAWordPackManager countWordsInText:self.prompt ?: @""];
    NSInteger outputWords = [AIUAWordPackManager countWordsInText:finalText];
    NSInteger totalWords = inputWords + outputWords;
    
    if (totalWords > 0) {
        [[AIUAWordPackManager sharedManager] consumeWords:totalWords completion:^(BOOL success, NSInteger remainingWords) {
            if (success) {
                NSLog(@"[Writing] 消耗字数成功: 输入 %ld 字 + 输出 %ld 字 = 总计 %ld 字，剩余: %ld 字", 
                      (long)inputWords, (long)outputWords, (long)totalWords, (long)remainingWords);
            } else {
                NSLog(@"[Writing] 消耗字数失败，剩余: %ld 字", (long)remainingWords);
            }
        }];
    }
    
    // 保存到plist文件
    [self saveWritingToPlist];
    
    // 最终滚动到底部
    [self scrollToBottomIfNeeded];
    
    // 随机触发评分提示（写作完成是一个好时机）
    [AIUAToolsManager tryShowRandomRatingPrompt];
}

- (void)writingCompletedWithError:(NSError *)error {
    self.isGenerating = NO;
    [self updateUIState];
}

- (void)tryExtractTitleFromContent:(NSString *)content {
    NSArray *lines = [content componentsSeparatedByString:@"\n"];
    if (lines.count > 0) {
        NSString *firstLine = [lines firstObject];
        // 放宽标题判断条件，允许更长的标题
        if (firstLine.length > 2 && firstLine.length < 100) {
            // 移除可能的Markdown格式
            NSString *cleanTitle = [AIUAToolsManager removeMarkdownSymbols:firstLine];
            self.titleLabel.text = cleanTitle;
            self.finalTitle = cleanTitle;
            
            // 从内容中移除标题行
            NSMutableArray *remainingLines = [lines mutableCopy];
            [remainingLines removeObjectAtIndex:0];
            NSString *remainingContent = [remainingLines componentsJoinedByString:@"\n"];
            self.contentTextView.text = remainingContent;
        }
    }
}

- (void)processFinalContent:(NSString *)content {
    NSArray *lines = [content componentsSeparatedByString:@"\n"];
    if (lines.count >= 2) {
        NSString *title = [lines firstObject];
        NSMutableArray *contentLines = [lines mutableCopy];
        [contentLines removeObjectAtIndex:0];
        
        NSMutableArray *filteredLines = [NSMutableArray array];
        for (NSString *line in contentLines) {
            if (line.length > 0) {
                [filteredLines addObject:line];
            }
        }
        
        NSString *finalContent = [filteredLines componentsJoinedByString:@"\n"];
        
        // 处理最终内容的格式
        NSString *processedTitle = [AIUAToolsManager removeMarkdownSymbols:title];
        NSString *processedContent = [AIUAToolsManager removeMarkdownSymbols:finalContent];
        
        self.titleLabel.text = processedTitle;
        self.contentTextView.text = processedContent;
        self.finalTitle = processedTitle;
        self.finalContent = processedContent;
    } else {
        NSString *processedContent = [AIUAToolsManager removeMarkdownSymbols:content];
        self.titleLabel.text = L(@"creation_content");
        self.contentTextView.text = processedContent;
        self.finalTitle = L(@"creation_content");
        self.finalContent = processedContent;
    }
}

#pragma mark - 保存到Plist文件

- (void)saveWritingToPlist {
    if (!self.finalTitle || !self.finalContent) {
        NSLog(@"标题或内容为空，无法保存");
        return;
    }
    
    // 如果当前有writingID，先删除旧的记录
    if (self.currentWritingID) {
        [self deleteCurrentWritingRecord];
    }
    
    // 生成新的ID
    self.currentWritingID = [[AIUADataManager sharedManager] generateUniqueID];
    
    self.currentWritingDocParam = @{
        @"id": self.currentWritingID,
        @"title": self.finalTitle ?: @"",
        @"content": self.finalContent ?: @"",
        @"prompt": self.prompt ?: @"",
        @"createTime": [[AIUADataManager sharedManager] currentTimeString],
        @"type": self.type ?: @"",
        @"wordCount": @(self.finalContent.length),
    };
    
    [[AIUADataManager sharedManager] saveWritingToPlist:self.currentWritingDocParam];
}

- (void)deleteCurrentWritingRecord {
    if (!self.currentWritingID) {
        return;
    }
    [[AIUADataManager sharedManager] deleteWritingWithID:self.currentWritingID];
    self.currentWritingID = nil;
}

#pragma mark - 按钮事件

// 停止生成
- (void)stopButtonTapped {
    [self.writer cancelCurrentRequest];
    // 即使停止生成，也保存已生成的内容
    if (self.contentTextView.text.length > 0) {
        self.finalContent = self.contentTextView.text;
        if (!self.finalTitle || self.finalTitle.length == 0) {
            self.finalTitle = L(@"unfinished_creation");
        }
    }
    [self writingCompletedWithContent:self.contentTextView.text ?: @""];
}

// 重新生成
- (void)rewriteButtonTapped {
    [AIUAAlertHelper showAlertWithTitle:L(@"recreate") message:L(@"confirm_regenerate_content") cancelBtnText:L(@"cancel")  confirmBtnText:L(@"confirm")   inController:self cancelAction:nil confirmAction:^{
            [self restartWriting];
    }];
}

// 复制全文
- (void)duplicateButtonTapped {
    NSString *fullText = [NSString stringWithFormat:@"%@\n%@", self.titleLabel.text, self.contentTextView.text];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = fullText;
    [self showToastMessage:L(@"copied_to_clipboard")];
}

// 导出文档
- (void)exportButtonTapped {
    [[AIUADataManager sharedManager] exportDocument:self.titleLabel.text withContent:self.contentTextView.text];
}

// 智能编辑
- (void)editButtonTapped {
    // 跳转到编辑页面
    AIUADocDetailViewController *docDetailVC = [[AIUADocDetailViewController alloc] initWithWritingItem:self.currentWritingDocParam];
    [self.navigationController pushViewController:docDetailVC animated:YES];
}

- (void)restartWriting {
    // 取消当前请求
    [self.writer cancelCurrentRequest];
    
    // 删除当前已生成的内容记录
    [self deleteCurrentWritingRecord];
    
    // 重置UI状态
    [self clearCurrentContent];
    self.contentTextView.textColor = AIUAUIColorRGB(68, 68, 68);
    
    // 重新开始写作
    [self startWriting];
}

#pragma mark - 工具方法

- (void)showToastMessage:(NSString *)message {
    [AIUAMBProgressManager showText:nil withText:message andSubText:nil isBottom:YES backColor:[UIColor grayColor]];
}

#pragma mark - 内存管理

- (void)dealloc {
    [self.writer cancelCurrentRequest];
}

@end
