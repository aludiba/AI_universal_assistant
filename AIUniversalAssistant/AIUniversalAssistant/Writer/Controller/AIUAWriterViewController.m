//
//  AIUAWriterViewController.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/3/25.
//

#import "AIUAWriterViewController.h"
#import "AIUAWritingInputCell.h"
#import "AIUAWritingCategoryCell.h"
#import "AIUADataManager.h"

@interface AIUAWriterViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) AIUAWritingInputCell *inputCell;
@property (nonatomic, strong) NSArray *writingCategories;
@property (nonatomic, assign) UIEdgeInsets originalContentInset; // 保存原始的contentInset

@end

@implementation AIUAWriterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self setupData];
    [self setupKeyboardObservers];
}

- (void)dealloc {
    // 移除键盘监听
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupUI {
    self.title = L(@"tab_writer");
    [self setupInputCell];
    [self setupGestureRecognizer];
}

- (void)setupData {
    // 从plist文件加载数据
    self.writingCategories = [[AIUADataManager sharedManager] loadWritingCategories];
    [self.tableView reloadData];
}

- (void)setupInputCell {
    self.inputCell = [[AIUAWritingInputCell alloc] init];
    self.inputCell.onTextChange = ^(NSString *text) {
        // 文本变化处理
    };
    self.inputCell.onClearText = ^{
        // 清空文本处理
    };
    self.inputCell.onStartCreate = ^{
        // 开始创作处理
        
    };
}

// 设置键盘监听
- (void)setupKeyboardObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

// 键盘升起时的处理
- (void)keyboardWillShow:(NSNotification *)notification {
    // 获取键盘信息
    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    // 计算键盘高度
    CGFloat keyboardHeight = keyboardFrame.size.height;
    
    // 更新tableView的contentInset，使其可以滚动到最底部
    UIEdgeInsets contentInset = self.tableView.contentInset;
    contentInset.bottom = keyboardHeight;
    
    [UIView animateWithDuration:animationDuration animations:^{
        self.tableView.contentInset = contentInset;
        self.tableView.scrollIndicatorInsets = contentInset;
    }];
}

// 键盘落下时的处理
- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    // 恢复原始的contentInset
    [UIView animateWithDuration:animationDuration animations:^{
        self.tableView.contentInset = self.originalContentInset;
        self.tableView.scrollIndicatorInsets = self.originalContentInset;
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

#pragma mark - 懒加载

- (UITableView *)tableView{
    if (!_tableView) {
        // 创建表格
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.backgroundColor = [UIColor clearColor];
        [_tableView registerClass:[AIUAWritingCategoryCell class] forCellReuseIdentifier:@"AIUAWritingCategoryCell"];
        [self.view addSubview:_tableView];
        // 保存原始的contentInset
        self.originalContentInset = _tableView.contentInset;
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.writingCategories.count + 1; // +1 用于输入框section
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1; // 输入框section只有1行
    } else {
        NSDictionary *sectionData = self.writingCategories[section - 1];
        NSArray *items = sectionData[@"items"];
        return items.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // 输入框Cell
        return self.inputCell;
    } else {
        // 分类项Cell
        AIUAWritingCategoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AIUAWritingCategoryCell" forIndexPath:indexPath];
        NSDictionary *sectionData = self.writingCategories[indexPath.section - 1];
        NSArray *items = sectionData[@"items"];
        NSDictionary *item = items[indexPath.row];
        [cell configureWithTitle:item[@"title"] content:item[@"content"]];
        // 设置点击回调
        WeakSelf(self);
        [cell setTapBlock:^(NSString *fullText) {
            StrongSelf(self);
            [strongself handleCategoryCellTapWithText:fullText tableView:tableView];
        }];
        return cell;
    }
}

#pragma mark - 分类项点击处理

- (void)handleCategoryCellTapWithText:(NSString *)fullText tableView:(UITableView *)tableView {
    NSLog(@"Category selected, fullText: %@", fullText);
    
    // 设置输入框文本
    self.inputCell.textView.text = fullText;
    [self.inputCell updateButtonStates];
    
    // 弹出键盘并发送文本变化通知
    [self.inputCell.textView becomeFirstResponder];
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self.inputCell.textView];
    
    // 滚动到输入框
    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return nil; // 输入框section没有标题
    } else {
        NSDictionary *sectionData = self.writingCategories[section - 1];
        return sectionData[@"title"];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 280; // 输入框Cell的高度
    } else {
        return 80; // 分类项Cell的高度
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if (section > 0 && [view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        header.textLabel.font = AIUAUIFontBold(18);
        header.textLabel.textColor = [UIColor darkTextColor];
    }
}

@end
