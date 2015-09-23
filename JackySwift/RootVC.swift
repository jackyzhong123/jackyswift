//
//  RootVC.swift
//  HDYAdmin
//
//  Created by haha on 15/9/1.
//  Copyright (c) 2015年 HuoDongYou. All rights reserved.
//
/*
特别说明：
在访问 tag = 700 的时候为同步用户头像



*/




import UIKit

class RootVC: UIViewController {
    
    var _doneButton:UIButton!;
    var IsNeedDoneButton:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.translucent = false  //不计Controller 高度
        self.navigationController?.navigationBar.hidden = false   //显示navigationbar
        
        RenderDetail()
        
        if (IsNeedDoneButton)
        {
            //设置需要完成按钮
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        }
        
    }
    
    //给键盘增加完成输入的按钮
    func handleKeyboardDidShow (notification:NSNotification)
    {
        let info:NSDictionary = notification.userInfo!
        var keyboardFrame:CGRect?;
        info.objectForKey(UIKeyboardFrameEndUserInfoKey)?.getValue(&keyboardFrame)
        let kbSize:CGSize = info.objectForKey(UIKeyboardFrameEndUserInfoKey)!.CGRectValue.size
        let distanceToMove:CGFloat = kbSize.height
        if (self._doneButton == nil)
        {
            _doneButton = UIButton(type: UIButtonType.ContactAdd)
        }
        let exitBtFrame:CGRect = CGRectMake(self.view.frame.size.width - 40, self.view.frame.size.height - distanceToMove, 40.0, 30.0)
        _doneButton.frame = exitBtFrame
        
        _doneButton.setImage(UIImage(named: "done"), forState: UIControlState.Normal)
        self.view.addSubview(_doneButton)
        _doneButton.hidden = false;
        self.adjustPanelsWithKeyBordHeight(distanceToMove)
        _doneButton.addTarget(self, action: "CancelBackKeyboard:", forControlEvents: UIControlEvents.TouchDown)
    }
    
    func handleKeyboardWillHide (notification:NSNotification)
    {
        if (_doneButton.hidden == false)
        {
            _doneButton.hidden = true
        }
    }
    
    func adjustPanelsWithKeyBordHeight(height:CGFloat)
    {
        if (_doneButton != nil)
        {
            let exitBtFrame:CGRect = CGRectMake(self.view.frame.size.width - 40, self.view.frame.size.height - height - 30 , 40.0, 30.0)
            _doneButton.frame = exitBtFrame
        }
        self.view.addSubview(_doneButton)
    }
    
    
    
    
    
    func CancelBackKeyboard(sender:AnyObject?)
    {
        self.view.endEditing(true)
        
    }
    
    func hideKeyboard(){
        _doneButton.hidden = true
        
        
        //_doneButton.removeFromSuperview()
        
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //绑定页面点击事件
    @IBAction func btnPageTapped(sender: AnyObject) {
        var tag:Int = 0
        let obj =  sender as? UIButton
        if (obj == nil)
        {
            let   barobj = sender as? UIBarButtonItem
            tag = barobj!.tag
        }else
        {
            tag = obj!.tag
        }
        ButtonTap(tag)
    }
    
    func ButtonTap(tag:Int)
    {
        
    }
    
    //用于初始化页面
    func RenderDetail()
    {
        
    }
    
    
    //MARK: Table数据绑定  默认绑定一行数据
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    
    //用于同步头像
    func syncUserInfo()
    {
        self.httpGetApi(AppConfig.Url_getProfile,body:nil, tag: 700)
    }
    
    
    
    
    // MARK: - 网络访问
    func generateRequest(relative:String)->NSMutableURLRequest
    {
        let oriUrl = AppConfig.SERVICE_ROOT_PATH + relative
        // var strUrl = oriUrl.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let url:NSURL = NSURL(string: oriUrl)!
        let token = AppConfig.sharedAppConfig.getAuthorizationString()
        
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
        //添加请求header
        
        request.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        request.addValue(token, forHTTPHeaderField: "Authorization")
        
        NSLog("Request URL: %@", url);
        NSLog("Request Authorization: %@", token);
        return request;
    }
    
    
    func httpPostApi(apiname:String,body:AnyObject?,tag:Int)
    {
        
        let request:NSMutableURLRequest = self.generateRequest(apiname);
        request.HTTPMethod = "POST";
        
        if (body != nil)
        {
            request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(body!, options: NSJSONWritingOptions.PrettyPrinted)
        }
        
        
        
        
        //跳过证书认证
        let securityPolicy : AFSecurityPolicy = AFSecurityPolicy(pinningMode: AFSSLPinningMode.None)
        securityPolicy.allowInvalidCertificates = true;
        //创建请求操作
        let operation:AFHTTPRequestOperation = AFHTTPRequestOperation(request: request);
        //设置安全级别
        operation.securityPolicy = securityPolicy;
        
        operation.setCompletionBlockWithSuccess({
            (operation:AFHTTPRequestOperation! , responseObject:AnyObject!) in
            
            self.handleHttpResponse(responseObject!, tag: tag)
            
            },
            failure: {
                (operation:AFHTTPRequestOperation! , error:NSError!) in
                
                let statusCode = operation.response?.statusCode
                if statusCode==401
                {
                    AppConfig.sharedAppConfig.userLogout()
                }else
                {
                    self.requestDataFailed("服务器有错误")
                }
                
                
        })
        operation.start()
    }
    
    func httpGetApi(var apiname:String,body:[String : AnyObject]?,tag:Int)
    {
        
        if (body != nil)
        {
            let parameterString = body!.stringFromHttpParameters()
            if (apiname.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "?")).count > 1)
            {
                apiname = apiname + "&" + parameterString
            }else
            {
                apiname = apiname + "?" + parameterString
            }
        }
        let request:NSMutableURLRequest = self.generateRequest(apiname);
        
        
        request.HTTPMethod = "GET";
        
        //跳过证书认证
        let securityPolicy : AFSecurityPolicy = AFSecurityPolicy(pinningMode: AFSSLPinningMode.None)
        securityPolicy.allowInvalidCertificates = true;
        //创建请求操作
        let operation:AFHTTPRequestOperation = AFHTTPRequestOperation(request: request);
        //设置安全级别
        operation.securityPolicy = securityPolicy;
        
        operation.setCompletionBlockWithSuccess({
            (operation:AFHTTPRequestOperation! , responseObject:AnyObject!) in
            
            if (tag == 700)
            {
                
                
                AppConfig.sharedAppConfig.syncUserInfo(responseObject)
                return
            }
            
            self.handleHttpResponse(responseObject, tag: tag)
            
            },
            failure: {
                (operation:AFHTTPRequestOperation! , error:NSError!) in
                
                let statusCode = operation.response?.statusCode
                if statusCode==401
                {
                    AppConfig.sharedAppConfig.userLogout()
                }else
                {
                    self.requestDataFailed("服务器有错误")
                }
                
                
                
                //
                
        })
        operation.start()
    }
    
    func uploadImage(imageData:NSData,tag:Int)
    {
        
        let request:NSMutableURLRequest = self.generateRequest(AppConfig.Url_uploadImage);
        request.HTTPMethod = "POST";
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData;//NSURLRequestReloadIgnoringLocalCacheData
        request.HTTPBodyStream = NSInputStream(data: imageData);
        request.timeoutInterval = 100
        //        request.HTTPBody = imageData;
        
        //        	fileEntity.setContentType("application/octet-stream");
        
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        //跳过证书认证
        let securityPolicy : AFSecurityPolicy = AFSecurityPolicy(pinningMode: AFSSLPinningMode.None)
        securityPolicy.allowInvalidCertificates = true;
        //创建请求操作
        let operation:AFHTTPRequestOperation = AFHTTPRequestOperation(request: request);
        //设置安全级别
        operation.securityPolicy = securityPolicy;
        
        operation.setCompletionBlockWithSuccess({
            (operation:AFHTTPRequestOperation! , responseObject:AnyObject!) in
            
            self.handleHttpResponse(responseObject, tag: tag)
            
            },
            failure: {
                (operation:AFHTTPRequestOperation! , error:NSError!) in
                
                let statusCode = operation.response?.statusCode
                if statusCode==401
                {
                    AppConfig.sharedAppConfig.userLogout()
                }else
                {
                    self.requestDataFailed("服务器有错误")
                }
                
                
        })
        operation.start()
    }
    
    func handleHttpResponse(body:AnyObject,tag:Int)
    {
        
        
        let varData = body as! NSData;
        let dataDir:NSDictionary =  (try! NSJSONSerialization.JSONObjectWithData(varData, options: NSJSONReadingOptions.AllowFragments)) as! NSDictionary
        
        if(dataDir.count == 0 || dataDir.objectForKey("Code") == nil)
        {
            self.requestDataFailed("网络异常,无效的响应.")
            return ;
        }
        let strCode = dataDir.objectForKey("Code") as! Int
        if(strCode == 10000)//code为1000正常的响应
        {
            let strDetail:AnyObject = dataDir.objectForKey("Detail")!
            self.requestDataComplete(strDetail, tag: tag)
        }
        else if(strCode == 20000)//Code为20000,token令牌失效
        {
            if(AppConfig.sharedAppConfig.isUserLogin())
            {
                AppConfig.sharedAppConfig.userLogout()
            }
            return
        }
        else
        {
            let strErr = dataDir.objectForKey("Message") as! String
            self.requestDataFailed(strErr)
        }
        
    }
    
    //网络访问成功
    func requestDataComplete(response:AnyObject,tag:Int)
    {
        
    }
    
    //网络访问失败
    func requestDataFailed(error:String)
    {
        SVProgressHUD.showErrorWithStatusWithBlack(error)
    }
    
}
