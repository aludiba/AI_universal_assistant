#import "AIUADocDetailViewController.h"
#import "AIUADataManager.h"
#import "AIUAAlertHelper.h"
#import "AIUAMBProgressManager.h"
#import "AIUAToolsManager.h"
#import "AIUAVIPManager.h"
#import "AIUAWordPackManager.h"
#import "AIUAWordPackViewController.h"
#import "UITextView+AIUAPlaceholder.h"
#import <Masonry/Masonry.h>
#import <MBProgressHUD/MBProgressHUD.h>

@interface AIUADocDetailViewController () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextView *titleTextView;
@property (nonatomic, strong) UITextView *contentTextView;
@property (nonatomic, assign) CGFloat ContentTextViewHeight;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *toolbarView;

@property (nonatomic, copy) NSDictionary *writingItem; // 编辑模式下的原始数据
@property (nonatomic, assign) BOOL isNewDocument; // 是否为新建文档
@property (nonatomic, assign) BOOL hasUserEdited; // 用户是否编辑过

@property (nonatomic, copy) NSString *currentTitle;
@property (nonatomic, copy) NSString *currentContent;

@property (nonatomic, strong) NSMutableArray *toolbarButtonsArray;
// 编辑工具栏按钮
@property (nonatomic, strong) UIButton *continueWriteBtn;
@property (nonatomic, strong) UIButton *rewriteBtn;
@property (nonatomic, strong) UIButton *expandBtn;
@property (nonatomic, strong) UIButton *translateBtn;

// 风格选择
@property (nonatomic, strong) UIView *styleSelectionView;
@property (nonatomic, strong) NSArray *selectionStyles;
@property (nonatomic, assign) AIUAWritingEditType currentEditType;
@property (nonatomic, copy) NSString *selectedStyle;
@property (nonatomic, copy) NSString *selectedLength; // 扩写长度
@property (nonatomic, copy) NSString *selectedLanguage; // 翻译语言

// 流式生成相关
@property (nonatomic, assign) BOOL isGenerating;
@property (nonatomic, strong) NSMutableString *generatedContent;
@property (nonatomic, strong) UITextView *generationTextView; // 生成内容显示框
@property (nonatomic, strong) UIView *generationView; // 生成内容容器
@property (nonatomic, assign) AIUAWritingEditType type; // 写作类型
@property (nonatomic, strong) UIButton *stopButton; // 停止生成按钮
@property (nonatomic, strong) UIStackView *currentButtonStack; // 当前的结果按钮堆栈
@property (nonatomic, strong) UIButton *generationBackButton; // 生成视图中的返回按钮
// 键盘相关
@property (nonatomic, assign) CGFloat keyboardHeight;

@property (nonatomic, assign) BOOL isDeleteDocumentSuccess; // 是否删除文档成功
@end

@implementation AIUADocDetailViewController

- (instancetype)initWithNewDocument {
    self = [super init];
    if (self) {
        _isNewDocument = YES;
        _hasUserEdited = NO;
        _currentTitle = @"";
        _currentContent = @"";
        _selectedStyle = L(@"general");
        _selectedLength = L(@"medium");
        _selectedLanguage = L(@"english");
        [self setupDeepSeekWriter];
    }
    return self;
}

- (instancetype)initWithWritingItem:(NSDictionary *)writingItem {
    self = [super init];
    if (self) {
        _writingItem = writingItem;
        _isNewDocument = NO;
        _hasUserEdited = NO;
        _currentTitle = writingItem[@"title"] ?: @"";
        _currentContent = writingItem[@"content"] ?: @"";
        _selectedStyle = L(@"general");
        _selectedLength = L(@"medium");
        _selectedLanguage = L(@"english");
        [self setupDeepSeekWriter];
    }
    return self;
}

- (void)setupDeepSeekWriter {
    // 从配置或用户设置中获取API Key
    NSString *apiKey = APIKEY;
    if (apiKey && apiKey.length > 0) {
        self.deepSeekWriter = [[AIUADeepSeekWriter alloc] initWithAPIKey:apiKey];
    } else {
        // 如果没有配置API Key，创建一个空的writer，会在使用时提示
        self.deepSeekWriter = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!self.isDeleteDocumentSuccess) {
        [self saveDocumentIfNeeded];
        [self cancelCurrentGeneration];
    }
}

- (void)dealloc
{
    [self unregisterKeyboardNotifications];
}

- (void)setupNavigationBar {
    if (self.isNewDocument) {
        self.navigationItem.title = L(@"new_document");
    } else {
        self.navigationItem.title = L(@"document_details");
    }
    UIImage *ellipsisIcon = [UIImage systemImageNamed:@"ellipsis"];
    UIBarButtonItem *ellipsisButton = [[UIBarButtonItem alloc] initWithImage:ellipsisIcon style:UIBarButtonItemStylePlain target:self action:@selector(ellipsisTapped)];
    ellipsisButton.tintColor = AIUA_LABEL_COLOR; // 使用系统标签颜色，自动适配暗黑模式
    self.navigationItem.rightBarButtonItem = ellipsisButton;
}

- (void)setupUI {
    [super setupUI];
    [self setupTableView];
    [self setupHeaderView];
    [self setupContentTextView];
    [self setupToolbarView];
    [self setupStyleSelectionView];
    [self setupGenerationView];
    [self setupNavigationBar];
    [self setupGestureRecognizer];
    [self registerKeyboardNotifications];
    [self setupInputAccessoryView];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = AIUA_BACK_COLOR; // 使用系统背景色，自动适配暗黑模式
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-60);
    }];
}

- (void)setupHeaderView {
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 80)];
    self.headerView.backgroundColor = [UIColor clearColor];
    
    // 标题输入框
    self.titleTextView = [[UITextView alloc] init];
    self.titleTextView.font = AIUAUIFontBold(20);
    self.titleTextView.textColor = AIUA_LABEL_COLOR; // 使用系统标签颜色，自动适配暗黑模式
    self.titleTextView.backgroundColor = [UIColor clearColor];
    self.titleTextView.scrollEnabled = NO; // 禁用滚动，限制为两行
    self.titleTextView.delegate = self;
    self.titleTextView.text = self.currentTitle;
    self.titleTextView.placeholder = L(@"enter_title");
    self.titleTextView.placeholderColor = AIUA_SECONDARY_LABEL_COLOR; // 使用系统二级标签颜色，自动适配暗黑模式
    // 限制最大行数为2行
    self.titleTextView.textContainer.maximumNumberOfLines = 2;
    self.titleTextView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.headerView addSubview:self.titleTextView];
    
    [self.titleTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView).offset(16);
        make.left.equalTo(self.headerView).offset(16);
        make.right.equalTo(self.headerView).offset(-16);
        make.height.greaterThanOrEqualTo(@40);
    }];
    
    // 分隔线（靠底部）
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = AIUA_DIVIDER_COLOR;
    [self.headerView addSubview:separator];
    
    [separator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.headerView);
        make.bottom.equalTo(self.headerView);
        make.height.equalTo(@1);
    }];
    
    self.tableView.tableHeaderView = self.headerView;
}

- (void)setupContentTextView  {
    self.contentTextView = [[UITextView alloc] init];
    self.contentTextView.font = AIUAUIFontSystem(16);
    self.contentTextView.textColor = AIUA_LABEL_COLOR; // 使用系统标签颜色，自动适配暗黑模式
    self.contentTextView.backgroundColor = [UIColor clearColor];
    self.contentTextView.delegate = self;
    self.contentTextView.text = self.currentContent;
    self.contentTextView.placeholder = L(@"enter_main_text");
    self.contentTextView.placeholderColor = AIUA_SECONDARY_LABEL_COLOR; // 使用系统二级标签颜色，自动适配暗黑模式
    self.contentTextView.scrollEnabled = NO;
    self.ContentTextViewHeight = [self getContentTextViewHeight];
}

- (void)setupToolbarView {
    self.toolbarView = [[UIView alloc] init];
    // 使用动态颜色，适配暗黑模式
    self.toolbarView.backgroundColor = AIUA_DynamicColor(
        AIUAUIColorSimplifyRGB(0.95, 0.95, 0.95),  // 浅色模式：浅灰色
        AIUAUIColorSimplifyRGB(0.15, 0.15, 0.15)   // 暗黑模式：深灰色
    );
    [self.view addSubview:self.toolbarView];
    
    [self.toolbarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.equalTo(@60);
    }];
    
    // 创建工具栏按钮
    [self createToolbarButtons];
}

- (void)createToolbarButtons {
    self.toolbarButtonsArray = [[NSMutableArray alloc] init];
    NSArray *buttonTitles = @[L(@"continue_writing"), L(@"rewrite"), L(@"expand_writing"), L(@"translate")];
    NSArray *buttonIcons = @[@"pencil", @"pencil.tip", @"text.badge.plus", @"character"];
    
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = 0;
    [self.toolbarView addSubview:stackView];
    
    [stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.toolbarView);
    }];
    
    for (int i = 0; i < buttonTitles.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = i;
        [button setTitle:buttonTitles[i] forState:UIControlStateNormal];
        [button setTitleColor:AIUA_LABEL_COLOR forState:UIControlStateNormal]; // 使用系统标签颜色，自动适配暗黑模式
        button.titleLabel.font = AIUAUIFontSystem(12);
        
        // 设置图标
        UIImage *icon = [UIImage systemImageNamed:buttonIcons[i]];
        [button setImage:icon forState:UIControlStateNormal];
        button.tintColor = AIUA_LABEL_COLOR; // 使用系统标签颜色，自动适配暗黑模式
        
        // 调整图片和文字的位置
        button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 4);
        button.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
        
        [button addTarget:self action:@selector(toolbarButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [stackView addArrangedSubview:button];
        [self.toolbarButtonsArray addObject:button];
        // 保存按钮引用
        switch (i) {
            case 0: self.continueWriteBtn = button; break;
            case 1: self.rewriteBtn = button; break;
            case 2: self.expandBtn = button; break;
            case 3: self.translateBtn = button; break;
        }
    }
}

- (void)setupStyleSelectionView {
    self.styleSelectionView = [[UIView alloc] init];
    // 使用动态颜色，适配暗黑模式
    self.styleSelectionView.backgroundColor = AIUA_DynamicColor(
        AIUAUIColorSimplifyRGB(0.98, 0.98, 0.98),  // 浅色模式：浅灰色
        AIUAUIColorSimplifyRGB(0.15, 0.15, 0.15)   // 暗黑模式：深灰色
    );
    self.styleSelectionView.hidden = YES;
    [self.view addSubview:self.styleSelectionView];
    
    [self.styleSelectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.toolbarView.mas_top);
        make.height.equalTo(@160);
    }];
    
    // 创建标题容器
    UIView *titleContainer = [[UIView alloc] init];
    [self.styleSelectionView addSubview:titleContainer];
    
    [titleContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.styleSelectionView).offset(8);
        make.left.right.equalTo(self.styleSelectionView);
        make.height.equalTo(@30);
    }];
    
    // 添加返回按钮
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [backButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
    [backButton setTintColor:[UIColor systemGrayColor]];
    [backButton addTarget:self action:@selector(hideAllSelectionViews) forControlEvents:UIControlEventTouchUpInside];
    [titleContainer addSubview:backButton];
    
    [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleContainer).offset(16);
        make.centerY.equalTo(titleContainer);
        make.width.height.equalTo(@24);
    }];
    
    // 添加标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = AIUAUIFontSystem(14);
    titleLabel.textColor = AIUA_LABEL_COLOR; // 使用系统标签颜色，自动适配暗黑模式
    [titleContainer addSubview:titleLabel];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(backButton.mas_right).offset(8);
        make.centerY.equalTo(titleContainer);
    }];
    
    // 风格选择容器
    UIView *styleContainer = [[UIView alloc] init];
    [self.styleSelectionView addSubview:styleContainer];
    
    [styleContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(8);
        make.left.right.equalTo(self.styleSelectionView);
        make.height.equalTo(@40);
    }];
    
    // 风格选择按钮
    self.selectionStyles = @[L(@"general"), L(@"news"), L(@"academic"), L(@"official"), L(@"novel"), L(@"essay")];
    UIStackView *styleStackView = [[UIStackView alloc] init];
    styleStackView.axis = UILayoutConstraintAxisHorizontal;
    styleStackView.distribution = UIStackViewDistributionFillEqually;
    styleStackView.alignment = UIStackViewAlignmentCenter;
    styleStackView.spacing = 8;
    [styleContainer addSubview:styleStackView];
    
    [styleStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(styleContainer).insets(UIEdgeInsetsMake(0, 16, 0, 16));
    }];
    
    for (NSString *style in self.selectionStyles) {
        UIButton *styleButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [styleButton setTitle:style forState:UIControlStateNormal];
        [styleButton setTitleColor:AIUA_LABEL_COLOR forState:UIControlStateNormal]; // 使用系统标签颜色，自动适配暗黑模式
        styleButton.titleLabel.font = AIUAUIFontSystem(14);
        styleButton.backgroundColor = AIUA_CARD_BACKGROUND_COLOR; // 使用系统卡片背景色，自动适配暗黑模式
        styleButton.layer.cornerRadius = 6;
        styleButton.layer.borderWidth = 1;
        styleButton.layer.borderColor = AIUA_DIVIDER_COLOR.CGColor;
        [styleButton addTarget:self action:@selector(styleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [styleStackView addArrangedSubview:styleButton];
        
        // 默认选中第一个
        if ([style isEqualToString:L(@"general")]) {
            [self styleButtonTapped:styleButton];
        }
    }
    
    // 开始按钮
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [startButton setTitle:L(@"start_generating") forState:UIControlStateNormal];
    [startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    startButton.backgroundColor = [UIColor systemBlueColor];
    startButton.layer.cornerRadius = 6;
    startButton.titleLabel.font = AIUAUIFontBold(16);
    [startButton addTarget:self action:@selector(startGeneration) forControlEvents:UIControlEventTouchUpInside];
    [self.styleSelectionView addSubview:startButton];
    
    [startButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(styleContainer.mas_bottom).offset(16);
        make.left.equalTo(self.styleSelectionView).offset(16);
        make.right.equalTo(self.styleSelectionView).offset(-16);
        make.height.equalTo(@44);
    }];
}

- (void)setupGenerationView {
    self.generationView = [[UIView alloc] init];
    // 使用动态颜色，适配暗黑模式
    self.generationView.backgroundColor = AIUA_DynamicColor(
        AIUAUIColorSimplifyRGB(0.98, 0.98, 0.98),  // 浅色模式：浅灰色
        AIUAUIColorSimplifyRGB(0.15, 0.15, 0.15)   // 暗黑模式：深灰色
    );
    self.generationView.hidden = YES;
    [self.view addSubview:self.generationView];
    
    [self.generationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.toolbarView.mas_top);
        make.height.equalTo(@200);
    }];
    
    // 停止生成按钮（适配暗黑模式）
    UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
    config.image = [self stopButtonImage];
    config.imagePadding = 4;
    config.baseForegroundColor = AIUAUIColorRGB(239, 68, 68);
    // 使用动态颜色，适配暗黑模式
    config.background.backgroundColor = AIUA_DynamicColor(
        AIUAUIColorRGB(254, 242, 242),  // 浅色模式：浅红色
        AIUAUIColorRGB(75, 5, 5)         // 暗黑模式：深红色
    );
    config.contentInsets = NSDirectionalEdgeInsetsMake(8, 16, 8, 16);
    config.cornerStyle = UIButtonConfigurationCornerStyleMedium;

    UIButton *stopButton = [UIButton buttonWithType:UIButtonTypeSystem];
    stopButton.configuration = config;
    stopButton.layer.cornerRadius = 6;
    stopButton.layer.borderWidth = 1;
    // 使用动态颜色，适配暗黑模式
    stopButton.layer.borderColor = AIUA_DynamicColor(
        AIUAUIColorRGB(254, 202, 202),  // 浅色模式：浅红色边框
        AIUAUIColorRGB(120, 20, 20)     // 暗黑模式：深红色边框
    ).CGColor;
    stopButton.hidden = YES;
    [stopButton addTarget:self action:@selector(stopButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.stopButton = stopButton;
    // 停止按钮添加到generationView中，和buttonStack在同一个父视图
    [self.generationView addSubview:stopButton];
    [self.stopButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.generationView);
        make.bottom.lessThanOrEqualTo(self.generationView.mas_bottom).offset(-5);
        make.width.equalTo(@30);
        make.height.equalTo(@30);
    }];
    
    // 创建标题容器
    UIView *titleContainer = [[UIView alloc] init];
    [self.generationView addSubview:titleContainer];
    
    [titleContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.generationView).offset(8);
        make.left.right.equalTo(self.generationView);
        make.height.equalTo(@30);
    }];
    
    // 添加返回按钮
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [backButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
    [backButton setTintColor:[UIColor systemGrayColor]];
    [backButton addTarget:self action:@selector(showStyleSelectionView) forControlEvents:UIControlEventTouchUpInside];
    [titleContainer addSubview:backButton];
    self.generationBackButton = backButton; // 保存引用
    
    [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleContainer).offset(16);
        make.centerY.equalTo(titleContainer);
        make.width.height.equalTo(@24);
    }];
    
    // 生成内容标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = L(@"generated_content");
    titleLabel.font = AIUAUIFontSystem(14);
    titleLabel.textColor = AIUA_LABEL_COLOR; // 使用系统标签颜色，自动适配暗黑模式
    [titleContainer addSubview:titleLabel];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(backButton.mas_right).offset(8);
        make.centerY.equalTo(titleContainer);
    }];
    
    
    // 生成内容文本框
    self.generationTextView = [[UITextView alloc] init];
    self.generationTextView.font = AIUAUIFontSystem(14);
    self.generationTextView.textColor = AIUA_LABEL_COLOR; // 使用系统标签颜色，自动适配暗黑模式
    self.generationTextView.backgroundColor = AIUA_CARD_BACKGROUND_COLOR; // 使用系统卡片背景色，自动适配暗黑模式
    self.generationTextView.layer.cornerRadius = 6;
    self.generationTextView.layer.borderWidth = 1;
    self.generationTextView.layer.borderColor = AIUA_DIVIDER_COLOR.CGColor;
    self.generationTextView.editable = NO;
    self.generationTextView.scrollEnabled = YES;
    [self.generationView addSubview:self.generationTextView];
    
    [self.generationTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(8);
        make.left.equalTo(self.generationView).offset(16);
        make.right.equalTo(self.generationView).offset(-16);
        make.height.equalTo(@120);
    }];
}

- (void)updateStyleSelectionForType:(AIUAWritingEditType)type {
    UIView *titleContainer = self.styleSelectionView.subviews[0];
    // 根据类型更新风格选择界面
    UIView *styleContainer = self.styleSelectionView.subviews[1]; // 获取风格容器
    if (type == AIUAWritingEditTypeExpand) {
        // 扩写模式：显示扩写长度选择
        UILabel *titleLabel = titleContainer.subviews[1];
        titleLabel.text = L(@"expansion_length");
        // 移除原有风格按钮
        for (UIView *subview in styleContainer.subviews) {
            [subview removeFromSuperview];
        }
        // 添加扩写长度选择
        NSArray *lengths = @[L(@"medium"), L(@"longer")];
        UIStackView *lengthStackView = [[UIStackView alloc] init];
        lengthStackView.axis = UILayoutConstraintAxisHorizontal;
        lengthStackView.distribution = UIStackViewDistributionFillEqually;
        lengthStackView.alignment = UIStackViewAlignmentCenter;
        lengthStackView.spacing = 8;
        [styleContainer addSubview:lengthStackView];
        [lengthStackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(styleContainer).insets(UIEdgeInsetsMake(0, 16, 0, 16));
        }];
        for (NSString *length in lengths) {
            UIButton *lengthButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [lengthButton setTitle:length forState:UIControlStateNormal];
            [lengthButton setTitleColor:AIUA_LABEL_COLOR forState:UIControlStateNormal]; // 使用系统标签颜色，自动适配暗黑模式
            lengthButton.titleLabel.font = AIUAUIFontSystem(14);
            lengthButton.backgroundColor = AIUA_CARD_BACKGROUND_COLOR; // 使用系统卡片背景色，自动适配暗黑模式
            lengthButton.layer.cornerRadius = 6;
            lengthButton.layer.borderWidth = 1;
            lengthButton.layer.borderColor = AIUA_DIVIDER_COLOR.CGColor;
            [lengthButton addTarget:self action:@selector(lengthButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [lengthStackView addArrangedSubview:lengthButton];
            
            // 默认选中第一个
            if ([length isEqualToString:L(@"medium")]) {
                [self lengthButtonTapped:lengthButton];
            }
        }
        
    } else if (type == AIUAWritingEditTypeTranslate) {
        // 翻译模式：显示目标语言选择
        UILabel *titleLabel = titleContainer.subviews[1];
        titleLabel.text = L(@"target_language");
        // 移除原有风格按钮
        for (UIView *subview in styleContainer.subviews) {
            [subview removeFromSuperview];
        }
        // 添加语言选择
        NSArray *languages = @[L(@"english"), L(@"chinese"), L(@"japanese")];
        UIStackView *languageStackView = [[UIStackView alloc] init];
        languageStackView.axis = UILayoutConstraintAxisHorizontal;
        languageStackView.distribution = UIStackViewDistributionFillEqually;
        languageStackView.alignment = UIStackViewAlignmentCenter;
        languageStackView.spacing = 8;
        [styleContainer addSubview:languageStackView];
        [languageStackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(styleContainer).insets(UIEdgeInsetsMake(0, 16, 0, 16));
        }];
        for (NSString *language in languages) {
            UIButton *languageButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [languageButton setTitle:language forState:UIControlStateNormal];
            [languageButton setTitleColor:AIUA_LABEL_COLOR forState:UIControlStateNormal]; // 使用系统标签颜色，自动适配暗黑模式
            languageButton.titleLabel.font = AIUAUIFontSystem(14);
            languageButton.backgroundColor = AIUA_CARD_BACKGROUND_COLOR; // 使用系统卡片背景色，自动适配暗黑模式
            languageButton.layer.cornerRadius = 6;
            languageButton.layer.borderWidth = 1;
            languageButton.layer.borderColor = AIUA_DIVIDER_COLOR.CGColor;
            [languageButton addTarget:self action:@selector(languageButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [languageStackView addArrangedSubview:languageButton];
            
            // 默认选中第一个
            if ([language isEqualToString:L(@"english")]) {
                [self languageButtonTapped:languageButton];
            }
        }
        
    } else {
        // 其他模式：显示风格选择
        UILabel *titleLabel = titleContainer.subviews[1];
        NSString *title = L(@"select_style");
        if (type == AIUAWritingEditTypeContinue) {
            title = L(@"continuation_style");
        } else if (type == AIUAWritingEditTypeRewrite) {
            title = L(@"rewrite_style");
        }
        titleLabel.text = title;
        for (UIView *subview in styleContainer.subviews) {
            [subview removeFromSuperview];
        }
        // 如果已经移除，重新创建风格选择
        UIStackView *styleStackView = [[UIStackView alloc] init];
        styleStackView.axis = UILayoutConstraintAxisHorizontal;
        styleStackView.distribution = UIStackViewDistributionFillEqually;
        styleStackView.alignment = UIStackViewAlignmentCenter;
        styleStackView.spacing = 8;
        [styleContainer addSubview:styleStackView];
        [styleStackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(styleContainer).insets(UIEdgeInsetsMake(0, 16, 0, 16));
        }];
        for (NSString *style in self.selectionStyles) {
            UIButton *styleButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [styleButton setTitle:style forState:UIControlStateNormal];
            [styleButton setTitleColor:AIUA_LABEL_COLOR forState:UIControlStateNormal]; // 使用系统标签颜色，自动适配暗黑模式
            styleButton.titleLabel.font = AIUAUIFontSystem(14);
            styleButton.backgroundColor = AIUA_CARD_BACKGROUND_COLOR; // 使用系统卡片背景色，自动适配暗黑模式
            styleButton.layer.cornerRadius = 6;
            styleButton.layer.borderWidth = 1;
            styleButton.layer.borderColor = AIUA_DIVIDER_COLOR.CGColor;
            [styleButton addTarget:self action:@selector(styleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [styleStackView addArrangedSubview:styleButton];
            // 默认选中第一个
            if ([style isEqualToString:L(@"general")]) {
                [self styleButtonTapped:styleButton];
            }
        }
    }
}

- (void)removeResultButtons {
    UIStackView *stack = nil;
    // 移除原有按钮
    for (UIView *subview in self.generationView.subviews) {
        if ([subview isKindOfClass:[UIStackView  class]]) {
            stack = (UIStackView *)subview;
            break;
        }
    }
    for (UIView *subview in stack.arrangedSubviews) {
        if ([subview isKindOfClass:[UIButton  class]]) {
            [subview removeFromSuperview];
        }
    }
}

- (void)setupResultButtonsForType:(AIUAWritingEditType)type {
    self.type = type;
    if (!self.currentButtonStack) {
        // 创建新的操作按钮
        UIStackView *buttonStack = [[UIStackView alloc] init];
        buttonStack.axis = UILayoutConstraintAxisHorizontal;
        buttonStack.distribution = UIStackViewDistributionFillEqually;
        buttonStack.alignment = UIStackViewAlignmentCenter;
        buttonStack.spacing = 16;
        [self.generationView addSubview:buttonStack];
        [buttonStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.generationTextView.mas_bottom).offset(8);
            make.left.equalTo(self.generationView).offset(16);
            make.right.equalTo(self.generationView).offset(-16);
            make.height.equalTo(@44);
        }];
        // 保存buttonStack引用
        self.currentButtonStack = buttonStack;
    }
    
    if (self.currentButtonStack) {
        // 移除旧的Button
        for (id obj in self.currentButtonStack.subviews) {
            if ([obj isKindOfClass:[UIButton class]]) {
                [obj removeFromSuperview];
            }
        }
        // 重新生成按钮（所有类型都有）
        UIButton *regenerateButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [regenerateButton setTitle:L(@"regenerate") forState:UIControlStateNormal];
        [regenerateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        regenerateButton.backgroundColor = [UIColor systemBlueColor];
        regenerateButton.layer.cornerRadius = 6;
        regenerateButton.layer.borderWidth = 1;
        regenerateButton.layer.borderColor = [UIColor systemBlueColor].CGColor;
        [regenerateButton addTarget:self action:@selector(regenerateContent) forControlEvents:UIControlEventTouchUpInside];
        [self.currentButtonStack addArrangedSubview:regenerateButton];
        
        // 插入按钮（所有类型都有）
        UIButton *insertButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [insertButton setTitle:L(@"insert") forState:UIControlStateNormal];
        [insertButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        insertButton.backgroundColor = [UIColor systemBlueColor];
        insertButton.layer.cornerRadius = 6;
        [insertButton addTarget:self action:@selector(insertGeneratedContent) forControlEvents:UIControlEventTouchUpInside];
        [self.currentButtonStack addArrangedSubview:insertButton];
        
        // 改写和扩写有覆盖原文按钮
        if (type == AIUAWritingEditTypeRewrite || type == AIUAWritingEditTypeExpand || type == AIUAWritingEditTypeTranslate) {
            UIButton *coverButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [coverButton setTitle:L(@"overwrite_original") forState:UIControlStateNormal];
            [coverButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            coverButton.backgroundColor = [UIColor systemBlueColor];
            coverButton.layer.cornerRadius = 6;
            coverButton.layer.borderWidth = 1;
            coverButton.layer.borderColor = [UIColor systemBlueColor].CGColor;
            [coverButton addTarget:self action:@selector(coverOriginalContent) forControlEvents:UIControlEventTouchUpInside];
            [self.currentButtonStack addArrangedSubview:coverButton];
            // 调整布局为三个按钮
            self.currentButtonStack.distribution = UIStackViewDistributionFillEqually;
        }
    }
}

// 键盘添加完成按钮
- (void)setupInputAccessoryView {
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    toolbar.barStyle = UIBarStyleDefault;
    toolbar.translucent = YES;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:L(@"action_complete")
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(dismissKeyboard)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
    
    [toolbar setItems:@[flexibleSpace, doneButton]];
    
    self.titleTextView.inputAccessoryView = toolbar;
    self.contentTextView.inputAccessoryView = toolbar;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContentCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ContentCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [cell.contentView addSubview:self.contentTextView];
        
        [self.contentTextView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(cell.contentView).insets(UIEdgeInsetsMake(8, 16, 8, 16));
        }];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.ContentTextViewHeight + 16;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // 限制标题输入框最多两行
    if (textView == self.titleTextView) {
        // 如果输入的是换行符，检查是否已经有两行
        if ([text isEqualToString:@"\n"]) {
            // 计算当前文本的行数（通过换行符数量）
            NSUInteger lineCount = [[textView.text componentsSeparatedByString:@"\n"] count];
            if (lineCount >= 2) {
                return NO; // 已经两行，禁止输入换行符
            }
        }
        
        // 计算输入后的文本
        NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
        
        // 使用 sizeThatFits 计算新文本的高度
        CGSize textSize = [newText boundingRectWithSize:CGSizeMake(textView.frame.size.width - textView.textContainerInset.left - textView.textContainerInset.right, CGFLOAT_MAX)
                                                 options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                              attributes:@{NSFontAttributeName: textView.font}
                                                 context:nil].size;
        
        // 计算单行高度
        CGFloat singleLineHeight = textView.font.lineHeight;
        // 两行的最大高度（考虑行间距）
        CGFloat maxHeight = singleLineHeight * 2 + textView.font.leading;
        
        // 如果新文本高度超过两行，禁止输入
        if (textSize.height > maxHeight) {
            return NO;
        }
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.hasUserEdited = YES;
    
    if (textView == self.titleTextView) {
        self.currentTitle = textView.text;
    } else if (textView == self.contentTextView) {
        self.currentContent = textView.text;
    }
    self.ContentTextViewHeight = [self getContentTextViewHeight];
    [UIView performWithoutAnimation:^{
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }];
}

#pragma mark - 键盘处理

- (void)registerKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)unregisterKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat riseHeight = [self riseHeight:keyboardFrame.size.height];
    NSLog(@"keyboardWillShow-riseHeight:%lf", riseHeight);
    [UIView animateWithDuration:0.3 animations:^{
        [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view).offset(-riseHeight);
        }];
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    CGFloat riseHeight = [self riseHeight:60];
    NSLog(@"keyboardWillHide-riseHeight:%lf", riseHeight);
    [UIView animateWithDuration:0.3 animations:^{
        [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view).offset(-riseHeight);
        }];
        [self.view layoutIfNeeded];
    }];
}

- (CGFloat)riseHeight:(CGFloat)height {
    CGFloat riseHeight = height;
    if (self.styleSelectionView.isHidden == NO) {
        riseHeight = MAX(riseHeight, 220);
    }
    if (self.generationView.isHidden == NO) {
        riseHeight = MAX(riseHeight, 260);
    }
    return riseHeight;
}

#pragma mark - Actions

// 更多：导出文档、复制全文、删除文档
- (void)ellipsisTapped {
    [self updateWritingItem];
    NSArray *actions;
    if (self.isNewDocument) {
        actions = @[
               @{@"title": L(@"export_document"), @"style": @(UIAlertActionStyleDefault)},
               @{@"title": L(@"copy_full_text"), @"style": @(UIAlertActionStyleDefault)}
           ];
    } else {
        actions = @[
               @{@"title": L(@"export_document"), @"style": @(UIAlertActionStyleDefault)},
               @{@"title": L(@"copy_full_text"), @"style": @(UIAlertActionStyleDefault)},
               @{@"title": L(@"delete_document"), @"style": @(UIAlertActionStyleDestructive)}
           ];
    }
    [AIUAAlertHelper showActionWithTitle:nil
                                            message:nil
                                            actions:actions
                                      preferredStyle:UIAlertControllerStyleAlert
                                      inController:self
                                      actionHandler:^(NSString *actionTitle) {
        [self handleAction:actionTitle forDocument:self.writingItem];
    }];
}

- (void)handleAction:(NSString *)actionTitle forDocument:(NSDictionary *)document{
    if ([actionTitle isEqualToString:L(@"export_document")]) {
        [self exportDocument:document];
    } else if ([actionTitle isEqualToString:L(@"copy_full_text")]) {
        [self copyFullText:document];
    } else if ([actionTitle isEqualToString:L(@"delete_document")]) {
        [self deleteDocument:document];
    }
}

// 增强版导出方法
- (void)exportDocument:(NSDictionary *)document {
    NSString *content = document[@"content"] ?: @"";
    if (content.length > 0) {
        [[AIUADataManager sharedManager] exportDocument:document[@"title"] ?: @"" withContent:document[@"content"] ?: @""];
    } else {
        [AIUAAlertHelper showAlertWithTitle:L(@"prompt")
                                   message:L(@"please_enter_content_first")
                             cancelBtnText:nil
                            confirmBtnText:L(@"confirm")
                              inController:self
                              cancelAction:nil
                             confirmAction:nil];
    }
}


- (void)copyFullText:(NSDictionary *)document {
    NSString *content = document[@"content"] ?: @"";
    if (content.length > 0) {
        [UIPasteboard generalPasteboard].string = [NSString stringWithFormat:@"%@\n%@", document[@"title"] ?: @"", content];
        // 使用动态颜色，适配暗黑模式
        [AIUAMBProgressManager showText:nil withText:L(@"copied_to_clipboard") andSubText:nil isBottom:NO backColor:AIUA_DynamicColor([UIColor whiteColor], [UIColor blackColor])];
    } else {
        [AIUAAlertHelper showAlertWithTitle:L(@"prompt")
                                   message:L(@"please_enter_content_first")
                             cancelBtnText:nil
                            confirmBtnText:L(@"confirm")
                              inController:self
                              cancelAction:nil
                             confirmAction:nil];
    }
}

- (void)deleteDocument:(NSDictionary *)document {
    NSString *documentID = document[@"id"];
    
    if (!documentID) {
        NSLog(@"Error: Document ID is nil");
        return;
    }
    
    WeakType(self);
    [AIUAAlertHelper showAlertWithTitle:L(@"confirm_delete")
                                message:L(@"confirm_delete_document")
                          cancelBtnText:L(@"cancel")
                         confirmBtnText:L(@"delete")
                           inController:self
                           cancelAction:nil
                         confirmAction:^{
        StrongType(self);
        BOOL success = [[AIUADataManager sharedManager] deleteWritingWithID:documentID];
        if (success) {
            strongself.isDeleteDocumentSuccess = YES;
            [strongself.navigationController popViewControllerAnimated:YES];
            // 使用动态颜色，适配暗黑模式
            [AIUAMBProgressManager showText:nil withText:L(@"deleted_success") andSubText:nil isBottom:NO backColor:AIUA_DynamicColor([UIColor whiteColor], [UIColor blackColor])];
        } else {
            // 使用动态颜色，适配暗黑模式
            [AIUAMBProgressManager showText:nil withText:L(@"delete_failed") andSubText:nil isBottom:NO backColor:AIUA_DynamicColor([UIColor whiteColor], [UIColor blackColor])];
        }
    }];
}

- (CGFloat)getContentTextViewHeight {
    if (self.currentContent.length > 0) {
        CGSize sizeThatFits = [self.contentTextView sizeThatFits:CGSizeMake(AIUAScreenWidth - 32, CGFLOAT_MAX)];
        return sizeThatFits.height;
    } else {
        return 300;
    }
}

- (void)toolbarButtonTapped:(UIButton *)sender {
    // 检查VIP权限
    NSArray *featureNames = @[L(@"continue_writing"), L(@"rewrite"), L(@"expand_writing"), L(@"translate")];
    NSString *featureName = sender.tag < featureNames.count ? featureNames[sender.tag] : @"";
    
    [[AIUAVIPManager sharedManager] checkVIPPermissionWithViewController:self featureName:featureName completion:^(BOOL hasPermission) {
        if (!hasPermission) {
            // 无权限，已显示弹窗
            return;
        }
        
        // 有权限，执行原有逻辑
        if (!self.hasUserEdited && self.isNewDocument) {
            [AIUAAlertHelper showAlertWithTitle:L(@"prompt")
                                       message:L(@"please_enter_content_first")
                                 cancelBtnText:nil
                                confirmBtnText:L(@"confirm")
                                  inController:self
                                  cancelAction:nil
                                 confirmAction:nil];
            return;
        }
        
        if (self.currentContent.length == 0) {
            [AIUAAlertHelper showAlertWithTitle:L(@"prompt")
                                       message:L(@"please_enter_main_content_firs")
                                 cancelBtnText:nil
                                confirmBtnText:L(@"confirm")
                                  inController:self
                                  cancelAction:nil
                                 confirmAction:nil];
            return;
        }
        
        // 检查DeepSeek配置
        if (!self.deepSeekWriter) {
            [AIUAAlertHelper showAlertWithTitle:L(@"config_error")
                                       message:L(@"please_configure_deepseek_api_key_first")
                                 cancelBtnText:nil
                                confirmBtnText:L(@"confirm")
                                  inController:self
                                  cancelAction:nil
                                 confirmAction:nil];
            return;
        }
        
        for (int i = 0; i < self.toolbarButtonsArray.count; i++) {
            UIButton *button = self.toolbarButtonsArray[i];
            if (sender.tag == button.tag) {
                [button setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
                button.tintColor = [UIColor systemBlueColor];
            } else {
                [button setTitleColor:AIUA_LABEL_COLOR forState:UIControlStateNormal]; // 使用系统标签颜色，自动适配暗黑模式
                button.tintColor = AIUA_LABEL_COLOR; // 使用系统标签颜色，自动适配暗黑模式
            }
        }
        
        self.currentEditType = (AIUAWritingEditType)sender.tag;
        
        // 根据类型更新界面
        [self updateStyleSelectionForType:self.currentEditType];
        
        // 显示风格选择视图
        [self showStyleSelectionView];
    }];
}

- (void)styleButtonTapped:(UIButton *)sender {
    self.selectedStyle = sender.titleLabel.text;
    
    // 更新按钮选中状态
    for (UIView *view in sender.superview.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;
            if (button == sender) {
                button.backgroundColor = [UIColor systemBlueColor];
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            } else {
                button.backgroundColor = AIUA_CARD_BACKGROUND_COLOR; // 使用系统卡片背景色，自动适配暗黑模式
                [button setTitleColor:AIUA_LABEL_COLOR forState:UIControlStateNormal]; // 使用系统标签颜色，自动适配暗黑模式
            }
        }
    }
}

- (void)lengthButtonTapped:(UIButton *)sender {
    self.selectedLength = sender.titleLabel.text;
    
    // 更新按钮选中状态
    for (UIView *view in sender.superview.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;
            if (button == sender) {
                button.backgroundColor = [UIColor systemBlueColor];
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            } else {
                button.backgroundColor = AIUA_CARD_BACKGROUND_COLOR; // 使用系统卡片背景色，自动适配暗黑模式
                [button setTitleColor:AIUA_LABEL_COLOR forState:UIControlStateNormal]; // 使用系统标签颜色，自动适配暗黑模式
            }
        }
    }
}

- (void)languageButtonTapped:(UIButton *)sender {
    self.selectedLanguage = sender.titleLabel.text;
    
    // 更新按钮选中状态
    for (UIView *view in sender.superview.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;
            if (button == sender) {
                button.backgroundColor = [UIColor systemBlueColor];
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            } else {
                button.backgroundColor = AIUA_CARD_BACKGROUND_COLOR; // 使用系统卡片背景色，自动适配暗黑模式
                [button setTitleColor:AIUA_LABEL_COLOR forState:UIControlStateNormal]; // 使用系统标签颜色，自动适配暗黑模式
            }
        }
    }
}

- (void)startGeneration {
    [self hideStyleSelectionView];
    [self removeResultButtons];
    [self showGenerationView];
    [self performAIGenerationWithType:self.currentEditType];
}

- (void)showStyleSelectionView {
    self.styleSelectionView.hidden = NO;
    self.generationView.hidden = YES;
    [self.styleSelectionView.superview layoutIfNeeded];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view).offset(-220);
        }];
        [self.view layoutIfNeeded];
    }];
}

- (void)hideStyleSelectionView {
    [UIView animateWithDuration:0.3 animations:^{
        [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view).offset(-60);
        }];
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.styleSelectionView.hidden = YES;
    }];
}

- (void)showGenerationView {
    self.generationView.hidden = NO;
    [self.generationView.superview layoutIfNeeded];
    
    // 初始显示生成视图时，停止按钮还未显示，所以只需要考虑生成视图和工具栏
    // 停止按钮的显示和布局会在performAIGenerationWithType中处理
    [UIView animateWithDuration:0.3 animations:^{
        [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view).offset(-260); // 生成视图200 + 工具栏60
        }];
        [self.view layoutIfNeeded];
    }];
}

- (void)hideAllSelectionViews {
    [UIView animateWithDuration:0.3 animations:^{
        self.styleSelectionView.hidden = YES;
        self.generationView.hidden = YES;
        [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view).offset(-60);
        }];
        [self.view layoutIfNeeded];
        for (int i = 0; i < self.toolbarButtonsArray.count; i++) {
            UIButton *button = self.toolbarButtonsArray[i];
            [button setTitleColor:AIUA_LABEL_COLOR forState:UIControlStateNormal]; // 使用系统标签颜色，自动适配暗黑模式
            button.tintColor = AIUA_LABEL_COLOR; // 使用系统标签颜色，自动适配暗黑模式
        }
    }];
}

// 设置收起键盘手势
- (void)setupGestureRecognizer {
    // 添加点击手势隐藏键盘
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tapGesture.cancelsTouchesInView = NO; // 允许点击事件继续传递给子视图（如按钮等）
    [self.view addGestureRecognizer:tapGesture];
    
    // 滑动手势隐藏键盘
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:pan];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - AI生成处理

- (void)performAIGenerationWithType:(AIUAWritingEditType)type {
    if (self.isGenerating) {
        return;
    }
    
    // 估算需要消耗的字数
    // 注意：所有功能都只消耗输出字数（outputWords），不计算输入字数（inputWords）
    // 因为原文已经存在，只有新生成的内容才需要消耗字数
    NSInteger inputWords = [AIUAWordPackManager countWordsInText:self.currentContent];
    NSInteger estimatedOutputWords = 0;
    NSInteger estimatedConsumeWords = 0; // 实际需要消耗的字数（只计算输出，不计算输入）
    
    switch (type) {
        case AIUAWritingEditTypeContinue:
            // 续写：估算生成与原文相似长度的内容，只消耗输出字数（新增的）
            estimatedOutputWords = MAX(inputWords, 500);
            estimatedConsumeWords = estimatedOutputWords;
            break;
        case AIUAWritingEditTypeRewrite:
            // 改写：生成与原文相似长度的内容，只消耗输出字数（重新生成）
            estimatedOutputWords = MAX(inputWords, 300);
            estimatedConsumeWords = estimatedOutputWords;
            break;
        case AIUAWritingEditTypeExpand:
            // 扩写：根据选择的长度估算，只消耗新增的字数（输出 - 输入）
            if ([self.selectedLength isEqualToString:L(@"short")]) {
                estimatedOutputWords = MAX((NSInteger)(inputWords * 1.5), 500);
            } else if ([self.selectedLength isEqualToString:L(@"medium")]) {
                estimatedOutputWords = MAX((NSInteger)(inputWords * 2.0), 1000);
            } else {
                estimatedOutputWords = MAX((NSInteger)(inputWords * 3.0), 2000);
            }
            // 扩写只消耗新增的字数（输出 - 输入）
            estimatedConsumeWords = MAX(estimatedOutputWords - inputWords, 0);
            break;
        case AIUAWritingEditTypeTranslate:
            // 翻译：生成与原文相似长度的内容，只消耗输出字数（重新生成）
            estimatedOutputWords = MAX(inputWords, 500);
            estimatedConsumeWords = estimatedOutputWords;
            break;
    }
    
    NSInteger estimatedTotalWords = estimatedConsumeWords;
    
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
    
    NSString *prompt = [self buildPromptForType:type];
    
    // 隐藏buttonStack，显示停止生成按钮（停止按钮取代buttonStack的位置）
    self.currentButtonStack.hidden = YES;
    self.stopButton.hidden = NO;
    
    // 显示HUD（在停止按钮之后显示，确保停止按钮在HUD上方）
    [AIUAMBProgressManager showHUD:self.view];
    
    // 获取HUD实例并配置，允许停止按钮的交互
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    if (hud) {
        // 设置HUD不阻止用户交互，这样停止按钮可以点击
        hud.userInteractionEnabled = NO;
    }
    
    // 确保停止按钮在HUD上面（通过设置z-order）
    [self.view bringSubviewToFront:self.stopButton];
    
    self.isGenerating = YES;
    self.generationTextView.text = @"";
    self.generatedContent = [NSMutableString string];
    
    // 禁用生成视图中的返回按钮
    if (self.generationBackButton) {
        self.generationBackButton.enabled = NO;
        self.generationBackButton.alpha = 0.5;
    }
    
    // 禁用输入框和工具栏按钮
    [self setUIEnabled:NO];
    
    // 使用流式生成
    WeakType(self);
    [self.deepSeekWriter generateFullStreamWritingWithPrompt:prompt
                                                   wordCount:0
                                              streamHandler:^(NSString *chunk, BOOL finished, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            StrongType(self);
            if (error) {
                [AIUAMBProgressManager hideHUD:strongself.view];
                strongself.isGenerating = NO;
                strongself.stopButton.hidden = YES;
                // 显示buttonStack
                if (strongself.currentButtonStack) {
                    strongself.currentButtonStack.hidden = NO;
                } else if (strongself.generatedContent && strongself.generatedContent.length > 0) {
                    // 如果有生成内容但没有buttonStack，创建它
                    [strongself setupResultButtonsForType:strongself.currentEditType];
                }
                // 恢复生成视图中的返回按钮
                if (strongself.generationBackButton) {
                    strongself.generationBackButton.enabled = YES;
                    strongself.generationBackButton.alpha = 1.0;
                }
                // 恢复输入框和工具栏按钮
                [strongself setUIEnabled:YES];
                
                if (error.code == NSURLErrorCancelled) {
                    return;
                }
                
                [AIUAAlertHelper showAlertWithTitle:L(@"generation_failed")
                                           message:error.localizedDescription
                                     cancelBtnText:nil
                                    confirmBtnText:L(@"confirm")
                                      inController:strongself
                                      cancelAction:nil
                                     confirmAction:nil];
                return;
            }
            
            if (chunk && chunk.length > 0) {
                NSString *text = [AIUAToolsManager removeMarkdownSymbols:chunk];
                [strongself.generatedContent appendString:text];
                strongself.generationTextView.text = strongself.generatedContent;
                // 自动滚动到底部
                [strongself scrollGenerationTextViewToBottom];
            }
            
            if (finished) {
                [AIUAMBProgressManager hideHUD:strongself.view];
                strongself.isGenerating = NO;
                // 隐藏停止生成按钮，显示buttonStack
                strongself.stopButton.hidden = YES;
                if (strongself.currentButtonStack) {
                    strongself.currentButtonStack.hidden = NO;
                }
                [strongself setupResultButtonsForType:type];

                // 恢复生成视图中的返回按钮
                if (strongself.generationBackButton) {
                    strongself.generationBackButton.enabled = YES;
                    strongself.generationBackButton.alpha = 1.0;
                }
                // 恢复输入框和工具栏按钮
                [strongself setUIEnabled:YES];
                
                // 计算实际消耗的字数
                // 注意：所有功能都只消耗输出字数（outputWords），不计算输入字数（inputWords）
                // 因为原文已经存在，只有新生成的内容才需要消耗字数
                NSInteger inputWords = [AIUAWordPackManager countWordsInText:strongself.currentContent ?: @""];
                NSInteger outputWords = [AIUAWordPackManager countWordsInText:strongself.generatedContent];
                NSInteger consumeWords = 0; // 实际需要消耗的字数（只计算输出，不计算输入）
                
                switch (type) {
                    case AIUAWritingEditTypeContinue:
                        // 续写：只消耗输出字数（新增的）
                        consumeWords = outputWords;
                        break;
                    case AIUAWritingEditTypeRewrite:
                        // 改写：只消耗输出字数（重新生成）
                        consumeWords = outputWords;
                        break;
                    case AIUAWritingEditTypeExpand:
                        // 扩写：只消耗新增的字数（输出 - 输入）
                        consumeWords = MAX(outputWords - inputWords, 0);
                        break;
                    case AIUAWritingEditTypeTranslate:
                        // 翻译：只消耗输出字数（重新生成）
                        consumeWords = outputWords;
                        break;
                }
                
                if (consumeWords > 0) {
                    [[AIUAWordPackManager sharedManager] consumeWords:consumeWords completion:^(BOOL success, NSInteger remainingWords) {
                        if (success) {
                            if (type == AIUAWritingEditTypeExpand) {
                                NSLog(@"[DocDetail] 消耗字数成功（扩写）: 输入 %ld 字，输出 %ld 字，新增 %ld 字，消耗 %ld 字，剩余: %ld 字", 
                                      (long)inputWords, (long)outputWords, (long)(outputWords - inputWords), (long)consumeWords, (long)remainingWords);
                            } else {
                                NSLog(@"[DocDetail] 消耗字数成功: 输入 %ld 字，输出 %ld 字，消耗 %ld 字（仅输出），剩余: %ld 字", 
                                      (long)inputWords, (long)outputWords, (long)consumeWords, (long)remainingWords);
                            }
                        } else {
                            NSLog(@"[DocDetail] 消耗字数失败，剩余: %ld 字", (long)remainingWords);
                        }
                    }];
                } else {
                    NSLog(@"[DocDetail] 无需消耗字数（扩写时输出字数小于等于输入字数）");
                }
                
                // 随机触发评分提示（文档编辑完成是一个好时机）
                [AIUAToolsManager tryShowRandomRatingPrompt];
            }
        });
    }];
}

- (void)scrollGenerationTextViewToBottom {
    if (self.generationTextView.text.length > 0) {
        NSRange range = NSMakeRange(self.generationTextView.text.length + 20, self.generationTextView.text.length + 30);
        [self.generationTextView scrollRangeToVisible:range];
    }
}

- (NSString *)buildPromptForType:(AIUAWritingEditType)type {
    NSString *baseContent = self.currentContent;
    NSString *typeInstruction = @"";
    NSString *additionalInstruction = @"";
    
    switch (type) {
        case AIUAWritingEditTypeContinue:
            typeInstruction = L(@"please_continue_based_on_the_following");
            additionalInstruction = [NSString stringWithFormat:L(@"please_write_in_%@"), self.selectedStyle];
            break;
        case AIUAWritingEditTypeRewrite:
            typeInstruction = L(@"please_rewrite_the_following");
            additionalInstruction = [NSString stringWithFormat:L(@"please_rewrite_in_%@"), self.selectedStyle];
            break;
        case AIUAWritingEditTypeExpand:
            typeInstruction = L(@"please_expand_the_following");
            additionalInstruction = [NSString stringWithFormat:L(@"please_expand_with_%@_length_in_%@"), self.selectedLength, self.selectedStyle];
            break;
        case AIUAWritingEditTypeTranslate:
            typeInstruction = [NSString stringWithFormat:L(@"please_translate_the_following_to_%@"), self.selectedLanguage];
            additionalInstruction = L(@"ensure_translation_is_accurate_and_fluent");
            break;
    }
    NSLog(@"typeInstruction:%@, additionalInstruction:%@", typeInstruction, additionalInstruction);
    return [NSString stringWithFormat:@"%@：\n\n%@\n\n%@", typeInstruction, baseContent, additionalInstruction];
}

// 重新生成
- (void)regenerateContent {
    [self performAIGenerationWithType:self.currentEditType];
}

// 插入
- (void)insertGeneratedContent {
    if (self.generatedContent && self.generatedContent.length > 0) {
        NSRange selectedRange = self.contentTextView.selectedRange;
        NSString *newText = [self.currentContent stringByReplacingCharactersInRange:selectedRange withString:self.generatedContent];
        self.contentTextView.text = newText;
        self.currentContent = newText;
        self.hasUserEdited = YES;
        self.ContentTextViewHeight = [self getContentTextViewHeight];
        [UIView performWithoutAnimation:^{
            [self.tableView beginUpdates];
            [self.tableView endUpdates];
        }];
        [self hideAllSelectionViews];
    }
}

// 覆盖原文
- (void)coverOriginalContent {
    if (self.generatedContent && self.generatedContent.length > 0) {
        self.contentTextView.text = self.generatedContent;
        self.currentContent = self.generatedContent;
        self.hasUserEdited = YES;
        self.ContentTextViewHeight = [self getContentTextViewHeight];
        [UIView performWithoutAnimation:^{
            [self.tableView beginUpdates];
            [self.tableView endUpdates];
        }];
        [self hideAllSelectionViews];
    }
}

// 取消当前生成
- (void)cancelCurrentGeneration {
    if (self.isGenerating) {
        [self.deepSeekWriter cancelCurrentRequest];
        [AIUAMBProgressManager hideHUD:self.view];
        self.isGenerating = NO;
        self.stopButton.hidden = YES;
        // 如果有已生成内容，显示buttonStack（先保存再清空）
        NSString *savedContent = [self.generatedContent copy];
        self.generatedContent = nil;
        if (savedContent && savedContent.length > 0) {
            if (self.currentButtonStack) {
                self.currentButtonStack.hidden = NO;
            }
            [self setupResultButtonsForType:self.currentEditType];
        }
        // 恢复生成视图中的返回按钮
        if (self.generationBackButton) {
            self.generationBackButton.enabled = YES;
            self.generationBackButton.alpha = 1.0;
        }
        // 恢复输入框和工具栏按钮
        [self setUIEnabled:YES];
    }
}

// 停止生成按钮点击事件
- (void)stopButtonTapped {
    [self.deepSeekWriter cancelCurrentRequest];
    [AIUAMBProgressManager hideHUD:self.view];
    self.isGenerating = NO;
    self.stopButton.hidden = YES;
    // 如果有已生成内容，显示buttonStack
    if (self.generatedContent && self.generatedContent.length > 0) {
        if (self.currentButtonStack) {
            self.currentButtonStack.hidden = NO;
        }
        [self setupResultButtonsForType:self.currentEditType];
    } else {
        // 如果没有生成内容，隐藏生成视图
        [self hideAllSelectionViews];
    }
    // 恢复生成视图中的返回按钮
    if (self.generationBackButton) {
        self.generationBackButton.enabled = YES;
        self.generationBackButton.alpha = 1.0;
    }
    // 恢复输入框和工具栏按钮
    [self setUIEnabled:YES];
}

// 设置UI启用/禁用状态
- (void)setUIEnabled:(BOOL)enabled {
    // 设置标题和内容输入框可编辑性
    self.titleTextView.editable = enabled;
    self.contentTextView.editable = enabled;
    
    // 禁用titleTextView和contentTextView的用户交互（防止生成时点击弹起键盘）
    self.titleTextView.userInteractionEnabled = enabled;
    self.contentTextView.userInteractionEnabled = enabled;
    
    // 设置工具栏按钮可点击性
    for (UIButton *button in self.toolbarButtonsArray) {
        button.enabled = enabled;
        button.alpha = enabled ? 1.0 : 0.5;
    }
}

// 停止按钮图标
- (UIImage *)stopButtonImage {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(12, 12), NO, [UIScreen mainScreen].scale);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 12, 12)];
    [[UIColor grayColor] setFill];
    [path fill];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - 数据保存

- (void)updateWritingItem {
    if (!self.hasUserEdited) {
        return;
    }
    NSString *title = [self.currentTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *content = [self.currentContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (title.length == 0 && content.length == 0) {
        return;
    }
    NSString *documentID = self.writingItem[@"id"] ?: @"";
    NSMutableDictionary *writingRecord = [NSMutableDictionary dictionary];
    if (self.isNewDocument && documentID.length == 0) {
        // 新建文档
        writingRecord[@"id"] = [[AIUADataManager sharedManager] generateUniqueID];
        writingRecord[@"createTime"] = [[AIUADataManager sharedManager] currentTimeString];
        writingRecord[@"prompt"] = @"";
        writingRecord[@"type"] = @"";
    } else {
        // 编辑现有文档
        writingRecord[@"id"] = documentID ?: [[AIUADataManager sharedManager] generateUniqueID];
        writingRecord[@"createTime"] = self.writingItem[@"createTime"] ?: [[AIUADataManager sharedManager] currentTimeString];
        writingRecord[@"prompt"] = self.writingItem[@"prompt"] ?: @"";
        writingRecord[@"type"] = self.writingItem[@"type"] ?: @"";
    }
    writingRecord[@"title"] = title ?: @"";
    writingRecord[@"content"] = content ?: @"";
    writingRecord[@"wordCount"] = @(content.length);
    self.writingItem = [writingRecord copy];
}

- (void)saveDocumentIfNeeded {
    if (!self.hasUserEdited) {
        return;
    }
    [self updateWritingItem];
    
    // 安全检查：确保 writingItem 不为 nil
    if (!self.writingItem || ![self.writingItem isKindOfClass:[NSDictionary class]]) {
        NSLog(@"❌ saveDocumentIfNeeded: writingItem 为 nil 或不是有效的字典");
        return;
    }
    
    NSString *documentID = self.writingItem[@"id"] ?: @"";
    BOOL success = NO;
    if (documentID.length > 0) {
        success = [[AIUADataManager sharedManager] deleteWritingWithID:documentID];
    }
    [[AIUADataManager sharedManager] saveWritingToPlist:self.writingItem];
}

@end
