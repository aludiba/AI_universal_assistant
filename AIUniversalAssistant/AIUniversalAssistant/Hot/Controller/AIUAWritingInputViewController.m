#import "AIUAWritingInputViewController.h"
#import "AIUAWritingDetailViewController.h"
#import "AIUAAlertHelper.h"
#import "AIUADataManager.h"
#import "AIUAMBProgressManager.h"

@interface AIUAWritingInputViewController ()<UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

// 标题区域
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;

// 输入区域
@property (nonatomic, strong) UIView *inputContainer;

@property (nonatomic, strong) UILabel *themeTitleLabel;
@property (nonatomic, strong) UIView *themeContainer;
@property (nonatomic, strong) UITextField *themeTextField;
@property (nonatomic, strong) UIButton *themeClearButton;

@property (nonatomic, strong) UILabel *requirementTitleLabel;
@property (nonatomic, strong) UIView *requirementContainer;
@property (nonatomic, strong) UITextView *requirementTextView;
@property (nonatomic, strong) UILabel *requirementPlaceholder;
@property (nonatomic, strong) UIButton *requirementClearButton;

@property (nonatomic, strong) UILabel *wordCountTitleLabel;
@property (nonatomic, strong) UIView *wordCountContainer;
@property (nonatomic, strong) NSArray *wordCountOptions;
@property (nonatomic, strong) NSMutableArray *wordCountButtons;
@property (nonatomic, assign) NSInteger selectedWordCount;

// 底部按钮
@property (nonatomic, strong) UIView *bottomContainer;
@property (nonatomic, strong) UIButton *generateButton;
@property (nonatomic, strong) UIButton *favoriteButton;

@end

@implementation AIUAWritingInputViewController

- (instancetype)initWithTemplateItem:(NSDictionary *)templateItem
                            categoryId:(NSString *)categoryId apiKey:(NSString *)apiKey{
    self = [super init];
    if (self) {
        _templateItem = templateItem;
        _categoryId = categoryId;
        _apiKey = [apiKey copy];
        _type = templateItem[@"type"];
        _wordCountOptions = @[@0, @100, @300, @600, @1000];
        _wordCountButtons = [NSMutableArray array];
        _selectedWordCount = 0; // 默认不限
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupUI {
    [super setupUI];
    
    // 设置自定义标题视图
    [self setupCustomTitleView];
    
    // 滚动视图
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.scrollView];
    
    // 内容视图
    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];
    
    // 输入容器
    self.inputContainer = [[UIView alloc] init];
    self.inputContainer.backgroundColor = [UIColor whiteColor];
    self.inputContainer.layer.cornerRadius = 12;
    self.inputContainer.layer.masksToBounds = YES;
    [self.contentView addSubview:self.inputContainer];
    
    // 主题标题
    self.themeTitleLabel = [[UILabel alloc] init];
    self.themeTitleLabel.font = AIUAUIFontSystem(16);
    self.themeTitleLabel.textColor = AIUAUIColorRGB(34, 34, 34);
    self.themeTitleLabel.text = L(@"theme");
    [self.inputContainer addSubview:self.themeTitleLabel];
    
    // 主题容器
    self.themeContainer = [[UIView alloc] init];
    self.themeContainer.backgroundColor = AIUAUIColorRGB(249, 250, 251);
    self.themeContainer.layer.cornerRadius = 8;
    self.themeContainer.layer.masksToBounds = YES;
    self.themeContainer.layer.borderWidth = 1;
    self.themeContainer.layer.borderColor = AIUAUIColorRGB(229, 231, 235).CGColor;
    [self.inputContainer addSubview:self.themeContainer];
    
    // 主题输入框
    self.themeTextField = [[UITextField alloc] init];
    self.themeTextField.delegate = self;
    self.themeTextField.font = AIUAUIFontSystem(16);
    self.themeTextField.textColor = AIUAUIColorRGB(34, 34, 34);
    self.themeTextField.backgroundColor = [UIColor clearColor];
    self.themeTextField.placeholder = L(@"enter_creation_theme");
    [self.themeContainer addSubview:self.themeTextField];
    
    // 主题清空按钮
    self.themeClearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.themeClearButton setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    self.themeClearButton.tintColor = AIUAUIColorRGB(156, 163, 175);
    self.themeClearButton.alpha = 0;
    [self.themeClearButton addTarget:self action:@selector(clearTheme) forControlEvents:UIControlEventTouchUpInside];
    [self.themeContainer addSubview:self.themeClearButton];
    
    // 要求标题
    self.requirementTitleLabel = [[UILabel alloc] init];
    self.requirementTitleLabel.font = AIUAUIFontSystem(16);
    self.requirementTitleLabel.textColor = AIUAUIColorRGB(34, 34, 34);
    self.requirementTitleLabel.text = L(@"require");
    [self.inputContainer addSubview:self.requirementTitleLabel];
    
    // 要求容器
    self.requirementContainer = [[UIView alloc] init];
    self.requirementContainer.backgroundColor = AIUAUIColorRGB(249, 250, 251);
    self.requirementContainer.layer.cornerRadius = 8;
    self.requirementContainer.layer.masksToBounds = YES;
    self.requirementContainer.layer.borderWidth = 1;
    self.requirementContainer.layer.borderColor = AIUAUIColorRGB(229, 231, 235).CGColor;
    [self.inputContainer addSubview:self.requirementContainer];
    
    // 要求输入框
    self.requirementTextView = [[UITextView alloc] init];
    self.requirementTextView.font = AIUAUIFontSystem(16);
    self.requirementTextView.textColor = AIUAUIColorRGB(34, 34, 34);
    self.requirementTextView.backgroundColor = [UIColor clearColor];
    self.requirementTextView.delegate = self;
    [self.requirementContainer addSubview:self.requirementTextView];
    
    // 要求占位符
    self.requirementPlaceholder = [[UILabel alloc] init];
    self.requirementPlaceholder.font = AIUAUIFontSystem(16);
    self.requirementPlaceholder.textColor = AIUAUIColorRGB(156, 163, 175);
    self.requirementPlaceholder.text = L(@"enter_specific_requirements");
    self.requirementPlaceholder.userInteractionEnabled = NO;
    [self.requirementContainer addSubview:self.requirementPlaceholder];
    
    // 要求清空按钮
    self.requirementClearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.requirementClearButton setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    self.requirementClearButton.tintColor = AIUAUIColorRGB(156, 163, 175);
    self.requirementClearButton.alpha = 0;
    [self.requirementClearButton addTarget:self action:@selector(clearRequirement) forControlEvents:UIControlEventTouchUpInside];
    [self.requirementContainer addSubview:self.requirementClearButton];
    
    // 字数标题
    self.wordCountTitleLabel = [[UILabel alloc] init];
    self.wordCountTitleLabel.font = AIUAUIFontSystem(16);
    self.wordCountTitleLabel.textColor = AIUAUIColorRGB(34, 34, 34);
    self.wordCountTitleLabel.text = L(@"maximum_word_count");
    [self.inputContainer addSubview:self.wordCountTitleLabel];
    
    // 字数选择容器
    self.wordCountContainer = [[UIView alloc] init];
    [self.inputContainer addSubview:self.wordCountContainer];
    
    // 创建字数选择按钮
    [self createWordCountButtons];
    
    // 底部容器
    self.bottomContainer = [[UIView alloc] init];
    [self.view addSubview:self.bottomContainer];
    
    // 收藏按钮
    self.favoriteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.favoriteButton setImage:[UIImage systemImageNamed:@"star"] forState:UIControlStateNormal];
    [self.favoriteButton setImage:[UIImage systemImageNamed:@"star.fill"] forState:UIControlStateSelected];
    NSString *itemId = [[AIUADataManager sharedManager] getItemId:self.templateItem];
    BOOL isFavorite = [[AIUADataManager sharedManager] isFavorite:itemId];
    [self.favoriteButton setSelected:isFavorite];
    self.favoriteButton.tintColor = isFavorite ? AIUAUIColorSimplifyRGB(1.0, 0.2, 0.2) : AIUAUIColorSimplifyRGB(0.6, 0.6, 0.6);
    self.favoriteButton.backgroundColor = [UIColor whiteColor];
    self.favoriteButton.layer.cornerRadius = 12;
    self.favoriteButton.layer.masksToBounds = YES;
    self.favoriteButton.layer.borderWidth = 1;
    self.favoriteButton.layer.borderColor = AIUAUIColorRGB(229, 231, 235).CGColor;
    [self.favoriteButton addTarget:self action:@selector(favoriteButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomContainer addSubview:self.favoriteButton];
    
    // 生成按钮
    self.generateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.generateButton setTitle:L(@"generate") forState:UIControlStateNormal];
    [self.generateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.generateButton.titleLabel.font = AIUAUIFontSystem(18);
    self.generateButton.backgroundColor = AIUAUIColorRGB(59, 130, 246);
    self.generateButton.layer.cornerRadius = 12;
    self.generateButton.layer.masksToBounds = YES;
    [self.generateButton addTarget:self action:@selector(generateWriting) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomContainer addSubview:self.generateButton];
    
    [self setupConstraints];
    [self setupDefaultValues];
    [self setupNotifications];
    [self setupGestureRecognizer];
}

- (void)setupCustomTitleView {
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    
    self.mainTitleLabel = [[UILabel alloc] init];
    self.mainTitleLabel.font = AIUAUIFontBold(18);
    self.mainTitleLabel.textColor = AIUAUIColorRGB(34, 34, 34);
    self.mainTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.mainTitleLabel.text = self.templateItem[@"title"];
    [titleView addSubview:self.mainTitleLabel];
    
    self.subTitleLabel = [[UILabel alloc] init];
    self.subTitleLabel.font = AIUAUIFontSystem(14);
    self.subTitleLabel.textColor = AIUAUIColorRGB(107, 114, 128);
    self.subTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.subTitleLabel.text = self.templateItem[@"subtitle"];
    [titleView addSubview:self.subTitleLabel];
    
    self.mainTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.mainTitleLabel.topAnchor constraintEqualToAnchor:titleView.topAnchor constant:4],
        [self.mainTitleLabel.leadingAnchor constraintEqualToAnchor:titleView.leadingAnchor],
        [self.mainTitleLabel.trailingAnchor constraintEqualToAnchor:titleView.trailingAnchor],
        
        [self.subTitleLabel.topAnchor constraintEqualToAnchor:self.mainTitleLabel.bottomAnchor constant:2],
        [self.subTitleLabel.leadingAnchor constraintEqualToAnchor:titleView.leadingAnchor],
        [self.subTitleLabel.trailingAnchor constraintEqualToAnchor:titleView.trailingAnchor],
        [self.subTitleLabel.bottomAnchor constraintEqualToAnchor:titleView.bottomAnchor constant:-4]
    ]];
    
    self.navigationItem.titleView = titleView;
}

- (void)createWordCountButtons {
    NSArray *titles = @[L(@"unlimited"), [NSString stringWithFormat:@"100%@",L(@"words")], [NSString stringWithFormat:@"300%@",L(@"words")], [NSString stringWithFormat:@"600%@",L(@"words")], [NSString stringWithFormat:@"1000%@",L(@"words")]];
    
    for (NSInteger i = 0; i < self.wordCountOptions.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setTitle:titles[i] forState:UIControlStateNormal];
        [button setTitleColor:AIUAUIColorRGB(68, 68, 68) forState:UIControlStateNormal];
        button.titleLabel.font = AIUAUIFontSystem(14);
        button.backgroundColor = [UIColor clearColor];
        button.layer.cornerRadius = 6;
        button.layer.masksToBounds = YES;
        button.layer.borderWidth = 1;
        button.layer.borderColor = AIUAUIColorRGB(229, 231, 235).CGColor;
        button.tag = i;
        [button addTarget:self action:@selector(wordCountButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.wordCountContainer addSubview:button];
        [self.wordCountButtons addObject:button];
    }
    
    // 设置默认选中状态
    [self updateWordCountButtonStates];
}

- (void)setupConstraints {
    // 滚动视图
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // 滚动视图
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.bottomContainer.topAnchor],
        
        // 内容视图
        [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor],
        
        // 输入容器
        [self.inputContainer.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16],
        [self.inputContainer.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [self.inputContainer.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [self.inputContainer.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-16],
        
        // 底部容器
        [self.bottomContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.bottomContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.bottomContainer.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-16],
        [self.bottomContainer.heightAnchor constraintEqualToConstant:60]
    ]];
    
    // 输入容器内部布局
    [self setupInputContainerConstraints];
    
    // 底部按钮布局
    [self setupBottomContainerConstraints];
    
    // 字数选择按钮布局
    [self setupWordCountButtonsConstraints];
}

- (void)setupInputContainerConstraints {
    self.themeTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.themeContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.themeTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.themeClearButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.requirementTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.requirementContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.requirementTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.requirementPlaceholder.translatesAutoresizingMaskIntoConstraints = NO;
    self.requirementClearButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.wordCountTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.wordCountContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // 主题标题
        [self.themeTitleLabel.topAnchor constraintEqualToAnchor:self.inputContainer.topAnchor constant:24],
        [self.themeTitleLabel.leadingAnchor constraintEqualToAnchor:self.inputContainer.leadingAnchor constant:16],
        [self.themeTitleLabel.trailingAnchor constraintEqualToAnchor:self.inputContainer.trailingAnchor constant:-16],
        
        // 主题容器
        [self.themeContainer.topAnchor constraintEqualToAnchor:self.themeTitleLabel.bottomAnchor constant:8],
        [self.themeContainer.leadingAnchor constraintEqualToAnchor:self.inputContainer.leadingAnchor constant:16],
        [self.themeContainer.trailingAnchor constraintEqualToAnchor:self.inputContainer.trailingAnchor constant:-16],
        [self.themeContainer.heightAnchor constraintEqualToConstant:48],
        
        // 主题输入框
        [self.themeTextField.topAnchor constraintEqualToAnchor:self.themeContainer.topAnchor],
        [self.themeTextField.leadingAnchor constraintEqualToAnchor:self.themeContainer.leadingAnchor constant:12],
        [self.themeTextField.trailingAnchor constraintEqualToAnchor:self.themeClearButton.leadingAnchor constant:-8],
        [self.themeTextField.bottomAnchor constraintEqualToAnchor:self.themeContainer.bottomAnchor],
        
        // 主题清空按钮
        [self.themeClearButton.trailingAnchor constraintEqualToAnchor:self.themeContainer.trailingAnchor constant:-12],
        [self.themeClearButton.centerYAnchor constraintEqualToAnchor:self.themeContainer.centerYAnchor],
        [self.themeClearButton.widthAnchor constraintEqualToConstant:20],
        [self.themeClearButton.heightAnchor constraintEqualToConstant:20],
        
        // 要求标题
        [self.requirementTitleLabel.topAnchor constraintEqualToAnchor:self.themeContainer.bottomAnchor constant:24],
        [self.requirementTitleLabel.leadingAnchor constraintEqualToAnchor:self.inputContainer.leadingAnchor constant:16],
        [self.requirementTitleLabel.trailingAnchor constraintEqualToAnchor:self.inputContainer.trailingAnchor constant:-16],
        
        // 要求容器
        [self.requirementContainer.topAnchor constraintEqualToAnchor:self.requirementTitleLabel.bottomAnchor constant:8],
        [self.requirementContainer.leadingAnchor constraintEqualToAnchor:self.inputContainer.leadingAnchor constant:16],
        [self.requirementContainer.trailingAnchor constraintEqualToAnchor:self.inputContainer.trailingAnchor constant:-16],
        [self.requirementContainer.heightAnchor constraintEqualToConstant:120],
        
        // 要求输入框
        [self.requirementTextView.topAnchor constraintEqualToAnchor:self.requirementContainer.topAnchor constant:8],
        [self.requirementTextView.leadingAnchor constraintEqualToAnchor:self.requirementContainer.leadingAnchor constant:8],
        [self.requirementTextView.trailingAnchor constraintEqualToAnchor:self.requirementClearButton.leadingAnchor constant:-8],
        [self.requirementTextView.bottomAnchor constraintEqualToAnchor:self.requirementContainer.bottomAnchor constant:-8],
        
        // 要求占位符
        [self.requirementPlaceholder.topAnchor constraintEqualToAnchor:self.requirementTextView.topAnchor constant:8],
        [self.requirementPlaceholder.leadingAnchor constraintEqualToAnchor:self.requirementTextView.leadingAnchor constant:4],
        [self.requirementPlaceholder.trailingAnchor constraintEqualToAnchor:self.requirementTextView.trailingAnchor],
        
        // 要求清空按钮
        [self.requirementClearButton.topAnchor constraintEqualToAnchor:self.requirementContainer.topAnchor constant:12],
        [self.requirementClearButton.trailingAnchor constraintEqualToAnchor:self.requirementContainer.trailingAnchor constant:-12],
        [self.requirementClearButton.widthAnchor constraintEqualToConstant:20],
        [self.requirementClearButton.heightAnchor constraintEqualToConstant:20],
        
        // 字数标题
        [self.wordCountTitleLabel.topAnchor constraintEqualToAnchor:self.requirementContainer.bottomAnchor constant:24],
        [self.wordCountTitleLabel.leadingAnchor constraintEqualToAnchor:self.inputContainer.leadingAnchor constant:16],
        [self.wordCountTitleLabel.trailingAnchor constraintEqualToAnchor:self.inputContainer.trailingAnchor constant:-16],
        
        // 字数容器
        [self.wordCountContainer.topAnchor constraintEqualToAnchor:self.wordCountTitleLabel.bottomAnchor constant:12],
        [self.wordCountContainer.leadingAnchor constraintEqualToAnchor:self.inputContainer.leadingAnchor constant:16],
        [self.wordCountContainer.trailingAnchor constraintEqualToAnchor:self.inputContainer.trailingAnchor constant:-16],
        [self.wordCountContainer.bottomAnchor constraintEqualToAnchor:self.inputContainer.bottomAnchor constant:-24],
        [self.wordCountContainer.heightAnchor constraintEqualToConstant:40]
    ]];
}

- (void)setupBottomContainerConstraints {
    self.favoriteButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.generateButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // 收藏按钮
        [self.favoriteButton.leadingAnchor constraintEqualToAnchor:self.bottomContainer.leadingAnchor],
        [self.favoriteButton.centerYAnchor constraintEqualToAnchor:self.bottomContainer.centerYAnchor],
        [self.favoriteButton.widthAnchor constraintEqualToConstant:60],
        [self.favoriteButton.heightAnchor constraintEqualToConstant:60],
        
        // 生成按钮
        [self.generateButton.leadingAnchor constraintEqualToAnchor:self.favoriteButton.trailingAnchor constant:12],
        [self.generateButton.trailingAnchor constraintEqualToAnchor:self.bottomContainer.trailingAnchor],
        [self.generateButton.centerYAnchor constraintEqualToAnchor:self.bottomContainer.centerYAnchor],
        [self.generateButton.heightAnchor constraintEqualToConstant:60]
    ]];
}

- (void)setupWordCountButtonsConstraints {
    for (NSInteger i = 0; i < self.wordCountButtons.count; i++) {
        UIButton *button = self.wordCountButtons[i];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        CGFloat buttonWidth = (AIUAScreenWidth - 32 - 32 - 16) / 5; // 屏幕宽度 - 左右边距 - 容器边距 - 按钮间距
        
        [NSLayoutConstraint activateConstraints:@[
            [button.topAnchor constraintEqualToAnchor:self.wordCountContainer.topAnchor],
            [button.bottomAnchor constraintEqualToAnchor:self.wordCountContainer.bottomAnchor],
            [button.widthAnchor constraintEqualToConstant:buttonWidth],
            [button.heightAnchor constraintEqualToConstant:36]
        ]];
        
        if (i == 0) {
            [button.leadingAnchor constraintEqualToAnchor:self.wordCountContainer.leadingAnchor].active = YES;
        } else {
            UIButton *previousButton = self.wordCountButtons[i - 1];
            [button.leadingAnchor constraintEqualToAnchor:previousButton.trailingAnchor constant:4].active = YES;
        }
    }
}

- (void)setupDefaultValues {
    // 设置模板的默认值
    self.themeTextField.text = self.templateItem[@"title"];
    
    // 监听文本变化
    [self.themeTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
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

#pragma mark - 按钮事件

- (void)clearTheme {
    self.themeTextField.text = @"";
    self.themeClearButton.alpha = 0;
}

- (void)clearRequirement {
    self.requirementTextView.text = @"";
    self.requirementPlaceholder.hidden = NO;
    self.requirementClearButton.alpha = 0;
}

- (void)wordCountButtonTapped:(UIButton *)sender {
    self.selectedWordCount = [self.wordCountOptions[sender.tag] integerValue];
    [self updateWordCountButtonStates];
}

- (void)favoriteButtonTapped {
    BOOL isFavorite = !self.favoriteButton.selected;
    NSString *itemId = [[AIUADataManager sharedManager] getItemId:self.templateItem];
    if ([[AIUADataManager sharedManager] isFavorite:itemId]) {
        WeakType(self);
        [AIUAAlertHelper showAlertWithTitle:L(@"confirm_unfavorite")
                                    message:nil
                              cancelBtnText:L(@"think_it_over")
                             confirmBtnText:L(@"confirm")
                               inController:nil
                               cancelAction:nil confirmAction:^{
            StrongType(self);
            strongself.favoriteButton.tintColor = AIUAUIColorSimplifyRGB(0.6, 0.6, 0.6); // 灰色
            // 取消收藏
            [[AIUADataManager sharedManager] removeFavorite:itemId];
            self.favoriteButton.selected = isFavorite;
        }];
    } else {
        self.favoriteButton.tintColor = AIUAUIColorSimplifyRGB(1.0, 0.2, 0.2);
        // 添加收藏
        [[AIUADataManager sharedManager] addFavorite:self.templateItem];
        [AIUAMBProgressManager showText:nil withText:L(@"favorited") andSubText:nil isBottom:YES];
        self.favoriteButton.selected = isFavorite;
    }
}

- (void)generateWriting {
    NSString *theme = [self.themeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *requirement = [self.requirementTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (theme.length == 0) {
        [self showAlertWithTitle:L(@"prompt") message:L(@"enter_topic")];
        return;
    }
    
    if (requirement.length == 0) {
        [self showAlertWithTitle:L(@"prompt") message:L(@"enter_specific_requirements")];
        return;
    }
    
    // 构建完整的提示词
    NSString *prompt = [NSString stringWithFormat:@"%@:%@，%@:%@", L(@"theme"), theme, L(@"require"), requirement];
    if (self.selectedWordCount > 0) {
        AIUAWritingDetailViewController *detailVC = [[AIUAWritingDetailViewController alloc] initWithPrompt:prompt apiKey:self.apiKey type:self.type wordCount:self.selectedWordCount];
        [self.navigationController pushViewController:detailVC animated:YES];
    } else {
        AIUAWritingDetailViewController *detailVC = [[AIUAWritingDetailViewController alloc] initWithPrompt:prompt apiKey:self.apiKey type:self.type ];
        [self.navigationController pushViewController:detailVC animated:YES];
    }
}

#pragma mark - UITextField & UITextView Delegate

- (void)textFieldDidChange:(UITextField *)textField {
    self.themeClearButton.alpha = textField.text.length > 0 ? 1 : 0;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.themeClearButton.alpha = textField.text.length > 0 ? 1 : 0;
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.themeClearButton.alpha = 0;
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.requirementClearButton.alpha = textView.text.length > 0 ? 1 : 0;
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.requirementPlaceholder.hidden = textView.text.length > 0;
    self.requirementClearButton.alpha = textView.text.length > 0 ? 1 : 0;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    self.requirementClearButton.alpha = 0;
}

#pragma mark - 键盘处理

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, keyboardFrame.size.height - self.view.safeAreaInsets.bottom, 0);
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        self.scrollView.contentInset = UIEdgeInsetsZero;
    }];
}

#pragma mark - 辅助方法

- (void)updateWordCountButtonStates {
    for (NSInteger i = 0; i < self.wordCountButtons.count; i++) {
        UIButton *button = self.wordCountButtons[i];
        NSInteger wordCount = [self.wordCountOptions[i] integerValue];
        
        if (wordCount == self.selectedWordCount) {
            button.backgroundColor = AIUAUIColorRGB(59, 130, 246);
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.layer.borderColor = AIUAUIColorRGB(59, 130, 246).CGColor;
        } else {
            button.backgroundColor = [UIColor clearColor];
            [button setTitleColor:AIUAUIColorRGB(68, 68, 68) forState:UIControlStateNormal];
            button.layer.borderColor = AIUAUIColorRGB(229, 231, 235).CGColor;
        }
    }
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    [AIUAAlertHelper showAlertWithTitle:title message:message cancelBtnText:nil confirmBtnText:L(@"confirm") inController:nil cancelAction:nil confirmAction:nil];
}

@end
