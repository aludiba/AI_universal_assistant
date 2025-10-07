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

@end

@implementation AIUAWriterViewController

- (void)setupUI {
    self.title = L(@"tab_writer");
    [self setupInputCell];
    [self setupTableView];
    [self setupGestureRecognizer];
}

- (void)setupData {
    // 从plist文件加载数据
    self.writingCategories = [[AIUADataManager sharedManager] loadWritingCategories];
    [self.tableView reloadData];
}

- (void)setupInputCell {
    self.inputCell = [[AIUAWritingInputCell alloc] init];
    __weak typeof(self) weakSelf = self;
    self.inputCell.onTextChange = ^(NSString *text) {
        // 文本变化处理
    };
    self.inputCell.onClearText = ^{
        // 清空文本处理
        
    };
    __weak typeof(self.inputCell) weakInputCell = self.inputCell;
    self.inputCell.onStartCreate = ^{
        // 开始创作处理
        [weakSelf startCreatingWithText:weakInputCell.textView.text];
    };
}

- (void)setupTableView {
    // 创建表格
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView registerClass:[AIUAWritingCategoryCell class] forCellReuseIdentifier:@"AIUAWritingCategoryCell"];
    [self.view addSubview:self.tableView];
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
        
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) return; // 输入框section不处理点击
    
    NSDictionary *sectionData = self.writingCategories[indexPath.section - 1];
    NSArray *items = sectionData[@"items"];
    NSDictionary *item = items[indexPath.row];
    // 构建完整文本
    NSString *fullText = [NSString stringWithFormat:@"%@：%@", item[@"title"], item[@"content"]];
    NSLog(@"fullText:%@", fullText);
    self.inputCell.textView.text = fullText;
    [self.inputCell updateButtonStates];
    // 滚动到顶部并弹出键盘
    [self.inputCell.textView becomeFirstResponder];
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self.inputCell.textView];
    
    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
}

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
        header.textLabel.font = [UIFont boldSystemFontOfSize:18];
        header.textLabel.textColor = [UIColor darkTextColor];
    }
}

#pragma mark - Action Methods

- (void)startCreatingWithText:(NSString *)text {
    if (text.length > 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"开始创作"
                                                                       message:@"即将根据您的内容进行创作"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
