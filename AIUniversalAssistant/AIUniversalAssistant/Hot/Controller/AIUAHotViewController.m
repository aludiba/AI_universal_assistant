#import "AIUAHotViewController.h"
#import "AIUAHotCardCollectionViewCell.h"
#import "AIUADataManager.h"
#import "AIUAMBProgressManager.h"
#import "AIUAAlertHelper.h"
#import "AIUASearchViewController.h"
#import "AIUAWritingInputViewController.h"

static NSString * const kCardCellId = @"CardCell";
static NSString * const kEmptyCellId = @"EmptyCell";

@interface AIUAHotViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIScrollViewDelegate, AIUAHotCardCollectionViewCellDelegate>

@property (nonatomic, strong) UIButton *searchButton;
@property (nonatomic, strong) UIScrollView *categoryScroll;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *collectionLayout;

@property (nonatomic, strong) NSArray *categories;
@property (nonatomic, strong) NSArray *currentItems;
@property (nonatomic, assign) NSInteger selectedCategoryIndex;

@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) NSMutableArray *categoryButtons;

// 收藏相关数据
@property (nonatomic, strong) NSArray *favoritesItems;
@property (nonatomic, strong) NSArray *recentUsedItems;

@property (nonatomic, strong) AIUASearchViewController *searchVC; // 搜索页

@end

@implementation AIUAHotViewController

- (void)setupUI {
    self.navigationItem.title = L(@"tab_hot");
    [self setupSearchBar];
    [self setupCategoryScroll];
    [self setupCollectionView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.navigationItem.title == nil) {
        self.navigationItem.title = L(@"tab_hot");
    }
    // 每次显示页面时刷新收藏数据
    [self refreshFavoritesData];
    if ([self isFavoriteCategorySelected]) {
        [self updateContentForSelectedCategory];
    } else {
        [self.collectionView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateCategorySelection];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationItem.title = nil;
}

- (void)setupData {
    self.categories = [[AIUADataManager sharedManager] loadHotCategories];
    self.categoryButtons = [NSMutableArray array];
    self.selectedCategoryIndex = 0;
    
    [self loadCategoryButtons];
    [self updateContentForSelectedCategory];
    [self refreshFavoritesData];
    [self refreshRecentUsedData];
}

- (void)setupSearchBar {
    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    searchButton.frame = CGRectMake(0, 0, self.view.bounds.size.width - 32, 36);
    searchButton.tintColor = [UIColor lightGrayColor];

    // 创建配置
    UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
    
    // 设置标题
    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: [UIColor lightGrayColor],
        NSFontAttributeName: AIUAUIFontSystem(16)
    };
    config.attributedTitle = [[NSAttributedString alloc] initWithString:L(@"enter_keywords_to_search_templates") attributes:attributes];
    
    // 设置图标 - 修改颜色为灰色
    UIImage *searchImage = [UIImage systemImageNamed:@"magnifyingglass"];
    config.image = searchImage;
    config.imagePlacement = NSDirectionalRectEdgeLeading; // 图标在标题前面
    config.imagePadding = 8; // 图标和标题之间的间距
    
    // 设置内容对齐方式为靠左
    config.contentInsets = NSDirectionalEdgeInsetsMake(0, 16, 0, 0);
    
    // 设置背景
    config.background.backgroundColor = AIUAUIColorSimplifyRGB(0.98, 0.98, 0.98);
    config.background.cornerRadius = 18;
    
    config.baseForegroundColor = [UIColor lightGrayColor];

    // 应用配置
    searchButton.configuration = config;
    
    // 确保内容靠左对齐
    searchButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    // 添加点击事件
    [searchButton addTarget:self action:@selector(handleSearchBarTap) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.titleView = searchButton;
    self.searchButton = searchButton;
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
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kEmptyCellId];
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
        [button setTitleColor:AIUA_BLUE_COLOR forState:UIControlStateSelected];
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
    self.indicatorView.backgroundColor = AIUA_BLUE_COLOR;
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
    if (self.selectedCategoryIndex < self.categories.count) {
        NSDictionary *selectedCategory = self.categories[self.selectedCategoryIndex];
        if ([[AIUADataManager sharedManager] isFavoriteCategory:selectedCategory]) {
            // 收藏分类 - 使用动态数据
            self.currentItems = @[];
        } else {
            // 常规分类
            NSString *categoryId = selectedCategory[@"id"];
            self.currentItems = [[AIUADataManager sharedManager] getItemsForCategory:categoryId];
        }
    }
    [self.collectionView reloadData];
}

- (void)refreshFavoritesData {
    // 刷新收藏数据
    self.favoritesItems = [[AIUADataManager sharedManager] loadFavorites];
}

- (void)refreshRecentUsedData {
    // 刷新最近使用数据
    self.recentUsedItems = [[AIUADataManager sharedManager] loadRecentUsed];
}

- (BOOL)isFavoriteCategorySelected {
    if (self.selectedCategoryIndex < self.categories.count) {
        NSDictionary *selectedCategory = self.categories[self.selectedCategoryIndex];
        return [[AIUADataManager sharedManager] isFavoriteCategory:selectedCategory];
    }
    return NO;
}

- (AIUASearchViewController *)searchVC {
    if (!_searchVC) {
        _searchVC = [[AIUASearchViewController alloc] init];
        _searchVC.hidesBottomBarWhenPushed = YES;
    }
    return _searchVC;
}

#pragma mark - Actions

- (void)handleSearchBarTap {
    [self.navigationController pushViewController:self.searchVC animated:YES];
}
    
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

#pragma mark - UICollectionView DataSource & Delegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if ([self isFavoriteCategorySelected]) {
        // 收藏页面：我的关注 + 最近使用
        return 2;
    } else {
        // 常规分类页面
        return 1;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([self isFavoriteCategorySelected]) {
            // 收藏页面
            if (section == 0) {
                return self.favoritesItems.count > 0 ? self.favoritesItems.count : 1;
            } else {
                return self.recentUsedItems.count > 0 ? self.recentUsedItems.count : 1;
            }
        } else {
            // 常规分类页面
            return self.currentItems.count;
        }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader] && [self isFavoriteCategorySelected]) {
        
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        // 清空headerView的子视图
        for (UIView *subview in headerView.subviews) {
            [subview removeFromSuperview];
        }
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 10, collectionView.bounds.size.width - 32, 30)];
        if (indexPath.section == 0) {
            titleLabel.text = L(@"my_following");
        } else {
            titleLabel.text = L(@"recently_used");
        }
        titleLabel.font = AIUAUIFontBold(18);
        titleLabel.textColor = AIUAUIColorSimplifyRGB(0.2, 0.2, 0.2);
        [headerView addSubview:titleLabel];
        
        return headerView;
    }
    return nil;
}

// 动态设置header高度
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if ([self isFavoriteCategorySelected]) {
        // 收藏页面：两个section都有header，高度50
        return CGSizeMake(collectionView.bounds.size.width, 50);
    } else {
        // 常规分类页面：没有header，高度为0
        return CGSizeZero;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isFavoriteCategorySelected]) {
        // 收藏页面
        if ((indexPath.section == 0 && self.favoritesItems.count == 0) ||
            (indexPath.section == 1 && self.recentUsedItems.count == 0)) {
            // 空状态cell
            UICollectionViewCell *emptyCell = [collectionView dequeueReusableCellWithReuseIdentifier:kEmptyCellId forIndexPath:indexPath];
            emptyCell.backgroundColor = [UIColor whiteColor];
            emptyCell.layer.cornerRadius = 16;
            
            // 清空现有子视图
            for (UIView *subview in emptyCell.contentView.subviews) {
                [subview removeFromSuperview];
            }
            
            UILabel *emptyLabel = [[UILabel alloc] init];
            emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
            emptyLabel.text = indexPath.section == 0 ? L(@"no_favorite_content_yet") : L(@"no_recent_items");
            emptyLabel.font = AIUAUIFontSystem(14);
            emptyLabel.textColor = AIUAUIColorSimplifyRGB(0.6, 0.6, 0.6);
            emptyLabel.textAlignment = NSTextAlignmentCenter;
            [emptyCell.contentView addSubview:emptyLabel];
            
            [NSLayoutConstraint activateConstraints:@[
                [emptyLabel.centerXAnchor constraintEqualToAnchor:emptyCell.contentView.centerXAnchor],
                [emptyLabel.centerYAnchor constraintEqualToAnchor:emptyCell.contentView.centerYAnchor]
            ]];
            
            return emptyCell;
        }
        
        AIUAHotCardCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCardCellId forIndexPath:indexPath];
        
        NSDictionary *item;
        if (indexPath.section == 0) {
            item = self.favoritesItems[indexPath.item];
        } else {
            item = self.recentUsedItems[indexPath.item];
        }
        
        [cell configureWithTitle:item[@"title"]
                       subtitle:item[@"subtitle"]
                       iconName:item[@"icon"]];
        
        // 在收藏页面隐藏收藏按钮
        [cell setFavoriteButtonHidden:YES];
        
        return cell;
        
    } else {
        // 常规分类页面
        AIUAHotCardCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCardCellId forIndexPath:indexPath];
        
        NSDictionary *item = self.currentItems[indexPath.item];
        [cell configureWithTitle:item[@"title"]
                       subtitle:item[@"subtitle"]
                       iconName:item[@"icon"]];
        
        // 设置收藏状态
        NSString *itemId = [[AIUADataManager sharedManager] getItemId:item];
        BOOL isFavorite = [[AIUADataManager sharedManager] isFavorite:itemId];
        [cell setFavorite:isFavorite];
        [cell setFavoriteButtonHidden:NO];
        cell.delegate = self;
        
        return cell;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat totalPadding = 16 + 16 + 16;
    CGFloat width = (collectionView.bounds.size.width - totalPadding) / 2.0;
    
    if ([self isFavoriteCategorySelected] && ((indexPath.section == 0 && self.favoritesItems.count == 0) ||
                                              (indexPath.section == 1 && self.recentUsedItems.count == 0))) {
        // 空状态cell占满一行
        return CGSizeMake(collectionView.bounds.size.width - 32, 80);
    }
    
    return CGSizeMake(width, 120);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *item;
    
    if ([self isFavoriteCategorySelected]) {
        // 收藏页面
        if ((indexPath.section == 0 && self.favoritesItems.count == 0) ||
            (indexPath.section == 1 && self.recentUsedItems.count == 0)) {
            return; // 空状态cell不处理点击
        }
        
        if (indexPath.section == 0) {
            item = self.favoritesItems[indexPath.item];
        } else {
            item = self.recentUsedItems[indexPath.item];
        }
    } else {
        // 常规分类页面
        item = self.currentItems[indexPath.item];
        
        // 添加到最近使用
        [[AIUADataManager sharedManager] addRecentUsed:item];
        // 刷新最近使用数据
        [self refreshRecentUsedData];
    }
    
    [self navigateToWriting:item];
}

- (void)navigateToWriting:(NSDictionary *)item {
    AIUAWritingInputViewController *writingInputVC = [[AIUAWritingInputViewController alloc] initWithTemplateItem:item categoryId:item[@"categoryId"] apiKey:APIKEY];
    writingInputVC.hidesBottomBarWhenPushed = YES;
    // 跳转到对应的写作页面
    [self.navigationController pushViewController:writingInputVC animated:YES];
}

#pragma mark - AIUACollectionViewCellDelegate

- (void)cell:(AIUAHotCardCollectionViewCell *)cell favoriteButtonTapped:(UIButton *)button {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (indexPath && ![self isFavoriteCategorySelected]) {
        NSDictionary *item = self.currentItems[indexPath.item];
        NSString *itemId = [[AIUADataManager sharedManager] getItemId:item];
        
        if ([[AIUADataManager sharedManager] isFavorite:itemId]) {
            WeakType(self);
            WeakType(cell);
            [AIUAAlertHelper showAlertWithTitle:L(@"confirm_unfavorite")
                                        message:nil
                                  cancelBtnText:L(@"think_it_over")
                                 confirmBtnText:L(@"confirm")
                                   inController:nil
                                   cancelAction:nil confirmAction:^{
                StrongType(self);
                StrongType(cell);
                // 取消收藏
                [[AIUADataManager sharedManager] removeFavorite:itemId];
                [strongcell setFavorite:NO];
                // 刷新收藏数据
                [strongself refreshFavoritesData];
            }];
        } else {
            // 添加收藏
            [[AIUADataManager sharedManager] addFavorite:item];
            [cell setFavorite:YES];
            [AIUAMBProgressManager showText:nil withText:L(@"favorited") andSubText:nil isBottom:YES];
            // 刷新收藏数据
            [self refreshFavoritesData];
        }
    }
}

@end
