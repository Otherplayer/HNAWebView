//
//  HNATripsController.swift
//  HNABim
//
//  Created by __无邪_ on 2017/7/4.
//  Copyright © 2017年 __无邪_. All rights reserved.
//

import UIKit
import WebKit

class HNATripsController: UIViewController ,WKNavigationDelegate,WKUIDelegate,WKScriptMessageHandler{

    let kJSCallbackIdentifier = "jsCallback";
    
    
    var urlStr = "https://www.baidu.com"            // url
    var webview : WKWebView!
    
    
    //MARK: - Life circle
    override func viewDidLoad() {
        super.viewDidLoad()

        webviewConfig()
        getVersion { (version) in
            self.urlStr = "\(self.urlStr)?version=\(version)"
            self.loadStart()
        }
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    deinit {
        self.webview.configuration.userContentController.removeAllUserScripts()
    }
    
    
    //MARK: fun
    func loadStart() {
        let url = URL(string: self.urlStr)
        let request = URLRequest.init(url: url!)
        self.webview .load(request)
    }
    
    
    //MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
//        showLoadingHUD(nil, hide: 20)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        clearHUD()
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
//        showLoadingHUD(error.localizedDescription, hide: 2)
    }
    
    
    //MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // selector引用的方法必须对ObjC运行时是可见的
        if message.name == kJSCallbackIdentifier {
            if let dic = message.body as? NSDictionary {
                var funcName = "jsCallback_" +  ((dic["f"] ?? dic["function"]) as! String).lowercased()
                let parameter = dic["p"] ?? dic["parameter"]
                if (parameter != nil) {
                    funcName = funcName + ":"
                }
                let methods = Selector(funcName);
                
                if self.responds(to: methods)  {
                    self.perform(methods, with: parameter)
                }else{
                    print("方法：\(methods)未实现")
                }
            }
        }
    }
    
    //MARK: - Callback-of-JS
    @objc private func jsCallback_return() {
        self.navigationController?.popViewController(animated: true);
    }
    @objc private func jsCallback_refresh() {
        self.webview.reload()
    }
    @objc private func jsCallback_goback() {
        if self.webview.canGoBack {
            self.webview.goBack()
        }
    }
    @objc private func jsCallback_goforward() {
        if self.webview.canGoForward {
            self.webview.goForward()
        }
    }
    @objc private func jsCallbackObjectiveC(_ body:Any) {
        //    if ([body isKindOfClass:[NSDictionary class]]) {
        //    NSDictionary *dict = (NSDictionary *)body;
        //    // oc调用js代码
        //    NSString *jsStr = [NSString stringWithFormat:@"ocCallJS('%@')", [dict objectForKey:@"data"]];
        //    [self.webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable data, NSError * _Nullable error) {
        //    if (error) {
        //    NSLog(@"错误:%@", error.localizedDescription);
        //    }
        //    }];
        //    }
    }
    
    
    //MARK: - Private methods
    func getVersion(completionHandler: @escaping (_ version : String) -> Swift.Void) {
        let task = URLSession.shared.dataTask(with: URL(string: "http://113.200.50.42:18100/travelmate/api/v1/param/get/version")!) {
            (Data, URLResponse, Error) in
            
            DispatchQueue.main.async {
                if let json = try? JSONSerialization.jsonObject(with: Data!, options: .allowFragments) as! [String : AnyObject] {
                    if JSONSerialization.isValidJSONObject(json) {
                        let v = json["t"]!["param_value"]!! as! String
                        completionHandler(v)
                    }else {
                        let v = "\(Date().timeIntervalSince1970)"
                        completionHandler(v)
                    }
                }else {
                    let v = "\(Date().timeIntervalSince1970)"
                    completionHandler(v)
                }
            }
        }
        task.resume()
    }
    func cookieValueInfo(cookies : [String : String]) -> String {
        var result = ""
        for (key,value) in cookies {
            result.append("document.cookie = '\(key)=\(value)';")
        }
        return result
    }
    
    //MARK: - Config
    func webviewConfig() {
        // cookie
        let id = "<>"
        let name = "<中国>".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        let avatar = "<>"
        let cookieValue = cookieValueInfo(cookies: ["id":id,"name":name!,"avatar":avatar])
        
        // js配置
        let userContentController = WKUserContentController()
        userContentController.add(self, name: kJSCallbackIdentifier)
        let cookieScript = WKUserScript(source: cookieValue, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(cookieScript)
        
        // WKWebView的配置
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        
        self.webview = WKWebView(frame: self.view.bounds, configuration: configuration)
        self.webview.uiDelegate = self
        self.webview.navigationDelegate = self
        self.view.addSubview(self.webview)
    }

}
