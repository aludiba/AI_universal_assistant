#import "AIUAHotViewController.h"
#import "AIUAHotCardCollectionViewCell.h"
#import "AIUADataManager.h"

static NSString * const kCardCellId = @"CardCell";

@interface AIUAHotViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIScrollView *categoryScroll;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *collectionLayout;

@property (nonatomic, strong) NSArray *categories;
@property (nonatomic, strong) NSArray *currentItems;
@property (nonatomic, assign) NSInteger selectedCategoryIndex;

@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) NSMutableArray *categoryButtons;

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
    self.categories = [[AIUADataManager sharedManager] loadHotCategories];
    self.categoryButtons = [NSMutableArray array];
    self.selectedCategoryIndex = 0;
    
    [self loadCategoryButtons];
    [self updateContentForSelectedCategory];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateCategorySelection];
}

- (void)setupSearchBar {
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 120, 36)];
    self.searchBar.placeholder = L(@"enter_keywords_to_search_templates");
    self.searchBar.delegate = self;
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.backgroundImage = [[UIImage alloc] init];
    self.searchBar.backgroundColor = AIUAUIColorSimplifyRGB(0.98, 0.98, 0.98);
    self.searchBar.layer.cornerRadius = 18;
    self.searchBar.layer.masksToBounds = YES;
    
    // 设置搜索图标颜色
    UITextField *searchField = [self.searchBar valueForKey:@"searchField"];
    if (searchField) {
        searchField.backgroundColor = [UIColor clearColor];
        searchField.layer.cornerRadius = 18;
        searchField.layer.masksToBounds = YES;
    }
    
    self.navigationItem.titleView = self.searchBar;
}

- (void)setupCategoryScroll {
    self.categoryScroll = [[UIScrollView alloc] init];
    self.categoryScroll.translatesAutoresizingMaskIntoConstraints = NO;
    self.categoryScroll.showsHorizontalScrollIndicator = NO;
    self.categoryScroll.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.categoryScroll];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.categoryScroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.categoryScroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.categoryScroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.categoryScroll.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)setupCollectionView {
    self.collectionLayout = [[UICollectionViewFlowLayout alloc] init];
    self.collectionLayout.minimumLineSpacing = 16;
    self.collectionLayout.minimumInteritemSpacing = 16;
    self.collectionLayout.sectionInset = UIEdgeInsetsMake(16, 16, 16, 16);
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.collectionLayout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsVerticalScrollIndicator = NO;
    [self.collectionView registerClass:[AIUAHotCardCollectionViewCell class] forCellWithReuseIdentifier:kCardCellId];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    // 添加左右滑动手势识别
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.collectionView addGestureRecognizer:swipeLeft];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.collectionView addGestureRecognizer:swipeRight];
    
    [self.view addSubview:self.collectionView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor constraintEqualToAnchor:self.categoryScroll.bottomAnchor constant:8],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
}

- (void)loadCategoryButtons {
    // 清空现有按钮
    for (UIView *subview in self.categoryScroll.subviews) {
        [subview removeFromSuperview];
    }
    [self.categoryButtons removeAllObjects];
    
    CGFloat x = 16;
    CGFloat buttonHeight = 32;
    
    for (NSInteger i = 0; i < self.categories.count; i++) {
        NSDictionary *category = self.categories[i];
        NSString *title = category[@"title"];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(x, 6, 0, buttonHeight);
        button.backgroundColor = [UIColor clearColor];
        button.titleLabel.font = AIUAUIFontMedium(15);
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:AIUAUIColorSimplifyRGB(0.4, 0.4, 0.4) forState:UIControlStateNormal];
        [button setTitleColor:AIUAUIColorSimplifyRGB(0.2, 0.4, 0.8) forState:UIControlStateSelected];
        [button addTarget:self action:@selector(categoryButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = i;
        
        // 计算按钮宽度
        CGSize textSize = [title sizeWithAttributes:@{NSFontAttributeName: button.titleLabel.font}];
        CGFloat buttonWidth = textSize.width + 24;
        button.frame = CGRectMake(x, 6, buttonWidth, buttonHeight);
        
        [self.categoryScroll addSubview:button];
        [self.categoryButtons addObject:button];
        
        x += buttonWidth + 12;
    }
    
    self.categoryScroll.contentSize = CGSizeMake(x, 44);
    
    // 添加指示器
    if (self.indicatorView) {
        [self.indicatorView removeFromSuperview];
    }
    self.indicatorView = [[UIView alloc] init];
    self.indicatorView.backgroundColor = AIUAUIColorSimplifyRGB(0.2, 0.4, 0.8);
    self.indicatorView.layer.cornerRadius = 2;
    [self.categoryScroll addSubview:self.indicatorView];
}

- (void)updateCategorySelection {
    // 更新按钮选中状态
    for (NSInteger i = 0; i < self.categoryButtons.count; i++) {
        UIButton *button = self.categoryButtons[i];
        button.selected = (i == self.selectedCategoryIndex);
        button.titleLabel.font = [UIFont systemFontOfSize:(i == self.selectedCategoryIndex) ? 18 : 15 weight:
                                 (i == self.selectedCategoryIndex) ? UIFontWeightSemibold : UIFontWeightMedium];
    }
    
    // 更新指示器位置
    UIButton *selectedButton = self.categoryButtons[self.selectedCategoryIndex];
    [UIView animateWithDuration:0.3 animations:^{
        self.indicatorView.frame = CGRectMake(selectedButton.frame.origin.x,
                                            self.categoryScroll.bounds.size.height - 4,
                                            selectedButton.frame.size.width,
                                            3);
    }];
    
    // 滚动到选中的分类
    CGRect visibleRect = CGRectMake(selectedButton.frame.origin.x - 16, 0,
                                   selectedButton.frame.size.width + 32, self.categoryScroll.bounds.size.height);
    [self.categoryScroll scrollRectToVisible:visibleRect animated:YES];
}

- (void)updateContentForSelectedCategory {
    NSDictionary *selectedCategory = self.categories[self.selectedCategoryIndex];
    NSString *categoryId = selectedCategory[@"id"];
    self.currentItems = [[AIUADataManager sharedManager] getItemsForCategory:categoryId];
    [self.collectionView reloadData];
}

#pragma mark - Actions

- (void)categoryButtonTapped:(UIButton *)sender {
    self.selectedCategoryIndex = sender.tag;
    [self updateCategorySelection];
    [self updateContentForSelectedCategory];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gesture {
    if (gesture.direction == UISwipeGestureRecognizerDirectionLeft) {
        // 向左滑动，切换到下一个分类
        if (self.selectedCategoryIndex < self.categories.count - 1) {
            self.selectedCategoryIndex++;
            [self updateCategorySelection];
            [self updateContentForSelectedCategory];
        }
    } else if (gesture.direction == UISwipeGestureRecognizerDirectionRight) {
        // 向右滑动，切换到上一个分类
        if (self.selectedCategoryIndex > 0) {
            self.selectedCategoryIndex--;
            [self updateCategorySelection];
            [self updateContentForSelectedCategory];
        }
    }
}

- (void)setupGestureRecognizer {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
}

- (void)dismissKeyboard {
    [self.searchBar resignFirstResponder];
}

#pragma mark - UICollectionView DataSource & Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.currentItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AIUAHotCardCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCardCellId forIndexPath:indexPath];
    
    NSDictionary *item = self.currentItems[indexPath.item];
    [cell configureWithTitle:item[@"title"] 
                   subtitle:item[@"subtitle"] 
                   iconName:item[@"icon"]];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat totalPadding = 16 + 16 + 16; // sectionInsets + interitem
    CGFloat width = (collectionView.bounds.size.width - totalPadding) / 2.0;
    return CGSizeMake(width, 120);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = self.currentItems[indexPath.item];
    NSLog(@"选中模板：%@ - %@", item[@"title"], item[@"type"]);
    
    // TODO: 跳转到对应的写作页面
    // [self navigateToWritingWithType:item[@"type"] title:item[@"title"]];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *text = searchBar.text;
    [searchBar resignFirstResponder];
    NSLog(@"搜索关键词：%@", text);
    // TODO: 实现搜索功能
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self dismissKeyboard];
}

@end
