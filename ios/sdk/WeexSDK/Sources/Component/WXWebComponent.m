/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

#import "WXWebComponent.h"
#import "WXComponent_internal.h"
#import "WXUtility.h"
#import "WXHandlerFactory.h"
#import "WXURLRewriteProtocol.h"
#import "WXSDKEngine.h"

#import <JavaScriptCore/JavaScriptCore.h>

@interface WXWebView : WKWebView

@end

@implementation WXWebView

- (void)dealloc
{
    if (self) {
//        self.delegate = nil;
    }
}

@end

@interface WXWebComponent ()


@property (nonatomic, strong) WXWebView *webview;

@property (nonatomic, strong) NSString *url;

@property (nonatomic, assign) BOOL startLoadEvent;

@property (nonatomic, assign) BOOL finishLoadEvent;

@property (nonatomic, assign) BOOL failLoadEvent;

@property (nonatomic, assign) BOOL notifyEvent;

@end

@implementation WXWebComponent

WX_EXPORT_METHOD(@selector(goBack))
WX_EXPORT_METHOD(@selector(reload))
WX_EXPORT_METHOD(@selector(goForward))

NSString *const kScriptMsgHandlerName = @"weexNotify";

- (instancetype)initWithRef:(NSString *)ref type:(NSString *)type styles:(NSDictionary *)styles attributes:(NSDictionary *)attributes events:(NSArray *)events weexInstance:(WXSDKInstance *)weexInstance
{
    if (self = [super initWithRef:ref type:type styles:styles attributes:attributes events:events weexInstance:weexInstance]) {
        self.url = attributes[@"src"];
    }
    return self;
}

- (UIView *)loadView
{
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]init];
    config.allowsInlineMediaPlayback = YES;
    WKUserContentController *contentController = [[WKUserContentController alloc]init];
    [contentController addScriptMessageHandler: self name: kScriptMsgHandlerName];
    return [[WXWebView alloc] initWithFrame:CGRectZero configuration:config];
}

- (void)viewDidLoad
{
    _webview = (WXWebView *)self.view;
    _webview.navigationDelegate = self;
    [_webview setBackgroundColor:[UIColor clearColor]];
    _webview.opaque = NO;
    
    if (_url) {
        [self loadURL:_url];
    }
}

- (void)updateAttributes:(NSDictionary *)attributes
{
    if (attributes[@"src"]) {
        self.url = attributes[@"src"];
    }
}

- (void)addEvent:(NSString *)eventName
{
    if ([eventName isEqualToString:@"pagestart"]) {
        _startLoadEvent = YES;
    }
    else if ([eventName isEqualToString:@"pagefinish"]) {
        _finishLoadEvent = YES;
    }
    else if ([eventName isEqualToString:@"error"]) {
        _failLoadEvent = YES;
    }
}

- (void)setUrl:(NSString *)url
{
    NSString* newURL = [url copy];
    WX_REWRITE_URL(url, WXResourceTypeLink, self.weexInstance)
    if (!newURL) {
        return;
    }
    
    if (![newURL isEqualToString:_url]) {
        _url = newURL;
        if (_url) {
            [self loadURL:_url];
        }
    }
}

- (void)loadURL:(NSString *)url
{
    if (self.webview) {
        NSURLRequest *request =[NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        [self.webview loadRequest:request];
    }
}

- (void)reload
{
    [self.webview reload];
}

- (void)goBack
{
    if ([self.webview canGoBack]) {
        [self.webview goBack];
    }
}

- (void)goForward
{
    if ([self.webview canGoForward]) {
        [self.webview goForward];
    }
}

- (void)notifyWebview:(NSDictionary *) data
{
    NSString *json = [WXUtility JSONString:data];
    NSString *code = [NSString stringWithFormat:@"(function(){var evt=null;var data=%@;if(typeof CustomEvent==='function'){evt=new CustomEvent('notify',{detail:data})}else{evt=document.createEvent('CustomEvent');evt.initCustomEvent('notify',true,true,data)}document.dispatchEvent(evt)}())", json];
    [self.webview evaluateJavaScript:code completionHandler:^(id result, NSError *error) {
        
    }];
}

#pragma mark WKWebViewNavigation Delegate

- (void)asyncBaseInfoWithCompletionHandler: (void (^) (NSMutableDictionary<NSString *, id> *)) handler
{
    NSMutableDictionary<NSString *, id> *info = [NSMutableDictionary new];
    [info setObject:self.webview.URL.absoluteString ?: @"" forKey:@"url"];
    [info setObject:@(self.webview.canGoBack) forKey:@"canGoBack"];
    [info setObject:@(self.webview.canGoForward) forKey:@"canGoForward"];
    
    [self.webview evaluateJavaScript: @"document.title" completionHandler: ^(id result, NSError *error) {
        NSString *title = @"";
        if ([result isKindOfClass:[NSString class]] && error == nil) {
            title = (NSString *)result;
        }
        [info setObject:title forKey:@"title"];
        handler(info);
    }];
}


- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (_finishLoadEvent) {
        __weak WXWebComponent *weakSelf = self;
        [self asyncBaseInfoWithCompletionHandler:^(NSMutableDictionary<NSString *,id> * dict) {
            NSMutableDictionary<NSString *,id> *data = [NSMutableDictionary dictionaryWithDictionary:dict];
            [weakSelf fireEvent:@"pagefinish" params:data domChanges:@{@"attrs": @{@"src":weakSelf.webview.URL.absoluteString}}];
        }];
    }
}


- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (_startLoadEvent) {
        NSMutableDictionary<NSString *, id> *data = [NSMutableDictionary new];
        [data setObject:navigationAction.request.URL.absoluteString ?:@"" forKey:@"url"];
        [self fireEvent:@"pagestart" params:data];
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (_failLoadEvent) {
        __weak WXWebComponent *weakSelf = self;
        [self asyncBaseInfoWithCompletionHandler:^(NSMutableDictionary<NSString *,id> * dict) {
            NSMutableDictionary<NSString *,id> *data = [NSMutableDictionary dictionaryWithDictionary:dict];
            [data setObject:[error localizedDescription] forKey:@"errorMsg"];
            [data setObject:[NSString stringWithFormat:@"%ld", (long)error.code] forKey:@"errorCode"];
            
            NSString * urlString = error.userInfo[NSURLErrorFailingURLStringErrorKey];
            if (urlString) {
                // webview.request may not be the real error URL, must get from error.userInfo
                [data setObject:urlString forKey:@"url"];
                if (![urlString hasPrefix:@"http"]) {
                    return;
                }
            }
            [weakSelf fireEvent:@"error" params:data];
        }];
        
    }
}


- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (_failLoadEvent) {
        __weak WXWebComponent *weakSelf = self;
        [self asyncBaseInfoWithCompletionHandler:^(NSMutableDictionary<NSString *,id> * dict) {
            NSMutableDictionary<NSString *,id> *data = [NSMutableDictionary dictionaryWithDictionary:dict];
            [data setObject:[error localizedDescription] forKey:@"errorMsg"];
            [data setObject:[NSString stringWithFormat:@"%ld", (long)error.code] forKey:@"errorCode"];
            
            NSString * urlString = error.userInfo[NSURLErrorFailingURLStringErrorKey];
            if (urlString) {
                // webview.request may not be the real error URL, must get from error.userInfo
                [data setObject:urlString forKey:@"url"];
                if (![urlString hasPrefix:@"http"]) {
                    return;
                }
            }
            [weakSelf fireEvent:@"error" params:data];
        }];
        
    }
}

#pragma mark - script message handler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if (message.name != kScriptMsgHandlerName) {
        return;
    }
    NSDictionary *params = nil;
    if ([message.body isKindOfClass: [NSString class]]) {
        NSData *data = [(NSString *)message.body dataUsingEncoding:NSUTF8StringEncoding];
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if([json isKindOfClass:[NSDictionary class]]) {
            params = (NSDictionary *) json;
        }
    }
    else if ([message.body isKindOfClass:[NSDictionary class]]) {
        params = (NSDictionary *)message.body;
    }
    
    [self fireEvent:@"notify" params:params];
}


@end
