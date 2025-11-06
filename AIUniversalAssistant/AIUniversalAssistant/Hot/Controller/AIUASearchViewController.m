//
//  AIUASearchViewController.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/9/25.
//

#import "AIUASearchViewController.h"
#import "AIUASearchResultCell.h"
#import "AIUAHistorySearchCell.h"
#import "AIUADataManager.h"
#import "AIUAToolsManager.h"
#import "AIUAAlertHelper.h"
#import "AIUAWritingInputViewController.h"
#import "AIUAVIPManager.h"

@interface AIUASearchViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *emptyView;
@property (nonatomic, strong) UIView *historyHeaderView;

@property (nonatomic, strong) NSArray *allCategories;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) NSMutableArray *historySearches;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, assign) BOOL showHistory;

@end

@implementation AIUASearchViewController


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationItem.titleView = self.titleView;
    [self.searchBar becomeFirstResponder];
}

- (void)setupUI {
    [super setupUI];
    [self setupSearchBar];
    // 表格视图
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = AIUA_BACK_COLOR;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.tableView registerClass:[AIUASearchResultCell class] forCellReuseIdentifier:@"SearchResultCell"];
    [self.tableView registerClass:[AIUAHistorySearchCell class] forCellReuseIdentifier:@"HistorySearchCell"];
    [self.view addSubview:self.tableView];
    
    // 空状态视图
    self.emptyView = [[UIView alloc] init];
    self.emptyView.backgroundColor = AIUA_BACK_COLOR;
    self.emptyView.hidden = YES;
    [self.view addSubview:self.emptyView];
    
    UILabel *emptyLabel = [[UILabel alloc] init];
    emptyLabel.text = L(@"no_related_templates_found");
    emptyLabel.font = AIUAUIFontSystem(16);
    emptyLabel.textColor = [UIColor grayColor];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    [self.emptyView addSubview:emptyLabel];
    
    UIButton *writerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [writerButton setTitle:L(@"go_to_writing_module") forState:UIControlStateNormal];
    [writerButton setTitleColor:AIUA_BLUE_COLOR forState:UIControlStateNormal];
    writerButton.titleLabel.font = AIUAUIFontSystem(14);
    [writerButton addTarget:self action:@selector(goToWriterModule) forControlEvents:UIControlEventTouchUpInside];
    [self.emptyView addSubview:writerButton];
    
    // 设置约束
    [self setupConstraintsWithEmptyLabel:emptyLabel writerButton:writerButton];
    
    [self setupGestureRecognizer];
}

- (void)setupData {
    [super setupData];
    self.searchResults = @[];
    self.historySearches = [NSMutableArray array];
    self.isSearching = NO;
    self.showHistory = NO;
    self.allCategories = [[NSMutableArray alloc] initWithArray:[[AIUADataManager sharedManager] loadSearchCategoriesData]];
    [self loadHistorySearches];
}

- (void)setupSearchBar {
    // 创建自定义视图作为 titleView，确保垂直居中
    CGFloat width = self.view.bounds.size.width - 68;
    if (@available(iOS 26.0, *)) {
        width = self.view.bounds.size.width - 88;
    }
    self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 44)];
    self.titleView.backgroundColor = [UIColor clearColor];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 4, self.titleView.bounds.size.width, 36)];
    self.searchBar.tintColor = [UIColor lightGrayColor];
    self.searchBar.backgroundColor = [UIColor clearColor];
    self.searchBar.placeholder = L(@"enter_keywords_to_search_templates");
    self.searchBar.delegate = self;
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.layer.cornerRadius = 18;
    self.searchBar.layer.masksToBounds = YES;
    
    UITextField *searchField = self.searchBar.searchTextField;
    searchField.tintColor = [UIColor lightGrayColor];
    searchField.backgroundColor = [UIColor clearColor];
    searchField.layer.cornerRadius = 18;
    searchField.layer.masksToBounds = YES;
    
    [self.titleView addSubview:self.searchBar];
}

- (UIView *)createHistoryHeaderView {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    headerView.backgroundColor = [UIColor whiteColor];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = L(@"search_history");
    titleLabel.font = AIUAUIFontMedium(16);
    titleLabel.textColor = [UIColor darkTextColor];
    [headerView addSubview:titleLabel];
    
    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [clearButton setImage:[UIImage systemImageNamed:@"trash"] forState:UIControlStateNormal];
    [clearButton setTintColor:[UIColor grayColor]];
    [clearButton addTarget:self action:@selector(clearAllHistory) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:clearButton];
    
    // 设置约束
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor constant:16],
        [titleLabel.centerYAnchor constraintEqualToAnchor:headerView.centerYAnchor],
        
        [clearButton.trailingAnchor constraintEqualToAnchor:headerView.trailingAnchor constant:-16],
        [clearButton.centerYAnchor constraintEqualToAnchor:headerView.centerYAnchor],
        [clearButton.widthAnchor constraintEqualToConstant:24],
        [clearButton.heightAnchor constraintEqualToConstant:24]
    ]];
    
    // 添加底部边框
    UIView *borderView = [[UIView alloc] init];
    borderView.backgroundColor = AIUA_DIVIDER_COLOR;
    [headerView addSubview:borderView];
    
    borderView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [borderView.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor],
        [borderView.trailingAnchor constraintEqualToAnchor:headerView.trailingAnchor],
        [borderView.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor],
        [borderView.heightAnchor constraintEqualToConstant:0.5]
    ]];
    
    return headerView;
}

- (void)setupConstraintsWithEmptyLabel:(UILabel *)emptyLabel writerButton:(UIButton *)writerButton {
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyView.translatesAutoresizingMaskIntoConstraints = NO;
    emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    writerButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // 表格视图约束
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        
        // 空状态视图约束
        [self.emptyView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.emptyView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.emptyView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.emptyView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        
        // 空状态标签约束
        [emptyLabel.centerXAnchor constraintEqualToAnchor:self.emptyView.centerXAnchor],
        [emptyLabel.centerYAnchor constraintEqualToAnchor:self.emptyView.centerYAnchor constant:-20],
        
        // 写作按钮约束
        [writerButton.centerXAnchor constraintEqualToAnchor:self.emptyView.centerXAnchor],
        [writerButton.topAnchor constraintEqualToAnchor:emptyLabel.bottomAnchor constant:12]
    ]];
}

- (void)loadHistorySearches {
    self.historySearches = [NSMutableArray arrayWithArray:[[AIUADataManager sharedManager] loadSearchHistorySearches]];
    self.showHistory = self.historySearches.count > 0;
}

#pragma mark - actions

// 返回按钮点击事件
- (void)backButtonTapped {
    [self clearSearchs];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveHistorySearches {
    [[AIUADataManager sharedManager] saveHistorySearches:self.historySearches];
}

- (void)addToHistory:(NSString *)searchText {
    // 移除重复项
    [self.historySearches removeObject:searchText];
    
    // 添加到开头
    [self.historySearches insertObject:searchText atIndex:0];
    
    // 限制数量为20个
    if (self.historySearches.count > 20) {
        [self.historySearches removeLastObject];
    }
    
    // 保存到文件
    [self saveHistorySearches];
    
    // 更新显示状态
    self.showHistory = self.historySearches.count > 0;
}

- (void)clearAllHistory {
    [self.historySearches removeAllObjects];
    [self saveHistorySearches];
    self.showHistory = NO;
    [self.tableView reloadData];
}

- (void)performSearchWithText:(NSString *)searchText {
    if (searchText.length == 0) {
        self.searchResults = @[];
        self.isSearching = NO;
        self.showHistory = self.historySearches.count > 0;
    } else {
        self.isSearching = YES;
        self.showHistory = NO;
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *item, NSDictionary *bindings) {
            NSString *title = item[@"title"];
            return [title rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound;
        }];
        self.searchResults = [self.allCategories filteredArrayUsingPredicate:predicate];
    }
    
    [self updateUI];
}

- (void)updateUI {
    [self.tableView reloadData];
    
    BOOL showEmptyView = self.isSearching && self.searchResults.count == 0;
    self.emptyView.hidden = !showEmptyView;
    self.tableView.hidden = showEmptyView;
}

- (void)goToWriterModule {
    [self clearSearchs];
    // 去写作模块
    [AIUAToolsManager goToTabBarModule:1];
}

- (void)clearSearchs {
    self.searchBar.searchTextField.text = @"";
    self.searchResults = @[];
    self.isSearching = NO;
    self.showHistory = self.historySearches.count > 0;
    [self updateUI];
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
    [self.searchBar resignFirstResponder];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self performSearchWithText:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self dismissKeyboard];
}

#pragma mark - UITableViewDataSource

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self dismissKeyboard];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isSearching) {
        return self.searchResults.count;
    } else if (self.showHistory) {
        return self.historySearches.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isSearching) {
        AIUASearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchResultCell" forIndexPath:indexPath];
        
        NSDictionary *item = self.searchResults[indexPath.row];
        cell.titleLabel.text = item[@"title"];
        cell.subtitleLabel.text = item[@"subtitle"];
        
        // 设置图标
        NSString *iconName = item[@"icon"];
        if (iconName) {
            UIImage *iconImage = [UIImage systemImageNamed:iconName];
            if (!iconImage) {
                iconImage = [UIImage systemImageNamed:@"doc.text"];
            }
            cell.iconImageView.image = iconImage;
        }
        
        // 隐藏最后一行分隔线
        cell.separatorView.hidden = (indexPath.row == self.searchResults.count - 1);
        
        return cell;
    } else {
        AIUAHistorySearchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HistorySearchCell" forIndexPath:indexPath];
        
        NSString *historyText = self.historySearches[indexPath.row];
        cell.titleLabel.text = historyText;
        
        // 隐藏最后一行分隔线
        cell.separatorView.hidden = (indexPath.row == self.historySearches.count - 1);
        
        return cell;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.showHistory && !self.isSearching) {
        return [self createHistoryHeaderView];
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.showHistory && !self.isSearching) {
        return 44;
    }
    return 0;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isSearching) {
        return 68;
    } else {
        return 50;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.isSearching) {
        NSDictionary *item = self.searchResults[indexPath.row];
        NSString *title = item[@"title"];
        // 添加到历史搜索
        [self addToHistory:title];
        // 处理模板选择
        [self handleTemplateSelection:item];
    } else {
        // 点击历史搜索项，开始搜索
        NSString *historyText = self.historySearches[indexPath.row];
        self.searchBar.text = historyText;
        [self performSearchWithText:historyText];
        [self dismissKeyboard];
    }
}

- (void)handleTemplateSelection:(NSDictionary *)item{
    // 检查VIP权限
    [[AIUAVIPManager sharedManager] checkVIPPermissionWithViewController:self completion:^(BOOL hasPermission) {
        if (hasPermission) {
            AIUAWritingInputViewController *writingInputVC = [[AIUAWritingInputViewController alloc] initWithTemplateItem:item categoryId:item[@"categoryId"] apiKey:APIKEY];
            // 跳转到对应的写作页面
            [self.navigationController pushViewController:writingInputVC animated:YES];
        }
        // 无权限，已显示弹窗
    }];
}

@end
