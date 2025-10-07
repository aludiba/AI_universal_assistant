//
//  AIUAHotViewController.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/3/25.
//

#import "AIUAHotViewController.h"
#import "AIUAHotCardCollectionViewCell.h"

static NSString * const kCardCellId = @"CardCell";

@interface AIUAHotViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIScrollView *categoryScroll;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray<NSDictionary *> *items; // 每项 title / subtitle / iconName

@end

@implementation AIUAHotViewController

- (void)setupUI {
    self.navigationItem.title = L(@"tab_hot");
    [self setupSearchBar];
    [self setupCategoryScroll];
    [self setupCollectionView];
    [self setupGestureRecognizer];
}

- (void)setupData {
    [self loadDummyData];
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

- (void)setupSearchBar {
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = L(@"search_placeholder");
    self.searchBar.delegate = self;
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.navigationItem.titleView = self.searchBar;
}

- (void)setupCategoryScroll {
    self.categoryScroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.categoryScroll.translatesAutoresizingMaskIntoConstraints = NO;
    self.categoryScroll.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:self.categoryScroll];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.categoryScroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.categoryScroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [self.categoryScroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [self.categoryScroll.heightAnchor constraintEqualToConstant:36]
    ]];
    
    NSArray *categories = @[L(@"tab_hot"), L(@"category_socialMedia"), L(@"category_school"), L(@"category_workplace"), L(@"category_marketing"), L(@"category_life")];
    CGFloat x = 0;
    for (NSString *title in categories) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:title forState:UIControlStateNormal];
        btn.frame = CGRectMake(x, 0, 80, 36);
        btn.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
        btn.layer.cornerRadius = 18;
        btn.clipsToBounds = YES;
        btn.titleLabel.font = AIUAUIFontSystem(14);
        [btn addTarget:self action:@selector(categoryTap:) forControlEvents:UIControlEventTouchUpInside];
        [self.categoryScroll addSubview:btn];
        x += 90;
    }
    self.categoryScroll.contentSize = CGSizeMake(x, 36);
}

- (void)categoryTap:(UIButton *)sender {
    NSLog(@"选择分类: %@", sender.titleLabel.text);
    // TODO: 根据分类刷新 collectionView 数据
}

- (void)setupCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 12;
    layout.minimumInteritemSpacing = 12;
    layout.sectionInset = UIEdgeInsetsMake(12, 12, 12, 12);
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = [UIColor clearColor];
    [self.collectionView registerClass:[AIUAHotCardCollectionViewCell class] forCellWithReuseIdentifier:kCardCellId];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    [self.view addSubview:self.collectionView];
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor constraintEqualToAnchor:self.categoryScroll.bottomAnchor constant:8],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)loadDummyData {
    self.items = @[
        @{@"title":@"演讲稿", @"subtitle":@"机会留给准备更充分的人", @"icon":@"icon1"},
        @{@"title":@"心得体会", @"subtitle":@"你在校园里获得的心得体会，真情实感", @"icon":@"icon2"},
        @{@"title":@"检讨书", @"subtitle":@"知错能改善莫大焉", @"icon":@"icon3"},
        @{@"title":@"大学生实习报告", @"subtitle":@"你也来临时抱佛脚啦？", @"icon":@"icon4"},
        @{@"title":@"小红书爆款文案", @"subtitle":@"标题、笔记、标签，一键全搞定～", @"icon":@"icon5"},
        @{@"title":@"诗词写作", @"subtitle":@"输入主题，我来帮您写唐诗。", @"icon":@"icon6"}
    ];
    [self.collectionView reloadData];
}

#pragma mark - UICollectionView dataSource / delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self dismissKeyboard];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AIUAHotCardCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCardCellId forIndexPath:indexPath];
    NSDictionary *info = self.items[indexPath.item];
    cell.titleLabel.text = info[@"title"];
    cell.subtitleLabel.text = info[@"subtitle"];
    // 占位 icon，可换成真实图片名或 SF Symbol（iOS13+）
    cell.iconView.image = [UIImage imageNamed:info[@"icon"]];
    cell.contentView.backgroundColor = [UIColor whiteColor];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat totalPadding = 12 + 12 + 12; // sectionInsets + interitem
    CGFloat width = (collectionView.bounds.size.width - totalPadding) / 2.0 - 6;
    return CGSizeMake(width, 120);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *info = self.items[indexPath.item];
    NSLog(@"选中卡片：%@", info[@"title"]);
    // TODO: 点击进入模板详情
}

#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *text = searchBar.text;
    [searchBar resignFirstResponder];
    NSLog(@"搜索关键词：%@", text);
    // TODO: 搜索逻辑
}

@end
