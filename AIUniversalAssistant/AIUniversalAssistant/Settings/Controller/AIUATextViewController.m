//
//  AIUATextViewController.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 2025/11/24.
//

#import "AIUATextViewController.h"
#import <Masonry/Masonry.h>
#import <WebKit/WebKit.h>
#import <SafariServices/SafariServices.h>

@interface AIUATextViewController () <WKNavigationDelegate>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) WKWebView *webView;

@end

@implementation AIUATextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 如果指定了URL，优先使用WebView加载远程页面
    if (self.urlString && self.urlString.length > 0) {
        [self loadURLString];
    } else if (self.htmlFileName && self.htmlFileName.length > 0) {
        // 如果指定了HTML文件名，使用WebView加载HTML
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
    if ((!self.htmlFileName || self.htmlFileName.length == 0) && (!self.urlString || self.urlString.length == 0)) {
        self.textView.text = text;
        // 确保文本视图滚动到顶部
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.textView setContentOffset:CGPointZero animated:NO];
        });
    }
}

- (void)setHtmlFileName:(NSString *)htmlFileName {
    _htmlFileName = htmlFileName;
    if (htmlFileName && htmlFileName.length > 0 && (!self.urlString || self.urlString.length == 0)) {
        [self loadHTMLFile];
    }
}

- (void)setUrlString:(NSString *)urlString {
    _urlString = urlString;
    if (urlString && urlString.length > 0) {
        [self loadURLString];
    }
}

- (void)loadURLString {
    if (!self.urlString || self.urlString.length == 0) {
        return;
    }
    
    NSURL *url = [NSURL URLWithString:self.urlString];
    if (!url) {
        return;
    }
    
    // 隐藏TextView，显示WebView
    self.textView.hidden = YES;
    self.webView.hidden = NO;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (void)loadHTMLFile {
    if (!self.htmlFileName || self.htmlFileName.length == 0) {
        return;
    }
    
    // 隐藏TextView，显示WebView
    self.textView.hidden = YES;
    self.webView.hidden = NO;
    
    // 获取HTML文件路径，根据系统语言手动查找对应的本地化文件
    NSString *htmlPath = [self localizedHTMLPathForFileName:self.htmlFileName];
    
    if (htmlPath && [[NSFileManager defaultManager] fileExistsAtPath:htmlPath]) {
        // 记录加载的文件路径（用于调试，可以看到加载的是哪个语言版本）
        NSLog(@"加载HTML文件: %@", htmlPath);
        NSURL *htmlURL = [NSURL fileURLWithPath:htmlPath];
        [self.webView loadFileURL:htmlURL allowingReadAccessToURL:[htmlURL URLByDeletingLastPathComponent]];
    } else {
        // 如果找不到文件，显示错误信息
        NSArray *preferredLanguages = [NSLocale preferredLanguages];
        NSString *currentLanguage = [preferredLanguages firstObject];
        NSLog(@"未找到本地化HTML文件: %@，当前系统语言: %@", self.htmlFileName, currentLanguage);
        
        NSString *errorMessage = [NSString stringWithFormat:@"无法加载文件：%@", self.htmlFileName];
        NSString *errorHTML = [NSString stringWithFormat:@"<html><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1.0'></head><body style='font-family: -apple-system; padding: 20px;'><h2>文件未找到</h2><p>%@</p></body></html>", errorMessage];
        [self.webView loadHTMLString:errorHTML baseURL:nil];
    }
}

// 根据系统语言获取本地化的HTML文件路径
- (NSString *)localizedHTMLPathForFileName:(NSString *)fileName {
    if (!fileName || fileName.length == 0) {
        return nil;
    }
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSArray *preferredLanguages = [NSLocale preferredLanguages];
    
    // 遍历系统首选语言列表，查找对应的本地化文件
    for (NSString *languageCode in preferredLanguages) {
        // 标准化语言代码（例如：zh-Hans, en, ja）
        NSString *normalizedLanguage = [self normalizeLanguageCode:languageCode];
        
        // 方法1：使用pathForResource:ofType:inDirectory:（指定.lproj目录）
        // 这是最可靠的方法，因为Bundle会自动处理资源路径
        NSString *fileNameWithoutExt = [fileName stringByDeletingPathExtension];
        NSString *fileExt = [fileName pathExtension];
        NSString *lprojDir = [NSString stringWithFormat:@"%@.lproj", normalizedLanguage];
        NSString *path = [mainBundle pathForResource:fileNameWithoutExt
                                               ofType:fileExt
                                          inDirectory:lprojDir];
        if (path && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSLog(@"找到本地化HTML文件 [%@]: %@", normalizedLanguage, path);
            return path;
        }
        
        // 方法2：直接构建.lproj目录路径（备用方法）
        NSString *resourcePath = [mainBundle resourcePath];
        if (resourcePath) {
            NSString *lprojPath = [resourcePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.lproj", normalizedLanguage]];
            NSString *filePath = [lprojPath stringByAppendingPathComponent:fileName];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                NSLog(@"找到本地化HTML文件 [%@]: %@", normalizedLanguage, filePath);
                return filePath;
            }
        }
    }
    
    // 如果都找不到，尝试使用pathForResource:ofType:（可能会找到根目录下的文件或自动本地化）
    NSString *fileNameWithoutExt = [fileName stringByDeletingPathExtension];
    NSString *fileExt = [fileName pathExtension];
    NSString *path = [mainBundle pathForResource:fileNameWithoutExt ofType:fileExt];
    
    if (path) {
        NSLog(@"使用回退路径加载HTML文件: %@", path);
    }
    
    return path;
}

// 标准化语言代码
- (NSString *)normalizeLanguageCode:(NSString *)languageCode {
    if (!languageCode || languageCode.length == 0) {
        return @"zh-Hans"; // 默认返回中文
    }
    
    // 处理语言代码，例如：zh-Hans-CN -> zh-Hans, en-US -> en
    NSArray *components = [languageCode componentsSeparatedByString:@"-"];
    if (components.count >= 2) {
        NSString *language = components[0];
        NSString *script = components[1];
        
        // 中文简体
        if ([language isEqualToString:@"zh"] && ([script isEqualToString:@"Hans"] || [script isEqualToString:@"CN"])) {
            return @"zh-Hans";
        }
        // 中文繁体
        if ([language isEqualToString:@"zh"] && ([script isEqualToString:@"Hant"] || [script isEqualToString:@"TW"] || [script isEqualToString:@"HK"])) {
            return @"zh-Hant";
        }
        // 英文
        if ([language isEqualToString:@"en"]) {
            return @"en";
        }
        // 日文
        if ([language isEqualToString:@"ja"]) {
            return @"ja";
        }
        
        // 其他情况，返回 language-script
        return [NSString stringWithFormat:@"%@-%@", language, script];
    }
    
    // 单个语言代码
    if ([languageCode isEqualToString:@"zh"]) {
        return @"zh-Hans"; // 默认简体中文
    }
    
    return languageCode;
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
        webView.backgroundColor = AIUA_BACK_COLOR; // 使用系统背景色，自动适配暗黑模式
        webView.opaque = NO;
        webView.navigationDelegate = self;
        [self.view addSubview:webView];
        
        [webView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            make.right.bottom.left.equalTo(self.view);
        }];
        
        _webView = webView;
    }
    return _webView;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    
    // 允许本地文件加载和初始页面加载
    if ([url isFileURL] || navigationAction.navigationType == WKNavigationTypeLinkActivated == NO) {
        // 对于非链接点击的导航（如初始加载），直接允许
        if (navigationAction.navigationType != WKNavigationTypeLinkActivated) {
            decisionHandler(WKNavigationActionPolicyAllow);
            return;
        }
    }
    
    // 用户点击了链接
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        NSString *scheme = url.scheme.lowercaseString;
        // http/https 外部链接，用应用内 Safari 控制器打开（不跳出应用）
        if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
            SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url];
            [self presentViewController:safariVC animated:YES completion:nil];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
