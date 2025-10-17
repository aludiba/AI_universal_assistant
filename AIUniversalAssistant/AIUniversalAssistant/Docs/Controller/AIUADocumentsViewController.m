// AIUADocumentsViewController.m
#import "AIUADocumentsViewController.h"
#import "AIUACreateDocumentCell.h"
#import "AIUADocumentsHeaderView.h"
#import "AIUADocumentCell.h"
#import "AIUADataManager.h"
#import "AIUAAlertHelper.h"
#import "AIUAMBProgressManager.h"

@interface AIUADocumentsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *documents;
@property (nonatomic, strong) UILabel *emptyLabel;

@end

@implementation AIUADocumentsViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupData];
}

- (void)setupUI {
    // 设置导航栏标题
    self.navigationItem.title = L(@"tab_docs");
    
    // 表格视图
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = AIUA_BACK_COLOR;
    self.tableView.showsVerticalScrollIndicator = YES;
    self.tableView.estimatedRowHeight = 80;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerClass:[AIUADocumentCell class] forCellReuseIdentifier:@"AIUADocumentCell"];
    [self.tableView registerClass:[AIUACreateDocumentCell class] forCellReuseIdentifier:@"AIUACreateDocumentCell"];
    [self.tableView registerClass:[AIUADocumentsHeaderView class] forHeaderFooterViewReuseIdentifier:@"AIUADocumentsHeaderView"];
    [self.view addSubview:self.tableView];
    
    // 空状态提示
    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = L(@"no_documents");
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

- (void)setupData {
    self.documents = [[AIUADataManager sharedManager] loadAllWritings];
    self.emptyLabel.hidden = self.documents.count > 0;
    [self.tableView reloadData];
}

#pragma mark - 按钮事件

- (void)createDocumentTapped {
    // TODO:新建文档功能，这里可以跳转到写作页面
    [AIUAMBProgressManager showText:nil withText:@"新建文档功能开发中" andSubText:nil isBottom:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; // 第一个section是新建文档，第二个section是文档列表
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1; // 新建文档cell
    } else {
        return self.documents.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // 新建文档cell
        AIUACreateDocumentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AIUACreateDocumentCell" forIndexPath:indexPath];
        return cell;
    } else {
        // 文档列表cell
        AIUADocumentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AIUADocumentCell" forIndexPath:indexPath];
        NSDictionary *document = self.documents[indexPath.row];
        [cell configureWithDocument:document];
        
        // 设置更多按钮点击事件
        WeakType(self);
        cell.moreButtonTapped = ^{
            StrongType(self);
            [strongself showActionSheetForDocument:document atIndexPath:indexPath];
        };
        
        return cell;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        AIUADocumentsHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"AIUADocumentsHeaderView"];
        headerView.titleLabel.text = L(@"my_documents");
        return headerView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return 50;
    }
    return 0.1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.1;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        // 新建文档
        [self createDocumentTapped];
    } else {
        // 点击文档
        NSDictionary *document = self.documents[indexPath.row];
        // 这里可以添加点击cell查看文档详情的功能
        NSLog(@"Selected document: %@", document[@"title"]);
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return nil; // 新建文档cell不支持侧滑删除
    }
    
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:L(@"delete") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self deleteDocumentAtIndexPath:indexPath];
        completionHandler(YES);
    }];
    deleteAction.backgroundColor = AIUAUIColorRGB(239, 68, 68);
    
    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
}

#pragma mark - 操作弹窗

- (void)showActionSheetForDocument:(NSDictionary *)document atIndexPath:(NSIndexPath *)indexPath {
    NSArray *actions = @[
           @{@"title": L(@"export_document"), @"style": @(UIAlertActionStyleDefault)},
           @{@"title": L(@"copy_full_text"), @"style": @(UIAlertActionStyleDefault)},
           @{@"title": L(@"delete_document"), @"style": @(UIAlertActionStyleDestructive)}
       ];
    [AIUAAlertHelper showActionSheetWithTitle:nil
                                            message:nil
                                            actions:actions
                                      inController:self
                                      actionHandler:^(NSString *actionTitle) {
        [self handleAction:actionTitle forDocument:document atIndexPath:indexPath];
    }];
}

- (void)handleAction:(NSString *)actionTitle forDocument:(NSDictionary *)document atIndexPath:(NSIndexPath *)indexPath {
    if ([actionTitle isEqualToString:L(@"export_document")]) {
        [self exportDocument:document];
    } else if ([actionTitle isEqualToString:L(@"copy_full_text")]) {
        [self copyFullText:document];
    } else if ([actionTitle isEqualToString:L(@"delete_document")]) {
        [self deleteDocumentAtIndexPath:indexPath];
    }
}

// 增强版导出方法

- (void)exportDocument:(NSDictionary *)document {
    [[AIUADataManager sharedManager] exportDocument:document[@"title"] ?: @"" withContent:document[@"content"] ?: @""];
}


- (void)copyFullText:(NSDictionary *)document {
    NSString *content = document[@"content"] ?: @"";
    if (content.length > 0) {
        [UIPasteboard generalPasteboard].string = [NSString stringWithFormat:@"%@\n%@", document[@"title"] ?: @"", content];
        [AIUAMBProgressManager showText:nil withText:L(@"copied_to_clipboard") andSubText:nil isBottom:YES];
    } else {
        [AIUAMBProgressManager showText:nil withText:L(@"empty_document") andSubText:nil isBottom:YES];
    }
}

- (void)deleteDocumentAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *document = self.documents[indexPath.row];
    NSString *documentID = document[@"id"];
    
    if (!documentID) {
        NSLog(@"Error: Document ID is nil");
        return;
    }
    
    WeakType(self);
    [AIUAAlertHelper showAlertWithTitle:L(@"confirm_delete")
                                message:L(@"confirm_delete_document")
                          cancelBtnText:L(@"cancel")
                         confirmBtnText:L(@"delete")
                           inController:self
                           cancelAction:nil
                         confirmAction:^{
        StrongType(self);
        BOOL success = [[AIUADataManager sharedManager] deleteWritingWithID:documentID];
        if (success) {
            // 从数据源中移除
            NSMutableArray *mutableDocuments = [strongself.documents mutableCopy];
            [mutableDocuments removeObjectAtIndex:indexPath.row];
            strongself.documents = [mutableDocuments copy];
            
            // 更新UI
            [strongself.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [strongself.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
            strongself.emptyLabel.hidden = strongself.documents.count > 0;
            
            [AIUAMBProgressManager showText:nil withText:L(@"deleted_success") andSubText:nil isBottom:YES];
        } else {
            [AIUAMBProgressManager showText:nil withText:L(@"delete_failed") andSubText:nil isBottom:YES];
        }
    }];
}

@end
