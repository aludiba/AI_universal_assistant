#import "AIUADocDetailViewController.h"
#import "AIUADataManager.h"
#import "AIUAAlertHelper.h"
#import "AIUAMBProgressManager.h"
#import "UITextView+AIUAPlaceholder.h"
#import <Masonry/Masonry.h>

@interface AIUADocDetailViewController () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextView *titleTextView;
@property (nonatomic, strong) UITextView *contentTextView;
@property (nonatomic, assign) CGFloat ContentTextViewHeight;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *toolbarView;

@property (nonatomic, strong) NSDictionary *writingItem; // 编辑模式下的原始数据
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

// 键盘相关
@property (nonatomic, assign) CGFloat keyboardHeight;

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
    [self saveDocumentIfNeeded];
    [self cancelCurrentGeneration];
    [self unregisterKeyboardNotifications];
}

- (void)setupNavigationBar {
    if (self.isNewDocument) {
        self.navigationItem.title = L(@"new_document");
    } else {
        self.navigationItem.title = L(@"document_details");
    }
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
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-60);
    }];
}

- (void)setupHeaderView {
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 120)];
    self.headerView.backgroundColor = [UIColor whiteColor];
    
    // 标题输入框
    self.titleTextView = [[UITextView alloc] init];
    self.titleTextView.font = AIUAUIFontBold(20);
    self.titleTextView.textColor = [UIColor blackColor];
    self.titleTextView.backgroundColor = [UIColor clearColor];
    self.titleTextView.scrollEnabled = YES;
    self.titleTextView.delegate = self;
    self.titleTextView.text = self.currentTitle;
    self.titleTextView.placeholder = L(@"enter_title");
    self.titleTextView.placeholderColor = [UIColor lightGrayColor];
    [self.headerView addSubview:self.titleTextView];
    
    [self.titleTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerView).offset(16);
        make.left.equalTo(self.headerView).offset(16);
        make.right.equalTo(self.headerView).offset(-16);
        make.height.greaterThanOrEqualTo(@40);
    }];
    
    // 分隔线
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = AIUA_DIVIDER_COLOR;
    [self.headerView addSubview:separator];
    
    [separator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleTextView.mas_bottom).offset(8);
        make.left.right.equalTo(self.headerView);
        make.height.equalTo(@1);
        make.bottom.equalTo(self.headerView).offset(-8);
    }];
    
    self.tableView.tableHeaderView = self.headerView;
}

- (void)setupContentTextView  {
    self.contentTextView = [[UITextView alloc] init];
    self.contentTextView.font = AIUAUIFontSystem(16);
    self.contentTextView.textColor = [UIColor darkGrayColor];
    self.contentTextView.backgroundColor = [UIColor clearColor];
    self.contentTextView.delegate = self;
    self.contentTextView.text = self.currentContent;
    self.contentTextView.placeholder = L(@"enter_main_text");
    self.contentTextView.placeholderColor = [UIColor lightGrayColor];
    self.contentTextView.scrollEnabled = NO;
    self.ContentTextViewHeight = [self getContentTextViewHeight];
}

- (void)setupToolbarView {
    self.toolbarView = [[UIView alloc] init];
    self.toolbarView.backgroundColor = AIUAUIColorSimplifyRGB(0.95, 0.95, 0.95);
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
        [button setTitleColor:AIUAUIColorSimplifyRGB(0.2, 0.2, 0.2) forState:UIControlStateNormal];
        button.titleLabel.font = AIUAUIFontSystem(12);
        
        // 设置图标
        UIImage *icon = [UIImage systemImageNamed:buttonIcons[i]];
        [button setImage:icon forState:UIControlStateNormal];
        button.tintColor = AIUAUIColorSimplifyRGB(0.2, 0.2, 0.2);
        
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
    self.styleSelectionView.backgroundColor = AIUAUIColorSimplifyRGB(0.98, 0.98, 0.98);
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
    [backButton addTarget:self action:@selector(hideStyleSelectionView) forControlEvents:UIControlEventTouchUpInside];
    [titleContainer addSubview:backButton];
    
    [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleContainer).offset(16);
        make.centerY.equalTo(titleContainer);
        make.width.height.equalTo(@24);
    }];
    
    // 添加标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = AIUAUIFontSystem(14);
    titleLabel.textColor = [UIColor darkGrayColor];
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
        [styleButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        styleButton.titleLabel.font = AIUAUIFontSystem(14);
        styleButton.backgroundColor = [UIColor whiteColor];
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
    self.generationView.backgroundColor = AIUAUIColorSimplifyRGB(0.98, 0.98, 0.98);
    self.generationView.hidden = YES;
    [self.view addSubview:self.generationView];
    
    [self.generationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.toolbarView.mas_top);
        make.height.equalTo(@200);
    }];
    
    // 生成内容标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = L(@"generated_content");
    titleLabel.font = AIUAUIFontSystem(14);
    titleLabel.textColor = [UIColor darkGrayColor];
    [self.generationView addSubview:titleLabel];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.generationView).offset(8);
        make.left.equalTo(self.generationView).offset(16);
    }];
    
    // 生成内容文本框
    self.generationTextView = [[UITextView alloc] init];
    self.generationTextView.font = AIUAUIFontSystem(14);
    self.generationTextView.textColor = [UIColor darkGrayColor];
    self.generationTextView.backgroundColor = [UIColor whiteColor];
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
            [lengthButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            lengthButton.titleLabel.font = AIUAUIFontSystem(14);
            lengthButton.backgroundColor = [UIColor whiteColor];
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
            [languageButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            languageButton.titleLabel.font = AIUAUIFontSystem(14);
            languageButton.backgroundColor = [UIColor whiteColor];
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
            [styleButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            styleButton.titleLabel.font = AIUAUIFontSystem(14);
            styleButton.backgroundColor = [UIColor whiteColor];
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
    
    // 重新生成按钮（所有类型都有）
    UIButton *regenerateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [regenerateButton setTitle:L(@"regenerate") forState:UIControlStateNormal];
    [regenerateButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    regenerateButton.backgroundColor = [UIColor whiteColor];
    regenerateButton.layer.cornerRadius = 6;
    regenerateButton.layer.borderWidth = 1;
    regenerateButton.layer.borderColor = [UIColor systemBlueColor].CGColor;
    [regenerateButton addTarget:self action:@selector(regenerateContent) forControlEvents:UIControlEventTouchUpInside];
    [buttonStack addArrangedSubview:regenerateButton];
    
    // 插入按钮（所有类型都有）
    UIButton *insertButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [insertButton setTitle:L(@"insert") forState:UIControlStateNormal];
    [insertButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    insertButton.backgroundColor = [UIColor systemBlueColor];
    insertButton.layer.cornerRadius = 6;
    [insertButton addTarget:self action:@selector(insertGeneratedContent) forControlEvents:UIControlEventTouchUpInside];
    [buttonStack addArrangedSubview:insertButton];
    
    // 改写和扩写有覆盖原文按钮
    if (type == AIUAWritingEditTypeRewrite || type == AIUAWritingEditTypeExpand) {
        UIButton *coverButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [coverButton setTitle:L(@"overwrite_original") forState:UIControlStateNormal];
        [coverButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
        coverButton.backgroundColor = [UIColor whiteColor];
        coverButton.layer.cornerRadius = 6;
        coverButton.layer.borderWidth = 1;
        coverButton.layer.borderColor = [UIColor systemBlueColor].CGColor;
        [coverButton addTarget:self action:@selector(coverOriginalContent) forControlEvents:UIControlEventTouchUpInside];
        [buttonStack addArrangedSubview:coverButton];
        
        // 调整布局为三个按钮
        buttonStack.distribution = UIStackViewDistributionFillEqually;
    }
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
    return self.ContentTextViewHeight - 16;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    self.hasUserEdited = YES;
    
    if (textView == self.titleTextView) {
        self.currentTitle = textView.text;
    } else if (textView == self.contentTextView) {
        self.currentContent = textView.text;
    }
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
    self.keyboardHeight = keyboardFrame.size.height;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view).offset(-60 - self.keyboardHeight);
        }];
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.keyboardHeight = 0;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view).offset(-60);
        }];
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - Actions

- (CGFloat)getContentTextViewHeight {
    CGSize sizeThatFits = [self.contentTextView sizeThatFits:CGSizeMake(AIUAScreenWidth - 32, CGFLOAT_MAX)];
    return sizeThatFits.height;
}

- (void)toolbarButtonTapped:(UIButton *)sender {
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
            [button setTitleColor:AIUAUIColorSimplifyRGB(0.2, 0.2, 0.2) forState:UIControlStateNormal];
            button.tintColor = AIUAUIColorSimplifyRGB(0.2, 0.2, 0.2);
        }
    }
    
    self.currentEditType = (AIUAWritingEditType)sender.tag;
    
    // 根据类型更新界面
    [self updateStyleSelectionForType:self.currentEditType];
    
    // 显示风格选择视图
    [self showStyleSelectionView];
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
                button.backgroundColor = [UIColor whiteColor];
                [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
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
                button.backgroundColor = [UIColor whiteColor];
                [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
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
                button.backgroundColor = [UIColor whiteColor];
                [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
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
        for (int i = 0; i < self.toolbarButtonsArray.count; i++) {
            UIButton *button = self.toolbarButtonsArray[i];
            [button setTitleColor:AIUAUIColorSimplifyRGB(0.2, 0.2, 0.2) forState:UIControlStateNormal];
            button.tintColor = AIUAUIColorSimplifyRGB(0.2, 0.2, 0.2);
        }
        self.styleSelectionView.hidden = YES;
    }];
}

- (void)showGenerationView {
    self.generationView.hidden = NO;
    [self.generationView.superview layoutIfNeeded];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view).offset(-260);
        }];
        [self.view layoutIfNeeded];
    }];
}

- (void)hideAllSelectionViews {
    self.styleSelectionView.hidden = YES;
    self.generationView.hidden = YES;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view).offset(-60);
        }];
        [self.view layoutIfNeeded];
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
    
    NSString *prompt = [self buildPromptForType:type];
    
    [AIUAMBProgressManager showHUD:self.view];
    self.isGenerating = YES;
    self.generationTextView.text = @"";
    self.generatedContent = [NSMutableString string];
    
    // 使用流式生成
    [self.deepSeekWriter generateFullStreamWritingWithPrompt:prompt
                                                   wordCount:0
                                              streamHandler:^(NSString *chunk, BOOL finished, NSError * _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [AIUAMBProgressManager hideHUD:self.view];
                self.isGenerating = NO;
                
                if (error.code == NSURLErrorCancelled) {
                    return;
                }
                
                [AIUAAlertHelper showAlertWithTitle:L(@"generation_failed")
                                           message:error.localizedDescription
                                     cancelBtnText:nil
                                    confirmBtnText:L(@"confirm")
                                      inController:self
                                      cancelAction:nil
                                     confirmAction:nil];
                return;
            }
            
            if (chunk && chunk.length > 0) {
                [self.generatedContent appendString:chunk];
                self.generationTextView.text = self.generatedContent;
                
                // 自动滚动到底部
                [self scrollGenerationTextViewToBottom];
            }
            
            if (finished) {
                [AIUAMBProgressManager hideHUD:self.view];
                self.isGenerating = NO;
                // 显示结果操作按钮
                [self setupResultButtonsForType:type];
            }
        });
    }];
}

- (void)scrollGenerationTextViewToBottom {
    if (self.generationTextView.text.length > 0) {
        NSRange range = NSMakeRange(self.generationTextView.text.length - 1, 1);
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

- (void)regenerateContent {
    [self performAIGenerationWithType:self.currentEditType];
}

- (void)insertGeneratedContent {
    if (self.generatedContent && self.generatedContent.length > 0) {
        NSRange selectedRange = self.contentTextView.selectedRange;
        NSString *newText = [self.currentContent stringByReplacingCharactersInRange:selectedRange withString:self.generatedContent];
        self.contentTextView.text = newText;
        self.currentContent = newText;
        self.hasUserEdited = YES;
        self.ContentTextViewHeight = [self getContentTextViewHeight];
        [self.tableView reloadData];
        [self hideAllSelectionViews];
    }
}

- (void)coverOriginalContent {
    if (self.generatedContent && self.generatedContent.length > 0) {
        self.contentTextView.text = self.generatedContent;
        self.currentContent = self.generatedContent;
        self.hasUserEdited = YES;
        self.ContentTextViewHeight = [self getContentTextViewHeight];
        [self.tableView reloadData];
        [self hideAllSelectionViews];
    }
}

- (void)cancelCurrentGeneration {
    if (self.isGenerating) {
        [self.deepSeekWriter cancelCurrentRequest];
        self.isGenerating = NO;
        self.generatedContent = nil;
        [AIUAMBProgressManager hideHUD:self.view];
    }
}

#pragma mark - 数据保存

- (void)saveDocumentIfNeeded {
    if (!self.hasUserEdited) {
        return;
    }
    
    NSString *title = [self.currentTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *content = [self.currentContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (title.length == 0 && content.length == 0) {
        return;
    }
    
    NSMutableDictionary *writingRecord = [NSMutableDictionary dictionary];
    
    if (self.isNewDocument) {
        // 新建文档
        writingRecord[@"id"] = [[AIUADataManager sharedManager] generateUniqueID];
        writingRecord[@"createTime"] = [[AIUADataManager sharedManager] currentTimeString];
        writingRecord[@"prompt"] = @"";
        writingRecord[@"type"] = @"";
    } else {
        NSString *documentID = self.writingItem[@"id"];
        BOOL success = NO;
        if (documentID && documentID.length > 0) {
            success = [[AIUADataManager sharedManager] deleteWritingWithID:documentID];
        }
        // 编辑现有文档
        writingRecord[@"id"] = documentID ?: [[AIUADataManager sharedManager] generateUniqueID];
        writingRecord[@"createTime"] = self.writingItem[@"createTime"] ?: [[AIUADataManager sharedManager] currentTimeString];
        writingRecord[@"prompt"] = self.writingItem[@"prompt"] ?: @"";
        writingRecord[@"type"] = self.writingItem[@"type"] ?: @"";
    }
    
    writingRecord[@"title"] = title ?: @"";
    writingRecord[@"content"] = content ?: @"";
    writingRecord[@"wordCount"] = @(content.length);
    
    [[AIUADataManager sharedManager] saveWritingToPlist:writingRecord];
}

@end
