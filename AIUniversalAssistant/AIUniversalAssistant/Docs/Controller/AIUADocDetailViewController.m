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
        _selectedStyle = @"通用";
        _selectedLength = @"适中";
        _selectedLanguage = @"英文";
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
        _selectedStyle = @"通用";
        _selectedLength = @"适中";
        _selectedLanguage = @"英文";
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
        self.navigationItem.title = @"新建文档";
    } else {
        self.navigationItem.title = @"文档详情";
    }
}

- (void)setupUI {
    [super setupUI];
    [self setupTableView];
    [self setupHeaderView];
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
    self.titleTextView.font = [UIFont boldSystemFontOfSize:20];
    self.titleTextView.textColor = [UIColor blackColor];
    self.titleTextView.backgroundColor = [UIColor clearColor];
    self.titleTextView.scrollEnabled = YES;
    self.titleTextView.delegate = self;
    self.titleTextView.text = self.currentTitle;
    self.titleTextView.placeholder = @"请输入标题";
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
    separator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    [self.headerView addSubview:separator];
    
    [separator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleTextView.mas_bottom).offset(8);
        make.left.right.equalTo(self.headerView);
        make.height.equalTo(@1);
        make.bottom.equalTo(self.headerView).offset(-8);
    }];
    
    self.tableView.tableHeaderView = self.headerView;
}

- (void)setupToolbarView {
    self.toolbarView = [[UIView alloc] init];
    self.toolbarView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
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
    NSArray *buttonTitles = @[@"续写", @"改写", @"扩写", @"翻译"];
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
        [button setTitleColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:12];
        
        // 设置图标
        UIImage *icon = [UIImage systemImageNamed:buttonIcons[i]];
        [button setImage:icon forState:UIControlStateNormal];
        button.tintColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
        
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
    self.styleSelectionView.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.98 alpha:1.0];
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
    titleLabel.font = [UIFont systemFontOfSize:14];
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
    NSArray *styles = @[@"通用", @"新闻", @"学术", @"公务", @"小说", @"作文"];
    UIStackView *styleStackView = [[UIStackView alloc] init];
    styleStackView.axis = UILayoutConstraintAxisHorizontal;
    styleStackView.distribution = UIStackViewDistributionFillEqually;
    styleStackView.alignment = UIStackViewAlignmentCenter;
    styleStackView.spacing = 8;
    [styleContainer addSubview:styleStackView];
    
    [styleStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(styleContainer).insets(UIEdgeInsetsMake(0, 16, 0, 16));
    }];
    
    for (NSString *style in styles) {
        UIButton *styleButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [styleButton setTitle:style forState:UIControlStateNormal];
        [styleButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        styleButton.titleLabel.font = [UIFont systemFontOfSize:14];
        styleButton.backgroundColor = [UIColor whiteColor];
        styleButton.layer.cornerRadius = 6;
        styleButton.layer.borderWidth = 1;
        styleButton.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
        [styleButton addTarget:self action:@selector(styleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [styleStackView addArrangedSubview:styleButton];
        
        // 默认选中第一个
        if ([style isEqualToString:@"通用"]) {
            [self styleButtonTapped:styleButton];
        }
    }
    
    // 开始按钮
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [startButton setTitle:@"开始生成" forState:UIControlStateNormal];
    [startButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    startButton.backgroundColor = [UIColor systemBlueColor];
    startButton.layer.cornerRadius = 6;
    startButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
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
    self.generationView.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.98 alpha:1.0];
    self.generationView.hidden = YES;
    [self.view addSubview:self.generationView];
    
    [self.generationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.toolbarView.mas_top);
        make.height.equalTo(@200);
    }];
    
    // 生成内容标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"生成内容";
    titleLabel.font = [UIFont systemFontOfSize:14];
    titleLabel.textColor = [UIColor darkGrayColor];
    [self.generationView addSubview:titleLabel];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.generationView).offset(8);
        make.left.equalTo(self.generationView).offset(16);
    }];
    
    // 生成内容文本框
    self.generationTextView = [[UITextView alloc] init];
    self.generationTextView.font = [UIFont systemFontOfSize:14];
    self.generationTextView.textColor = [UIColor darkGrayColor];
    self.generationTextView.backgroundColor = [UIColor whiteColor];
    self.generationTextView.layer.cornerRadius = 6;
    self.generationTextView.layer.borderWidth = 1;
    self.generationTextView.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
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
        titleLabel.text = @"扩写长度";
        // 移除原有风格按钮
        for (UIView *subview in styleContainer.subviews) {
            [subview removeFromSuperview];
        }
        // 添加扩写长度选择
        NSArray *lengths = @[@"适中", @"较长"];
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
            lengthButton.titleLabel.font = [UIFont systemFontOfSize:14];
            lengthButton.backgroundColor = [UIColor whiteColor];
            lengthButton.layer.cornerRadius = 6;
            lengthButton.layer.borderWidth = 1;
            lengthButton.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
            [lengthButton addTarget:self action:@selector(lengthButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [lengthStackView addArrangedSubview:lengthButton];
            
            // 默认选中第一个
            if ([length isEqualToString:@"适中"]) {
                [self lengthButtonTapped:lengthButton];
            }
        }
        
    } else if (type == AIUAWritingEditTypeTranslate) {
        // 翻译模式：显示目标语言选择
        UILabel *titleLabel = titleContainer.subviews[1];
        titleLabel.text = @"目标语言";
        // 移除原有风格按钮
        for (UIView *subview in styleContainer.subviews) {
            [subview removeFromSuperview];
        }
        // 添加语言选择
        NSArray *languages = @[@"英文", @"中文", @"日文"];
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
            languageButton.titleLabel.font = [UIFont systemFontOfSize:14];
            languageButton.backgroundColor = [UIColor whiteColor];
            languageButton.layer.cornerRadius = 6;
            languageButton.layer.borderWidth = 1;
            languageButton.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
            [languageButton addTarget:self action:@selector(languageButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [languageStackView addArrangedSubview:languageButton];
            
            // 默认选中第一个
            if ([language isEqualToString:@"英文"]) {
                [self languageButtonTapped:languageButton];
            }
        }
        
    } else {
        // 其他模式：显示风格选择
        UILabel *titleLabel = titleContainer.subviews[1];
        NSString *title = @"选择风格";
        if (type == AIUAWritingEditTypeContinue) {
            title = @"续写风格";
        } else if (type == AIUAWritingEditTypeRewrite) {
            title = @"改写风格";
        }
        titleLabel.text = title;
        for (UIView *subview in styleContainer.subviews) {
            [subview removeFromSuperview];
        }
        // 如果已经移除，重新创建风格选择
        NSArray *styles = @[@"通用", @"新闻", @"学术", @"公务", @"小说", @"作文"];
        UIStackView *styleStackView = [[UIStackView alloc] init];
        styleStackView.axis = UILayoutConstraintAxisHorizontal;
        styleStackView.distribution = UIStackViewDistributionFillEqually;
        styleStackView.alignment = UIStackViewAlignmentCenter;
        styleStackView.spacing = 8;
        [styleContainer addSubview:styleStackView];
        [styleStackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(styleContainer).insets(UIEdgeInsetsMake(0, 16, 0, 16));
        }];
        for (NSString *style in styles) {
            UIButton *styleButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [styleButton setTitle:style forState:UIControlStateNormal];
            [styleButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            styleButton.titleLabel.font = [UIFont systemFontOfSize:14];
            styleButton.backgroundColor = [UIColor whiteColor];
            styleButton.layer.cornerRadius = 6;
            styleButton.layer.borderWidth = 1;
            styleButton.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
            [styleButton addTarget:self action:@selector(styleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [styleStackView addArrangedSubview:styleButton];
            // 默认选中第一个
            if ([style isEqualToString:@"通用"]) {
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
    [regenerateButton setTitle:@"重新生成" forState:UIControlStateNormal];
    [regenerateButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    regenerateButton.backgroundColor = [UIColor whiteColor];
    regenerateButton.layer.cornerRadius = 6;
    regenerateButton.layer.borderWidth = 1;
    regenerateButton.layer.borderColor = [UIColor systemBlueColor].CGColor;
    [regenerateButton addTarget:self action:@selector(regenerateContent) forControlEvents:UIControlEventTouchUpInside];
    [buttonStack addArrangedSubview:regenerateButton];
    
    // 插入按钮（所有类型都有）
    UIButton *insertButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [insertButton setTitle:@"插入" forState:UIControlStateNormal];
    [insertButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    insertButton.backgroundColor = [UIColor systemBlueColor];
    insertButton.layer.cornerRadius = 6;
    [insertButton addTarget:self action:@selector(insertGeneratedContent) forControlEvents:UIControlEventTouchUpInside];
    [buttonStack addArrangedSubview:insertButton];
    
    // 改写和扩写有覆盖原文按钮
    if (type == AIUAWritingEditTypeRewrite || type == AIUAWritingEditTypeExpand) {
        UIButton *coverButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [coverButton setTitle:@"覆盖原文" forState:UIControlStateNormal];
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
        
        // 内容输入框
        self.contentTextView = [[UITextView alloc] init];
        self.contentTextView.font = [UIFont systemFontOfSize:16];
        self.contentTextView.textColor = [UIColor darkGrayColor];
        self.contentTextView.backgroundColor = [UIColor clearColor];
        self.contentTextView.delegate = self;
        self.contentTextView.text = self.currentContent;
        self.contentTextView.placeholder = @"请输入正文";
        self.contentTextView.placeholderColor = [UIColor lightGrayColor];
        [cell.contentView addSubview:self.contentTextView];
        
        [self.contentTextView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(cell.contentView).insets(UIEdgeInsetsMake(8, 16, 8, 16));
        }];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return AIUAScreenHeight - AIUA_NAV_BAR_TOTAL_HEIGHT - 120 - 60 - self.keyboardHeight;
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

- (void)toolbarButtonTapped:(UIButton *)sender {
    if (!self.hasUserEdited && self.isNewDocument) {
        [AIUAAlertHelper showAlertWithTitle:@"提示"
                                   message:@"请先输入内容"
                             cancelBtnText:nil
                            confirmBtnText:@"确定"
                              inController:self
                              cancelAction:nil
                             confirmAction:nil];
        return;
    }
    
    if (self.currentContent.length == 0) {
        [AIUAAlertHelper showAlertWithTitle:@"提示"
                                   message:@"请先输入正文内容"
                             cancelBtnText:nil
                            confirmBtnText:@"确定"
                              inController:self
                              cancelAction:nil
                             confirmAction:nil];
        return;
    }
    
    // 检查DeepSeek配置
    if (!self.deepSeekWriter) {
        [AIUAAlertHelper showAlertWithTitle:@"配置错误"
                                   message:@"请先配置DeepSeek API Key"
                             cancelBtnText:nil
                            confirmBtnText:@"确定"
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
            [button setTitleColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0] forState:UIControlStateNormal];
            button.tintColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
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
            [button setTitleColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0] forState:UIControlStateNormal];
            button.tintColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
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
                
                [AIUAAlertHelper showAlertWithTitle:@"生成失败"
                                           message:error.localizedDescription
                                     cancelBtnText:nil
                                    confirmBtnText:@"确定"
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
            typeInstruction = @"请根据以下内容进行续写，保持原文风格和逻辑连贯性";
            additionalInstruction = [NSString stringWithFormat:@"请使用%@风格进行写作。", self.selectedStyle];
            break;
        case AIUAWritingEditTypeRewrite:
            typeInstruction = @"请对以下内容进行改写，保持原意但优化表达方式";
            additionalInstruction = [NSString stringWithFormat:@"请使用%@风格进行改写。", self.selectedStyle];
            break;
        case AIUAWritingEditTypeExpand:
            typeInstruction = @"请对以下内容进行扩写，增加细节和丰富内容";
            additionalInstruction = [NSString stringWithFormat:@"请进行%@长度的扩写，使用%@风格。", self.selectedLength, self.selectedStyle];
            break;
        case AIUAWritingEditTypeTranslate:
            typeInstruction = [NSString stringWithFormat:@"请将以下内容翻译成%@", self.selectedLanguage];
            additionalInstruction = @"确保翻译准确流畅，保持原文意思不变。";
            break;
    }
    
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
        
        [self hideAllSelectionViews];
    }
}

- (void)coverOriginalContent {
    if (self.generatedContent && self.generatedContent.length > 0) {
        self.contentTextView.text = self.generatedContent;
        self.currentContent = self.generatedContent;
        self.hasUserEdited = YES;
        
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
