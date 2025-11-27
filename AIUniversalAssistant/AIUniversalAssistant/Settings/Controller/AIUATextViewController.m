//
//  AIUATextViewController.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 2025/11/24.
//

#import "AIUATextViewController.h"
#import <Masonry/Masonry.h>
#import <WebKit/WebKit.h>

@interface AIUATextViewController ()

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) WKWebView *webView;

@end

@implementation AIUATextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 如果指定了HTML文件名，优先使用WebView加载HTML
    if (self.htmlFileName && self.htmlFileName.length > 0) {
        [self loadHTMLFile];
    } else if (self.text && self.text.length > 0) {
        // 否则使用TextView显示文本
        self.textView.text = self.text;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.textView setContentOffset:CGPointZero animated:NO];
        });
    }
}

- (void)setText:(NSString *)text {
    _text = text;
    if (!self.htmlFileName || self.htmlFileName.length == 0) {
    self.textView.text = text;
    // 确保文本视图滚动到顶部
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.textView setContentOffset:CGPointZero animated:NO];
    });
    }
}

- (void)setHtmlFileName:(NSString *)htmlFileName {
    _htmlFileName = htmlFileName;
    if (htmlFileName && htmlFileName.length > 0) {
        [self loadHTMLFile];
    }
}

- (void)loadHTMLFile {
    if (!self.htmlFileName || self.htmlFileName.length == 0) {
        return;
    }
    
    // 隐藏TextView，显示WebView
    self.textView.hidden = YES;
    self.webView.hidden = NO;
    
    // 获取HTML文件路径
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:[self.htmlFileName stringByDeletingPathExtension] ofType:@"html"];
    
    if (htmlPath) {
        NSURL *htmlURL = [NSURL fileURLWithPath:htmlPath];
        [self.webView loadFileURL:htmlURL allowingReadAccessToURL:[htmlURL URLByDeletingLastPathComponent]];
    } else {
        // 如果找不到文件，显示错误信息
        NSString *errorHTML = [NSString stringWithFormat:@"<html><body style='font-family: -apple-system; padding: 20px;'><h2>文件未找到</h2><p>无法加载文件：%@</p></body></html>", self.htmlFileName];
        [self.webView loadHTMLString:errorHTML baseURL:nil];
    }
}

- (UITextView *)textView {
    if (!_textView) {
        UITextView *textView = [[UITextView alloc] init];
        textView.font = AIUAUIFontSystem(14);
        textView.textColor = AIUAUIColorRGB(75, 85, 99);
        textView.editable = NO;
        textView.textContainerInset = UIEdgeInsetsMake(16, 16, 16, 16);
        textView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
        [self.view addSubview:textView];
        
        [textView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            make.right.bottom.left.equalTo(self.view);
        }];
        _textView = textView;
    }
    return _textView;
}

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        webView.backgroundColor = [UIColor whiteColor];
        webView.opaque = NO;
        [self.view addSubview:webView];
        
        [webView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            make.right.bottom.left.equalTo(self.view);
        }];
        
        _webView = webView;
    }
    return _webView;
}

@end
