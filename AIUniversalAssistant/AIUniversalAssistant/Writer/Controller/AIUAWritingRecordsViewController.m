#import "AIUAWritingRecordsViewController.h"
#import "AIUAWritingRecordCell.h"
#import "AIUADataManager.h"
#import "AIUAAlertHelper.h"
#import "AIUAMBProgressManager.h"
#import "AIUADocDetailViewController.h"

@interface AIUAWritingRecordsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *writingRecords;
@property (nonatomic, strong) UILabel *emptyLabel;

@end

@implementation AIUAWritingRecordsViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadData];
}

- (void)setupUI {
    [super setupUI];
    // 设置导航栏标题
    self.navigationItem.title = L(@"writing_records");
    
    // 表格视图
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.showsVerticalScrollIndicator = YES;
    self.tableView.estimatedRowHeight = 120;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerClass:[AIUAWritingRecordCell class] forCellReuseIdentifier:@"AIUAWritingRecordCell"];
    [self.view addSubview:self.tableView];
    
    // 空状态提示
    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = L(@"no_writing_records");
    self.emptyLabel.textColor = AIUAUIColorRGB(156, 163, 175);
    self.emptyLabel.font = AIUAUIFontSystem(16);
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.hidden = YES;
    [self.view addSubview:self.emptyLabel];
    
    [self setupConstraints];
}

- (void)setupConstraints {
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // 表格视图
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        
        // 空状态标签
        [self.emptyLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.emptyLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.emptyLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.emptyLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20]
    ]];
}

- (void)loadData {
    self.writingRecords = [[AIUADataManager sharedManager] loadWritingsByType:self.type];
    self.emptyLabel.hidden = self.writingRecords.count > 0;
    [self updateNavigationTitle];
    [self.tableView reloadData];
}

#pragma mark - 提取主题作为标题
- (void)updateNavigationTitle {
    if (self.writingRecords.count == 0 || !self.type || [self.type isEqualToString:@""]) {
        // 如果没有记录，使用默认标题
        self.navigationItem.title = L(@"writing_records");
        return;
    }
    
    // 从第一条记录的prompt中提取主题
    NSDictionary *firstWriting = self.writingRecords.firstObject;
    NSString *prompt = firstWriting[@"prompt"] ?: @"";
    NSString *theme = [self extractThemeFromPrompt:prompt];
    
    if (theme.length > 0) {
        self.navigationItem.title = theme;
    } else {
        // 如果没有提取到主题，使用默认标题
        self.navigationItem.title = L(@"writing_records");
    }
}

- (NSString *)extractThemeFromPrompt:(NSString *)prompt {
    return [[AIUADataManager sharedManager] extractThemeFromPrompt:prompt];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.writingRecords.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AIUAWritingRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AIUAWritingRecordCell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    NSDictionary *writing = self.writingRecords[indexPath.row];
    [cell configureWithWriting:writing];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *writing = self.writingRecords[indexPath.row];
    // 这里可以添加点击后的操作，比如查看详情等
    NSLog(@"Selected writing: %@", writing[@"title"]);
    
    AIUADocDetailViewController *docDetailVC = [[AIUADocDetailViewController alloc] initWithWritingItem:writing];
    docDetailVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:docDetailVC animated:YES];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:L(@"delete") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self deleteWritingAtIndexPath:indexPath];
        completionHandler(YES);
    }];
    deleteAction.backgroundColor = AIUAUIColorRGB(239, 68, 68);
    
    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
}

- (void)deleteWritingAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *writing = self.writingRecords[indexPath.row];
    NSString *writingID = writing[@"id"];
    
    if (!writingID) {
        NSLog(@"Error: Writing ID is nil");
        return;
    }
    
    WeakType(self);
    [AIUAAlertHelper showAlertWithTitle:L(@"confirm_delete")
                                message:L(@"delete_writing_confirm")
                          cancelBtnText:L(@"cancel")
                         confirmBtnText:L(@"delete")
                           inController:self
                           cancelAction:nil
                         confirmAction:^{
        StrongType(self);
        BOOL success = [[AIUADataManager sharedManager] deleteWritingWithID:writingID];
        if (success) {
            // 从数据源中移除
            NSMutableArray *mutableRecords = [strongself.writingRecords mutableCopy];
            [mutableRecords removeObjectAtIndex:indexPath.row];
            strongself.writingRecords = [mutableRecords copy];
            
            // 更新UI
            [strongself.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            strongself.emptyLabel.hidden = strongself.writingRecords.count > 0;
            
            [AIUAMBProgressManager showText:nil withText:L(@"deleted_success") andSubText:nil isBottom:YES];
        } else {
            [AIUAMBProgressManager showText:nil withText:L(@"delete_failed") andSubText:nil isBottom:YES];
        }
    }];
}

@end
