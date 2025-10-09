//
//  AIUASearchViewController.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/9/25.
//

#import "AIUASearchViewController.h"
#import "AIUASearchResultCell.h"
#import "AIUAHistorySearchCell.h"

@interface AIUASearchViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

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

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"搜索";
    [self loadCategoriesData];
    [self loadHistorySearches];
}

- (void)setupUI {
    // 搜索栏
//    self.searchBar = [[UISearchBar alloc] init];
//    self.searchBar.placeholder = @"搜索模板类型";
//    self.searchBar.delegate = self;
//    self.searchBar.backgroundImage = [[UIImage alloc] init];
//    self.searchBar.backgroundColor = [UIColor whiteColor];
//    self.searchBar.layer.cornerRadius = 8;
//    self.searchBar.layer.masksToBounds = YES;
//    self.searchBar.layer.borderWidth = 1;
//    self.searchBar.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
//    [self.view addSubview:self.searchBar];
    
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
    emptyLabel.text = @"没有找到相关模板";
    emptyLabel.font = [UIFont systemFontOfSize:16];
    emptyLabel.textColor = [UIColor grayColor];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    [self.emptyView addSubview:emptyLabel];
    
    UIButton *writerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [writerButton setTitle:@"去写作模块看看 →" forState:UIControlStateNormal];
    [writerButton setTitleColor:[UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:1.0] forState:UIControlStateNormal];
    writerButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [writerButton addTarget:self action:@selector(goToWriterModule) forControlEvents:UIControlEventTouchUpInside];
    [self.emptyView addSubview:writerButton];
    
    // 设置约束
    [self setupConstraintsWithEmptyLabel:emptyLabel writerButton:writerButton];
}

- (void)setupConstraintsWithEmptyLabel:(UILabel *)emptyLabel writerButton:(UIButton *)writerButton {
//    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyView.translatesAutoresizingMaskIntoConstraints = NO;
    emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    writerButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // 搜索栏约束
//        [self.searchBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
//        [self.searchBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
//        [self.searchBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
//        [self.searchBar.heightAnchor constraintEqualToConstant:44],
        
        // 表格视图约束
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        
        // 空状态视图约束
        [self.emptyView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor],
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

- (void)setupData {
    [super setupData];
    self.searchResults = @[];
    self.historySearches = [NSMutableArray array];
    self.isSearching = NO;
    self.showHistory = NO;
}

- (void)loadCategoriesData {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"AIUAHotCategories" ofType:@"plist"];
    NSArray *categoriesArray = [NSArray arrayWithContentsOfFile:path];
    
    NSMutableArray *allItems = [NSMutableArray array];
    for (NSDictionary *category in categoriesArray) {
        NSArray *items = category[@"items"];
        for (NSDictionary *item in items) {
            [allItems addObject:item];
        }
    }
    
    self.allCategories = [allItems copy];
}

- (void)loadHistorySearches {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *historyPath = [documentsPath stringByAppendingPathComponent:@"SearchHistory.plist"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:historyPath]) {
        NSArray *history = [NSArray arrayWithContentsOfFile:historyPath];
        self.historySearches = [history mutableCopy];
    } else {
        self.historySearches = [NSMutableArray array];
    }
    
    self.showHistory = self.historySearches.count > 0;
}

- (void)saveHistorySearches {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *historyPath = [documentsPath stringByAppendingPathComponent:@"SearchHistory.plist"];
    
    [self.historySearches writeToFile:historyPath atomically:YES];
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
    // 跳转到写作模块

}

- (UIView *)createHistoryHeaderView {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    headerView.backgroundColor = [UIColor whiteColor];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"历史搜索";
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
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
    borderView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
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

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self performSearchWithText:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - UITableViewDataSource

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
        NSString *type = item[@"type"];
        
        // 添加到历史搜索
        [self addToHistory:title];
        
        // 处理模板选择
        [self handleTemplateSelectionWithType:type title:title];
    } else {
        // 点击历史搜索项，开始搜索
        NSString *historyText = self.historySearches[indexPath.row];
        self.searchBar.text = historyText;
        [self performSearchWithText:historyText];
        [self.searchBar resignFirstResponder];
    }
}

- (void)handleTemplateSelectionWithType:(NSString *)type title:(NSString *)title {
    // 这里可以处理模板选择后的逻辑
    NSLog(@"选择了模板: %@, 类型: %@", title, type);
    
    // 示例：显示提示
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"模板选择"
                                                                   message:[NSString stringWithFormat:@"您选择了: %@", title]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
