//
//  M12306Document.m
//  My12306
//
//  Created by 范 俊伟 on 13-7-11.
//  Copyright (c) 2013年 fjw. All rights reserved.
//

#import "M12306Document.h"
#import "M12306Base32.h"
#import "JSONKit.h"

@implementation M12306Document
{
    NSDictionary *_savedDate;
}
- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}
- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"M12306Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    
    [self myinit];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return YES;
}
-(void)myinit
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    NSURL *url = [NSURL URLWithString:HOST_URL];
    if (url) {
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url];
        for (int i = 0; i < [cookies count]; i++) {
            NSHTTPCookie *cookie = (NSHTTPCookie *)[cookies objectAtIndex:i];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
            
        }
    }
    [self initSeat];
    NSTimeInterval timei = 19*24*60*60;
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:timei];
    self.dtpDate.dateValue=date;
    NSString * username=[self.savedDate objectForKey:@"username"];
    NSString * password=[self.savedDate objectForKey:@"password"];
    if(username!=nil && password!=nil)
    {
        self.txtUsername.stringValue=username;
        self.txtPassword.stringValue =password;
    }
    NSString *trainnameregx=[self.savedDate objectForKey:@"trainnameregx"];
    if(trainnameregx!=nil)
    {
        self.txtTrainNameRegx.stringValue=trainnameregx;
    }
    
    [(M12306TextField *) self.txtImgcode setTextChangeAction:@selector(txtImgLoginCodeAction) toTarget:self];
    [self.txtCommitCode setTextChangeAction:@selector(txtCommitCodeTextChageAction) toTarget:self];
    
    
    NSString  * html=[self getResFile:@"login.html"];
    [self.webview.mainFrame loadHTMLString:html baseURL:nil];
    
    [NSThread detachNewThreadSelector:@selector(myinitThread) toTarget:self withObject:nil];
}
-(void) myinitThread
{
    
    [self addLog:@"初始化..."];
    [self getStations];
    [self getLoginImgCode];
    [self addLog:@"初始化完成。"];
    
}

-(void) addLogLock:(NSString *)log
{
    if(log!=nil && self.txtLogParent)
    {
        NSDate  * now =[NSDate date];
        NSDateFormatter * formate=[[NSDateFormatter alloc]init];
        [formate setDateFormat:@"HH:mm:ss"];
        NSString * str = [formate stringFromDate:now];
        str = [str stringByAppendingFormat:@" %@",log];
        
        self.txtLog.string=[self.txtLog.string stringByAppendingFormat:@"%@\n",str];
        
        NSRange range = NSMakeRange ([[self.txtLog string] length], 0);
        
        [self.txtLog scrollRangeToVisible: range];
        
    }
}
-(void) addLog:(NSString *)log
{
    [self performSelectorOnMainThread:@selector(addLogLock:) withObject:log waitUntilDone:YES];
}
- (void)setLoginImgCode:(NSImage *)image
{
    [self.imgLoginCode setImage:image];
    if(self.txtUsername.stringValue && ![self.txtUsername.stringValue isEqualToString:@""] && self.txtPassword.stringValue && ![self.txtPassword.stringValue isEqualToString:@""])
    {
        self.txtImgcode.stringValue=@"";
        [self.txtImgcode becomeFirstResponder];
    }
}
-(void) getLoginImgCodeLock
{
    
    self.loginKey=nil;
    NSImage *image=nil;
    while (!image) {
        image = [self getImageWithUrl:HOST_URL@"/otn/passcodeNew/getPassCodeNew?module=login&rand=sjrand" refUrl:HOST_URL@"/otn/login/init"];
        if(!image)
        {
            [self addLog:@"获取验证码错误,重新获取!"];
            sleep(3);
        }
    }
    [self performSelectorOnMainThread:@selector(setLoginImgCode:) withObject:image waitUntilDone:YES];
    
}
-(void) getLoginImgCode
{
    [NSThread detachNewThreadSelector:@selector(getLoginImgCodeLock) toTarget:self withObject:nil];
    
}
- (NSImage *) getImageWithUrl:(NSString *)url refUrl:(NSString *)refUrl
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url ] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:5];
    
    [request setValue:refUrl forHTTPHeaderField:@"Referer"];
    NSData * data=[M12306URLConnection sendSynchronousRequest:request];
    NSImage* image = [[NSImage alloc]initWithData:data];
    
    return image;
}


- (IBAction)btnLoginClick:(id)sender {
    [self login];
}

- (void)txtImgLoginCodeAction{
    if([self.txtImgcode.stringValue isEqualToString:@" "])
    {
        [self getLoginImgCode];
    }
    else if([self.txtImgcode.stringValue length]==4)
    {
        [self login];
    }
}
- (void)delayLoginLock
{
    
    sleep(2);
    [self loginLock];
}
- (void)delayLogin
{
    [NSThread detachNewThreadSelector:@selector(delayLoginLock) toTarget:self withObject:nil];
}
- (void)reLoginMainThread
{
    [self addLog:@"已不在线"];
    self.lblLoginMsg.stringValue=@"【未登录】";
    self.isLogin=NO;
    [self login];
}
- (void)reLogin
{
    [self performSelectorOnMainThread:@selector(reLoginMainThread) withObject:nil waitUntilDone:YES];
}
- (void)login
{
    NSMutableArray *sd = [self.savedDate mutableCopy];
    [sd setValue:self.txtUsername.stringValue forKey:@"username"];
    [sd setValue:self.txtPassword.stringValue forKey:@"password"];
    self.savedDate=(NSDictionary *)sd;
    [NSThread detachNewThreadSelector:@selector(loginLock) toTarget:self withObject:nil];
}
- (void)loginLock
{
    [self addLog:@"开始登录"];
    M12306Form * form =[[M12306Form alloc]initWithActionURL:HOST_URL@"/otn/login/loginAysnSuggest"];
    [self setYuanshiForFile:@"loginform" forFrom:form];
    
    [form setTagValue:self.txtUsername.stringValue forKey:@"loginUserDTO.user_name"];
    [form setTagValue:self.txtPassword.stringValue forKey:@"userDTO.password"];
    [form setTagValue:self.txtImgcode.stringValue forKey:@"randCode"];
    
    [form setTagValue:self.loginValue  forKey:self.loginKey];
    
    //form.referer=HOST_URL@"/otsweb/loginAction.do?method=init";
    NSString * outs= [form post];
    [self performSelectorOnMainThread:@selector(loginDidResult:) withObject:outs waitUntilDone:YES];
}
- (void)loginDidResult:(NSString *)strresult
{
    NSLog(@"%@",strresult);
    BOOL error = NO;
    NSString* errormsg =nil;
    id jsonresult=[strresult objectFromJSONString];
    NSDictionary *parData = [jsonresult objectForKey:@"data"];
    NSArray *parMessages = [jsonresult objectForKey:@"messages"];
    NSNumber *parStatus = [jsonresult objectForKey:@"status"];
    if(parStatus.boolValue)
    {
        if(parData!=nil && [parData count]>0)
        {
            NSString *parLoginCheck=[parData objectForKey:@"loginCheck"];
            if(parLoginCheck!=nil  && [parLoginCheck isEqualToString:@"Y"])
            {
                //登录成功
                [self addLog:@"登录成功"];
                self.isLogin = YES;
                NSString *str = [self getText:HOST_URL@"/otn/index/initMy12306" IsPost:NO];
                
                NSMutableArray * mathcStrs = [NSMutableArray array];
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"user_name='(.*?)'" options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators error:nil];
                
                [regex enumerateMatchesInString:str options:0 range:NSMakeRange(0, str.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                    if([result numberOfRanges]>0)
                    {
                        [mathcStrs addObject: [str substringWithRange:[result rangeAtIndex:1]]];
                    }
                    
                }];
                NSString *name = [mathcStrs objectAtIndex:0];
                NSString *tem = [NSString stringWithFormat:@"[\"%@\"]",name];
                NSArray *aa= [tem objectFromJSONString];
                name = [aa objectAtIndex:0];
                self.lblLoginMsg.stringValue=name;
                [self getPassenger];
            }
        }
        else
        {
            NSString *allMessages = @"";
            for (NSString * m in parMessages) {
                allMessages=[allMessages stringByAppendingFormat:@"%@ ",m];
            }
            if ([allMessages rangeOfString:@"验证码"].location!=NSNotFound)
            {
                [self getLoginImgCode];
            }
            else if ([allMessages rangeOfString:@"密码"].location!=NSNotFound)
            {
                [self.txtPassword becomeFirstResponder];
            }
            else if ([allMessages rangeOfString:@"登录名不存在"].location!=NSNotFound)
            {
                self.txtPassword.stringValue=@"";
                self.txtUsername.stringValue=@"";
                [self.txtUsername becomeFirstResponder];
            }
            else if ([allMessages rangeOfString:@"系统维护"].location!=NSNotFound)
            {
                
            }
            
            error=YES;
            errormsg=allMessages;
            
            [self addLog:errormsg];
            self.lblLoginMsg.stringValue=errormsg;
        }
    }
    else
    {
        NSLog(@"%@",strresult);
        [self addLog:@"登录失败，重新登录"];
        [self delayLogin];
    }
}
-(void)setPassenger
{
    self.tablePassenger.data=self.allPassengers;
    NSArray * array =[self.savedDate objectForKey:@"selectedpassenger"];
    [self.tablePassenger initSelected:array];
    [self.tablePassenger reloadData];
    
    [self addLog:@"联系人加载完成。"];
}

-(void)getPassengerLock
{
    [self addLog:@"初始化常用联系人..."];
    NSString*  tem1 = nil;
    NSDictionary * json;
    while (true)
    {
        tem1 = [self getText:HOST_URL@"/otn/confirmPassenger/getPassengerDTOs" IsPost:YES];
        if (tem1 == nil)
        {
            [self addLog:@"初始化常用联系人错误，稍候重试"];
            usleep(500*1000);
            continue;
        }
        json = [tem1 objectFromJSONString];
        if(!json)
        {
            [self addLog:@"初始化常用联系人错误，稍候重试"];
            usleep(500*1000);
            continue;
        }
        
        NSNumber * status= [json objectForKey:@"status"];
        if(!status.boolValue)
        {
            [self addLog:@"初始化常用联系人错误，稍候重试"];
            usleep(500*1000);
            continue;
        }
        break;
    }
    
    
    NSArray *jsonPassengersArray=[[json objectForKey:@"data"]objectForKey:@"normal_passengers"];
    NSMutableArray * tempassenger=[NSMutableArray array];
    for (int i=0; i<[jsonPassengersArray count ]; i++) {
        NSDictionary *p=[jsonPassengersArray objectAtIndex:i];
        M12306passengerTicketItem * item =[[M12306passengerTicketItem alloc]init];
        item.Cardno=[p objectForKey:@"passenger_id_no"];
        item.Cardtype=[p objectForKey:@"passenger_id_type_code"];
        item.Mobileno=[p objectForKey:@"mobile_no"];
        item.Name=[p objectForKey:@"passenger_name"];
        item.Ticket=[p objectForKey:@"passenger_type"];
        [tempassenger addObject:item];
    }
    self.allPassengers=[tempassenger copy];
    [self performSelectorOnMainThread:@selector(setPassenger) withObject:nil waitUntilDone:YES];
}
- (void)getPassenger
{
    [NSThread detachNewThreadSelector:@selector(getPassengerLock) toTarget:self withObject:nil];
}

- (void)setYuanshiForFile:(NSString *)filename forFrom:(M12306Form *)form
{
    NSString *resPath= [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:filename];
    NSString * value = [NSString stringWithContentsOfFile:resPath encoding:NSUTF8StringEncoding error:nil];
    NSArray * lines = [value componentsSeparatedByString:@"\n"];
    for (int i=0; i<[lines count]; i++) {
        NSArray * kv =[[lines objectAtIndex:i]componentsSeparatedByString:@"="];
        if(kv.count==2)
        {
            [form setTagValue:[kv objectAtIndex:1] forKey:[kv objectAtIndex:0]];
        }
    }
    
}

- (NSData *)getData:(NSString *)url IsPost:(BOOL)isPost
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url ] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:5];
    
    [request setValue:url forHTTPHeaderField:@"Referer"];
    if(isPost)
    {
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[NSMutableData dataWithLength:0]];
    }
    else
    {
        [request setHTTPMethod:@"GET"];
    }
    NSData * data=[M12306URLConnection sendSynchronousRequest:request];
    return data;
}
- (NSString *)getText:(NSString *)url IsPost:(BOOL)isPost
{
    NSData *data = [self getData:url IsPost:isPost];
    return  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
- (id)getJson:(NSString *)url IsPost:(BOOL)isPost
{
    NSData *data = [self getData:url IsPost:isPost];
    return  [data objectFromJSONData];
}
- (void)initSeat
{
    NSArray * seatDataValue=[NSArray arrayWithObjects:  @"二等座",@"一等座",@"商务座",@"特等座",@"高级软卧",@"软卧",@"硬卧",@"软座",@"硬座",@"无座", nil];
    self.seatData = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects: @"O",@"M",@"9",@"P",@"6",@"4",@"3",@"2",@"1",@"empty", nil] forKeys:seatDataValue];
    [self.popupSeat addItemsWithTitles:seatDataValue];
    NSString * index=[self.savedDate objectForKey:@"seatindex"];
    if(index!=nil)
    {
        [self.popupSeat selectItemAtIndex:[index intValue]];
    }
    
}
- (IBAction)popupSeat:(id)sender {
    //NSString * set=[self.popupSeat selectedItem].title;
    //NSString * value=[self.seatData objectForKey:set];
}
-(void)doStationsResult
{
    self.cbxFromStation.data=self.stations;
    self.cbxToStation.data=self.stations;
    [self.cbxToStation reloadData];
    [self.cbxFromStation reloadData];
    NSString * fromstationindex = [self.savedDate objectForKey:@"fromstationindex"];
    NSString *tostationindex = [self.savedDate objectForKey:@"tostationindex"];
    
    if(fromstationindex!=nil && tostationindex!=nil)
    {
        [self.cbxFromStation selectItemAtIndex:[fromstationindex intValue]];
        [self.cbxToStation selectItemAtIndex:[tostationindex intValue]];
    }
}
- (void)getStations
{
    NSString * str;
    while (str==nil) {
        str=[self getText:HOST_URL@"/otn/resources/merged/queryLeftTicket_end_js.js?scriptVersion=1.01" IsPost:NO];
        if (str == nil)
        {
            [self addLog:@"获取车站信息错误，稍候重试"];
            usleep(500*1000);
        }
    }
    
    NSMutableArray * mathcStrs = [NSMutableArray array];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"var station_names=\"(.*?)\"" options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators error:nil];
    
    [regex enumerateMatchesInString:str options:0 range:NSMakeRange(0, str.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        if([result numberOfRanges]>0)
        {
            [mathcStrs addObject: [str substringWithRange:[result rangeAtIndex:1]]];
        }
        
    }];
    NSString  *res = [mathcStrs objectAtIndex:0];
    NSArray * buffer = [res componentsSeparatedByString:@"|"];
    NSMutableArray *stations=[[NSMutableArray alloc]initWithCapacity:2166];
    for (int i=0; i<buffer.count-5; i+=5) {
        NSString *display=[buffer objectAtIndex:i+1];
        NSString *value=[buffer objectAtIndex:i+2];
        NSString *pinyin=[buffer objectAtIndex:i+3];
        NSDictionary* item =[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:display,value,pinyin, nil] forKeys:[NSArray arrayWithObjects:@"display",@"value",@"pinyin", nil]];
        [stations addObject:item];
    }
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"pinyin" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sorter count:1];
    self.stations = [stations sortedArrayUsingDescriptors:sortDescriptors];
    [self performSelectorOnMainThread:@selector(doStationsResult) withObject:nil waitUntilDone:YES];
}

- (IBAction)btnSearchClick:(id)sender {
    if([self.cbxFromStation indexOfSelectedItem]<0)
    {
        NSAlert * alert=[[NSAlert alloc]init];
        [alert addButtonWithTitle:@"确定"];
        [alert setMessageText:@"未选择出发站"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
    }
    else if([self.cbxToStation indexOfSelectedItem]<0)
    {
        NSAlert * alert=[[NSAlert alloc]init];
        [alert addButtonWithTitle:@"确定"];
        [alert setMessageText:@"未选择到达站"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
    }
    else
    {
        NSMutableArray *sd = [self.savedDate mutableCopy];
        [sd setValue:[NSString stringWithFormat:@"%ld",self.cbxFromStation.indexOfSelectedItem] forKey:@"fromstationindex"];
        [sd setValue:[NSString stringWithFormat:@"%ld",self.cbxToStation.indexOfSelectedItem] forKey:@"tostationindex"];
        self.savedDate=(NSDictionary *)sd;
        
        self.QueryCount = 0;
        [self query];
    }
}
- (void) setQueryResultToTableView
{
    self.dtQuery.data=self.queryResultData;
    [self.dtQuery reloadData];
}
- (void)queryLock
{
    [self addLog:[NSString stringWithFormat:@"查询车次：%ld",self.QueryCount]];
    
    NSDateFormatter * formate=[[NSDateFormatter alloc]init];
    [formate setDateFormat:@"yyyy-MM-dd"];
    NSString *date = [formate stringFromDate:self.dtpDate.dateValue];
    NSString *search = nil;
    NSString *sessionFrom =[[self.stations objectAtIndex:[self.cbxFromStation indexOfSelectedItem]] objectForKey:@"value"];
    NSString *sessionTo =[[self.stations objectAtIndex:[self.cbxToStation indexOfSelectedItem]] objectForKey:@"value"];
    
    NSString *url = [NSString stringWithFormat:HOST_URL@"/otn/leftTicket/query?leftTicketDTO.train_date=%@&leftTicketDTO.from_station=%@&leftTicketDTO.to_station=%@&purpose_codes=ADULT",date,sessionFrom,sessionTo];
    while (YES) {
        search = [self getText:url IsPost:NO];
        if(search==nil)
        {
            usleep(500*1000);
        }
        else
        {
            break;
        }
    }
    
    NSDictionary *json = [search objectFromJSONString];
    self.queryResultData=[json objectForKey:@"data"];
    [self performSelectorOnMainThread:@selector(setQueryResultToTableView) withObject:nil waitUntilDone:NO];
    NSArray *messages = [json objectForKey:@"messages"];
    if(messages!=nil && messages.count>0)
    {
        [self addLog:[messages objectAtIndex:0]];
    }
    if(self.yudingLoopRun)
    {
        for (NSDictionary * item  in self.queryResultData) {
            M12306TrainInfo * info = [[M12306TrainInfo alloc]initWithDictionary:item];
            if([info Success:self.txtTrainNameRegx.stringValue])
            {
                
                self.currTrainInfo=info;
                NSString * seatCode=[self.seatData objectForKey:[self.popupSeat selectedItem].title];
                NSInteger ticketCoun=[self.currTrainInfo TicketCountForSeat:seatCode];
                NSString *trainName=self.currTrainInfo.TrainName;
                [self addLog:[NSString stringWithFormat:@"开始预订:%@,余票:%ld",trainName,ticketCoun]];
                self.taskResult=TASK_RESULT_YES;
                break;
            }
        }
    }
    
    
    
}

- (void)yuding:(M12306TrainInfo *)info
{
    
    M12306Form* yudingForm=[[M12306Form alloc]initWithActionURL:HOST_URL@"/otn/confirmPassenger/autoSubmitOrderRequest"];
    NSString *sessionFromName =[[self.stations objectAtIndex:[self.cbxFromStation indexOfSelectedItem]] objectForKey:@"display"];
    NSString *sessionToName =[[self.stations objectAtIndex:[self.cbxToStation indexOfSelectedItem]] objectForKey:@"display"];
    NSString * date=[self formatDate:self.dtpDate.dateValue strFormat:@"yyyy-MM-dd"];
    NSString *seat=[self.seatData objectForKey:[self.popupSeat selectedItem].title];
    NSLog(@"%@",info.secretStr);
    [yudingForm setTagValue:info.secretStr forKey:@"secretStr"];
    [yudingForm setTagValue:date forKey:@"train_date"];
    [yudingForm setTagValue:@"dc" forKey:@"tour_flag"];
    [yudingForm setTagValue:@"ADULT" forKey:@"purpose_codes"];
    [yudingForm setTagValue:sessionFromName forKey:@"query_from_station_name"];
    [yudingForm setTagValue:sessionToName forKey:@"query_to_station_name"];
    [yudingForm setTagValue:@"2" forKey:@"cancel_flag"];
    [yudingForm setTagValue:@"000000000000000000000000000000" forKey:@"bed_level_order_num"];
    
    NSString *passengerTicketStr=@"";
    NSString *oldPassengerStr=@"";
    for (int i=0; i<[self.tablePassenger.data count]; i++) {
        M12306passengerTicketItem * item =[self.tablePassenger.data objectAtIndex:i];
        if(item.state)
        {
            passengerTicketStr=[passengerTicketStr stringByAppendingFormat:@"%@,0,%@,%@,%@,%@,%@,N_",seat,item.Ticket,item.Name,item.Cardtype,item.Cardno,item.Mobileno];
            oldPassengerStr=[oldPassengerStr stringByAppendingFormat:@"%@,%@,%@,%@_",item.Name,item.Cardtype,item.Cardno,item.Ticket];
        }
    }
    passengerTicketStr=[passengerTicketStr substringWithRange:NSMakeRange(0, [passengerTicketStr length]-1)];
    [yudingForm setTagValue:passengerTicketStr forKey:@"passengerTicketStr"];
    [yudingForm setTagValue:oldPassengerStr forKey:@"oldPassengerStr"];
    NSString * postResult = [yudingForm post];
    if(postResult)
    {
        [self yudingDoResult:postResult];
    }
    else
    {
        self.taskResult=TASK_RESULT_ERROR;
    }
}
- (void)yudingDoResult:(NSString *)strResult
{
    NSDictionary *json = [strResult objectFromJSONString];
    NSNumber *status=[json objectForKey:@"status"];
    NSNumber *httpstatus=[json objectForKey:@"httpstatus"];
    NSArray *messages=[json objectForKey:@"messages"];
    if(status.boolValue && httpstatus.intValue==200)
    {
        NSDictionary *data=[json objectForKey:@"data"];
        NSString * result = [data objectForKey:@"result"];
        NSNumber * submitStatus = [data objectForKey:@"submitStatus"];
        if(submitStatus.boolValue)
        {
            self.yudingResult=result;
            self.taskResult=TASK_RESULT_YES;
            return;
        }
        
    }
    if(messages && messages.count>0)
    {
        
        if([[messages objectAtIndex:0]rangeOfString:@"未完成订单"].location != NSNotFound )
        {
            [self stopYudingLoop];
            [self addLog:@"含有未完成订单！！！！"];
        }
        else
        {
            [self addLog:[messages objectAtIndex:0]];
        }
    }
    else
    {
        [self addLog:@"预订错误"];
    }
    sleep(1);
    self.taskResult=TASK_RESULT_ERROR;
    
}


- (void)checkImgCode
{
    
    M12306Form* yudingForm=[[M12306Form alloc]initWithActionURL:HOST_URL@"/otn/confirmPassenger/checkRandCode"];
    
    [yudingForm setTagValue:@"sjrand" forKey:@"rand"];
    [yudingForm setTagValue:self.txtCommitCode.stringValue forKey:@"randCode"];
    
    NSString * postResult = [yudingForm post];
    if(postResult)
    {
        [self checkImgCodeDoResult:postResult];
    }
    else
    {
        self.taskResult=TASK_RESULT_ERROR;
    }
}
- (void)checkImgCodeDoResult:(NSString *)strResult
{
    NSDictionary *json = [strResult objectFromJSONString];
    NSNumber *status=[json objectForKey:@"status"];
    NSNumber *httpstatus=[json objectForKey:@"httpstatus"];
    NSArray *messages=[json objectForKey:@"messages"];
    
    if(status.boolValue && httpstatus.intValue==200)
    {
        NSDictionary *data=[json objectForKey:@"data"];
        
        NSNumber * submitStatus = [data objectForKey:@"submitStatus"];
        if(submitStatus.boolValue)
        {
            self.taskResult=TASK_RESULT_YES;
            return;
        }
        
    }
    if(messages && messages.count>0)
    {
        [self addLog:[messages objectAtIndex:0]];
    }
    else
    {
        [self addLog:@"提交错误"];
    }
    sleep(1);
    self.taskResult=TASK_RESULT_ERROR;
    
}

- (void)yudingCheck
{
    M12306Form* yudingForm=[[M12306Form alloc]initWithActionURL:HOST_URL@"/otn/confirmPassenger/confirmSingleForQueue"];
    NSString *seat=[self.seatData objectForKey:[self.popupSeat selectedItem].title];
    NSArray * parms = [self.yudingResult componentsSeparatedByString:@"#"];
    NSString *passengerTicketStr=@"";
    NSString *oldPassengerStr=@"";
    for (int i=0; i<[self.tablePassenger.data count]; i++) {
        M12306passengerTicketItem * item =[self.tablePassenger.data objectAtIndex:i];
        if(item.state)
        {
            passengerTicketStr=[passengerTicketStr stringByAppendingFormat:@"%@,0,%@,%@,%@,%@,%@,N_",seat,item.Ticket,item.Name,item.Cardtype,item.Cardno,item.Mobileno];
            oldPassengerStr=[oldPassengerStr stringByAppendingFormat:@"%@,%@,%@,%@_",item.Name,item.Cardtype,item.Cardno,item.Ticket];
        }
    }
    passengerTicketStr=[passengerTicketStr substringWithRange:NSMakeRange(0, [passengerTicketStr length]-1)];
    [yudingForm setTagValue:passengerTicketStr forKey:@"passengerTicketStr"];
    [yudingForm setTagValue:oldPassengerStr forKey:@"oldPassengerStr"];
    [yudingForm setTagValue:@"" forKey:@"randCode"];
    [yudingForm setTagValue:@"ADULT" forKey:@"purpose_codes"];
    
    [yudingForm setTagValue:[parms objectAtIndex:1] forKey:@"key_check_isChange"];
    [yudingForm setTagValue:[parms objectAtIndex:2] forKey:@"leftTicketStr"];
    [yudingForm setTagValue:[parms objectAtIndex:0] forKey:@"train_location"];
    NSString * postResult = [yudingForm post];
    if(postResult)
    {
        [self yudingCheckDoResult:postResult];
    }
    else
    {
        self.taskResult=TASK_RESULT_ERROR;
    }
}
- (void)yudingCheckDoResult:(NSString *)strResult
{
    NSDictionary *json = [strResult objectFromJSONString];
    NSNumber *status=[json objectForKey:@"status"];
    NSNumber *httpstatus=[json objectForKey:@"httpstatus"];
    NSArray *messages=[json objectForKey:@"messages"];
    
    if(status.boolValue && httpstatus.intValue==200)
    {
        NSDictionary *data=[json objectForKey:@"data"];
        
        NSNumber * submitStatus = [data objectForKey:@"submitStatus"];
        if(submitStatus.boolValue)
        {
            self.taskResult=TASK_RESULT_YES;
            return;
        }
        
    }
    if(messages && messages.count>0)
    {
        [self addLog:[messages objectAtIndex:0]];
    }
    else
    {
        [self addLog:@"提交错误"];
    }
    sleep(1);
    self.taskResult=TASK_RESULT_ERROR;
    
}

- (void)yudingWaitOrder
{
    NSString *strResult=[self getText:HOST_URL@"/otn/confirmPassenger/queryOrderWaitTime?random=1386483829836&tourFlag=dc&_json_att=" IsPost:NO];
    NSDictionary *json = [strResult objectFromJSONString];
    NSNumber *status=[json objectForKey:@"status"];
    NSNumber *httpstatus=[json objectForKey:@"httpstatus"];
    NSArray *messages=[json objectForKey:@"messages"];
    
    if(status.boolValue && httpstatus.intValue==200)
    {
        NSDictionary *data=[json objectForKey:@"data"];
        
        NSNumber * queryOrderWaitTimeStatus = [data objectForKey:@"queryOrderWaitTimeStatus"];
        if(queryOrderWaitTimeStatus.boolValue)
        {
            NSNumber * waitTime=[data objectForKey:@"waitTime"];
            NSNumber *waitCount=[data objectForKey:@"waitCount"];
            NSString *orderId=[data objectForKey:@"orderId"];
            
            if (waitTime.intValue == -1)
            {
                NSString * log=[NSString stringWithFormat:@"购票成功，订单号：%@.快去付款！",orderId];
                [self addLog:log];
                
            }
            else if (waitTime.intValue == -2)
            {
                NSString * log=[NSString stringWithFormat:@"出票失败,重新购票."];
                [self addLog:log];
                self.yudingStatus=YUDING_STATUS_YUDING;
            }
            else if (waitTime.intValue == -3)
            {
                [self addLog:@"订单已经被取消！"];
            }
            else if (waitTime.intValue == -4)
            {
                [self addLog:@"正在处理中...."];
            }
            else
            {
                [self addLog:[NSString stringWithFormat:@"等待人数:%d,等待时间:%d",waitCount.intValue,waitTime.intValue]];
            }
            sleep(1);
            return;
        }
        
    }
    if(messages && messages.count>0)
    {
        [self addLog:[messages objectAtIndex:0]];
    }
    else
    {
        [self addLog:@"查询错误"];
    }
    sleep(1);
    
}

- (void)getCommitImgCode
{
    [NSThread detachNewThreadSelector:@selector(getCommitImgCodeLock) toTarget:self withObject:nil];
}
- (void)getCommitImgCodeLock
{
    NSString * url= HOST_URL@"/otn/passcodeNew/getPassCodeNew.do?module=login&rand=sjrand";
    NSImage * map=nil;
    while (YES) {
        map=[self getImageWithUrl:url refUrl:HOST_URL@"/otn/passcodeNew/getPassCodeNew.do?module=login&rand=sjrand"];
        if(map==nil)
        {
            [self addLog:@"获取验证码错误,稍候重试!"];
            usleep(500*1000);
        }
        else
        {
            break;
        }
    }
    self.taskResult=TASK_RESULT_YES;
    [self performSelectorOnMainThread:@selector(setCommitImgCodeLock:) withObject:map waitUntilDone:YES];
}
- (void)setCommitImgCodeLock:(NSImage *)image
{
    self.imgCommitCode.image=image;
    self.txtCommitCode.stringValue=@"";
    [self.txtCommitCode becomeFirstResponder];
    
}
- (void)txtCommitCodeTextChageAction
{
    if ([self.txtCommitCode.stringValue isEqualToString:@" "])
    {
        [self getCommitImgCode];
    }
    else if ([self.txtCommitCode.stringValue length] == 4)
    {
        self.taskResult=TASK_RESULT_YES;
    }
}

- (IBAction)loginOutClick:(id)sender {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    NSURL *url = [NSURL URLWithString:HOST_URL];
    if (url) {
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url];
        for (int i = 0; i < [cookies count]; i++) {
            NSHTTPCookie *cookie = (NSHTTPCookie *)[cookies objectAtIndex:i];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
            
        }
    }
    [self addLog:@"已不在线"];
    self.lblLoginMsg.stringValue=@"【未登录】";
    self.isLogin=NO;
    [self getLoginImgCode];
}
- (void)query
{
    [NSThread detachNewThreadSelector:@selector(queryLock) toTarget:self withObject:nil];
}
- (NSString *)formatDate:(NSDate *)date strFormat:(NSString *)format
{
    NSDateFormatter * dateFormat=[[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:format];
    return [dateFormat stringFromDate:date];
}
- (IBAction)tablePassengerChange:(id)sender {
    NSArray * array = self.tablePassenger.getSelectedCardNoArray;
    NSMutableArray *sd = [self.savedDate mutableCopy];
    [sd setValue:array forKey:@"selectedpassenger"];
    self.savedDate=(NSDictionary *)sd;
}

- (IBAction)btnStopYudingClick:(id)sender {
    self.QueryCount = 0;
    [self stopYudingLoop];
}

- (IBAction)btnYudingClick:(id)sender {
    int selectedPassengerCount=0;
    for (int i=0; i<[self.tablePassenger.data count]; i++) {
        M12306passengerTicketItem * item =[self.tablePassenger.data objectAtIndex:i];
        if(item.state)
        {
            selectedPassengerCount++;
        }
    }
    if(selectedPassengerCount==0)
    {
        NSAlert * alert=[[NSAlert alloc]init];
        [alert addButtonWithTitle:@"确定"];
        [alert setMessageText:@"未选择联系人"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
    }
    else if (!self.isLogin) {
        NSAlert * alert=[[NSAlert alloc]init];
        [alert addButtonWithTitle:@"确定"];
        [alert setMessageText:@"未登录"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
    }
    else if([self.cbxFromStation indexOfSelectedItem]<0)
    {
        NSAlert * alert=[[NSAlert alloc]init];
        [alert addButtonWithTitle:@"确定"];
        [alert setMessageText:@"未选择出发站"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
    }
    else if([self.cbxToStation indexOfSelectedItem]<0)
    {
        NSAlert * alert=[[NSAlert alloc]init];
        [alert addButtonWithTitle:@"确定"];
        [alert setMessageText:@"未选择到达站"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
    }
    else
    {
        NSMutableArray *sd = [self.savedDate mutableCopy];
        [sd setValue:[NSString stringWithFormat:@"%ld",self.cbxFromStation.indexOfSelectedItem] forKey:@"fromstationindex"];
        [sd setValue:[NSString stringWithFormat:@"%ld",self.cbxToStation.indexOfSelectedItem] forKey:@"tostationindex"];
        [sd setValue:self.txtTrainNameRegx.stringValue forKey:@"trainnameregx"];
        [sd setValue:[NSString stringWithFormat:@"%ld",self.popupSeat.indexOfSelectedItem] forKey:@"seatindex"];
        self.savedDate=(NSDictionary *)sd;
        self.QueryCount = 0;
        [self startYudingLoop];
    }
}
-(NSDictionary *)savedDate
{
    @synchronized(self)
    {
        if(_savedDate==nil)
        {
            NSString *path= [self storeFilePath];
            NSFileManager *fm =[NSFileManager defaultManager];
            if([fm fileExistsAtPath:path])
            {
                _savedDate =[[NSDictionary alloc] initWithContentsOfFile:path];
            }
            if(_savedDate==nil)
            {
                _savedDate=[NSDictionary dictionary];
            }
        }
        
        return _savedDate;
    }
    
}
-(void)setSavedDate:(NSDictionary *)savedDate
{
    @synchronized(self)
    {
        _savedDate=savedDate;
        NSString *path= [self storeFilePath];
        NSFileManager *fm =[NSFileManager defaultManager];
        if(![fm fileExistsAtPath:path])
        {
            [fm createFileAtPath:path contents:nil attributes:nil];
        }
        [_savedDate writeToFile:path atomically:YES];
    }
}
-(NSString *)storeFilePath
{
    NSString * path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"store.plist"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        [[NSFileManager defaultManager]createFileAtPath:path contents:nil attributes:nil];
    }
    return path;
}
-(NSString *)getResFile:(NSString *)fileName
{
    NSString * path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fileName];
    
    return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];;
}
-(void)startYudingLoop
{
    if(!self.yudingLoopRuning)
    {
        self.yudingLoopRuning=YES;
        self.yudingLoopRun=YES;
        self.yudingStatus=YUDING_STATUS_QUERY;
        [NSThread detachNewThreadSelector:@selector(yudingLoop) toTarget:self withObject:nil];
    }
}
-(void)stopYudingLoop
{
    self.yudingLoopRun=NO;
}
-(void)yudingLoop
{
    while (self.yudingLoopRun) {
        [self addLog:[NSString stringWithFormat:@"task status:%d",self.yudingStatus]];
        self.taskResult=TASK_RESULT_NONE;
        switch (self.yudingStatus) {
            case YUDING_STATUS_QUERY:
                [self queryLock];
                break;
            case YUDING_STATUS_YUDING:
                [self yuding:self.currTrainInfo];
                break;
            case YUDING_STATUS_GET_IMG_CODE:
                [self getCommitImgCodeLock];
                break;
            case YUDING_STATUS_WAIT_INPUT_IMG_CODE:
                while(self.taskResult==TASK_RESULT_NONE)
                {
                    usleep(100*1000);
                }
                break;
            case YUDING_STATUS_CHECK_IMG_CODE:
                [self checkImgCode];
                break;
            case YUDING_STATUS_YUDING_CHECK:
                [self yudingCheck];
                break;
            case YUDING_STATUS_WAIT_ORDER:
                [self yudingWaitOrder];
                break;
            default:
                usleep(100*1000);
                break;
        }
        if(self.taskResult!=TASK_RESULT_NONE)
        {
            switch (self.yudingStatus) {
                case YUDING_STATUS_NONE:
                    break;
                case YUDING_STATUS_QUERY:
                    self.yudingStatus=YUDING_STATUS_YUDING;
                    break;
                case YUDING_STATUS_YUDING:
                    self.yudingStatus=YUDING_STATUS_YUDING_CHECK;//跳过验证码
                    break;
                case YUDING_STATUS_GET_IMG_CODE:
                    self.yudingStatus=YUDING_STATUS_WAIT_INPUT_IMG_CODE;
                    break;
                case YUDING_STATUS_WAIT_INPUT_IMG_CODE:
                    self.yudingStatus=YUDING_STATUS_CHECK_IMG_CODE;
                    break;
                case YUDING_STATUS_CHECK_IMG_CODE:
                    if(self.taskResult == TASK_RESULT_YES)
                        self.yudingStatus=YUDING_STATUS_YUDING_CHECK;
                    else if(self.taskResult==TASK_RESULT_ERROR)
                        self.yudingStatus=YUDING_STATUS_GET_IMG_CODE;
                    break;
                case YUDING_STATUS_YUDING_CHECK:
                    if(self.taskResult == TASK_RESULT_YES)
                        self.yudingStatus=YUDING_STATUS_WAIT_ORDER;
                    else if(self.taskResult==TASK_RESULT_ERROR)
                        self.yudingStatus=YUDING_STATUS_YUDING_CHECK;
                    break;
                case YUDING_STATUS_WAIT_ORDER:
                    if(self.taskResult == TASK_RESULT_YES)
                        [self stopYudingLoop];
                    break;
            }
        }
        
    }
    self.yudingLoopRuning=NO;
}
@end
