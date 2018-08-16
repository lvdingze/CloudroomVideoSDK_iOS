//
//  MeetingController.m
//  Meeting
//
//  Created by king on 2017/11/14.
//  Copyright © 2017年 BossKing10086. All rights reserved.
//

#import "MeetingController.h"
#import "AppDelegate.h"
#import "VideoMeetingCallBack.h"
#import "VideoMgrCallBack.h"
#import "MeetingHelper.h"
#import "IQKeyboardManager.h"
#import "RotationUtil.h"
#import "BKDrawer.h"
#import "MJExtension.h"
#include "BKBrushButton.h"
#import "WhiteBoardModel.h"
typedef NS_ENUM(NSUInteger, BrushToolType) {
    SMALL_BRUSH = 1000,
    DEFAULT_BRUSH,
    BIG_BRUSH,
    BLUE_COLOR,
    GREEN_COLOR,
    YELLOW_COLOR,
    ORANGE_COLOR,
    RED_COLOR,
};

@interface MeetingController () <VideoMeetingDelegate, VideoMgrDelegate, BKBrushViewDelegate>
@property (nonatomic, strong) UIAlertController *dropVC; /**< 掉线弹框 */
@property (weak, nonatomic) IBOutlet UILabel            *meetNumLabel;
@property (weak, nonatomic) IBOutlet UIButton           *undoBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *boardW;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *boardH;
@property (weak, nonatomic) IBOutlet BKDrawer           *drawerView;
@property (weak, nonatomic) IBOutlet UIView *brushToolView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *brushToolViewW;
@property (weak, nonatomic) IBOutlet UIView *toolView;
@property (assign,nonatomic) NSInteger currrentColorTpye;
@property (assign,nonatomic) NSInteger currrentBrushTpye;
@property (weak, nonatomic) IBOutlet BKBrushButton *redColorBtn;
@property (weak, nonatomic) IBOutlet UIButton *smallBrushBtn;
@property (weak, nonatomic) IBOutlet UIButton *bigBrushBtn;
@property (weak, nonatomic) IBOutlet UIButton *defaultBrushBtn;
@property (nonatomic, copy)NSString* currentWbKey;   //当前白板key
@property (nonatomic, strong) NSMutableDictionary       *allWhiteBoardDict;
@property (nonatomic, strong) NSMutableDictionary       *allPicToModelDict;
@property (nonatomic, strong) NSMutableArray       *allWhilteBoardKey;
@property (assign,nonatomic) CGFloat showScale;
@end

@implementation MeetingController
#pragma mark -lazing
-(NSMutableDictionary *)allWhiteBoardDict{
    
    if(_allWhiteBoardDict == nil)
    {
        _allWhiteBoardDict = [NSMutableDictionary dictionary];
    }
    return _allWhiteBoardDict;
}

-(NSMutableDictionary *)allPicToModelDict{
    if(_allPicToModelDict == nil){
        _allPicToModelDict = [NSMutableDictionary dictionary];
    }
    return _allPicToModelDict;
}

-(NSMutableArray *)allWhilteBoardKey{
    if(_allWhilteBoardKey == nil){
        _allWhilteBoardKey = [NSMutableArray array];
    }
    return _allWhilteBoardKey;
}
#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self commonSetup];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[IQKeyboardManager sharedManager] setEnable:NO];
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:NO];
    
    // 不灭屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    // FIXME:屏幕共享结束回调接收不到 added by king 20170905
    // 更新代理
    [self updateDelegate];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[IQKeyboardManager sharedManager] setEnable:YES];
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:YES];
}
#pragma mark - selector
- (IBAction)undoBtnDidClick:(id)sender {
    [self.drawerView undoLocalLine];
}
- (IBAction)redoBtnDidClick:(id)sender {
    [self.drawerView redoLocalLine];
    [self.undoBtn setEnabled:YES];
}

- (IBAction)trashBtnDidClick:(id)sender {
    [self.drawerView deleteAllLine];
}

- (IBAction)brushBtnDidClick:(id)sender {
    UIButton *targetBtn = (UIButton*)sender;
    [targetBtn setSelected:!targetBtn.selected];
    [self.brushToolView setHidden:!targetBtn.selected];
}

- (IBAction)exitBtn:(id)sender {
    [self handleExit];
}

//画笔响应
- (IBAction)brushToolSizeBtnDidClick:(id)sender {
    UIButton *targetBtn = (UIButton*)sender;
    if(targetBtn.tag == _currrentBrushTpye && targetBtn.selected) return;
    _currrentBrushTpye = targetBtn.tag;
    [targetBtn setSelected:!targetBtn.selected];
    switch (targetBtn.tag) {
        case SMALL_BRUSH:
        {
            [self.drawerView setLocalLineW:2];
            [self controlBrushSizeViewSelectState:SMALL_BRUSH];
        }
            break;
        case DEFAULT_BRUSH:
        {
            [self.drawerView setLocalLineW:4];
            [self controlBrushSizeViewSelectState:DEFAULT_BRUSH];
        }
            break;
        case BIG_BRUSH:
        {
            [self.drawerView setLocalLineW:6];
            [self controlBrushSizeViewSelectState:BIG_BRUSH];
        }
            break;
        default:
            break;
    }
}

- (IBAction)brushToolColorBtnDidClick:(id)sender {
    
    UIButton *targetBtn = (UIButton*)sender;
    if(targetBtn.tag == _currrentColorTpye && targetBtn.selected) return;
    _currrentColorTpye = targetBtn.tag;
    [targetBtn setSelected:!targetBtn.selected];
    
    switch (targetBtn.tag) {
        case BLUE_COLOR:
        {
            [self controlBrushToolViewSelectState:BLUE_COLOR];
            [self.drawerView.drawerModel setColor:[UIColor blueColor]];
        }
            break;
        case GREEN_COLOR:
        {
            [self controlBrushToolViewSelectState:GREEN_COLOR];
            [self.drawerView.drawerModel setColor:[UIColor greenColor]];
        }
            break;
        case YELLOW_COLOR:
        {
            [self controlBrushToolViewSelectState:YELLOW_COLOR];
            [self.drawerView.drawerModel setColor:[UIColor yellowColor]];
        }
            break;
        case ORANGE_COLOR:
        {
            [self controlBrushToolViewSelectState:ORANGE_COLOR];
            [self.drawerView.drawerModel setColor:[UIColor orangeColor]];
        }
            break;
        case RED_COLOR:
        {
            [self controlBrushToolViewSelectState:RED_COLOR];
            [self.drawerView.drawerModel setColor:[UIColor redColor]];
        }
            break;
        default:
            break;
    }
    
}

- (void)controlBrushSizeViewSelectState:(int) type{
    NSArray *views = self.brushToolView.subviews;
    for (id obj in views) {
        UIButton *btn = (UIButton*)obj;
        if(btn.tag == RED_COLOR || btn.tag == ORANGE_COLOR ||btn.tag == YELLOW_COLOR || btn.tag == GREEN_COLOR || btn.tag == BLUE_COLOR ||btn.tag == type)
        {
            continue;
        }
        else{
            if(btn.selected)
            {
                [btn setSelected:!btn.selected];
            }
        }
    }
    
}
- (void)controlBrushToolViewSelectState:(int) type{
    NSArray *views = self.brushToolView.subviews;
    for (id obj in views) {
        UIButton *btn = (UIButton*)obj;
        if(btn.tag == SMALL_BRUSH || btn.tag == DEFAULT_BRUSH ||btn.tag == BIG_BRUSH ||btn.tag == type)
        {
            continue;
        }
        else{
            if(btn.selected)
            {
                [btn setSelected:!btn.selected];
            }
        }
    }
}
#pragma mark - VideoMgrDelegate
// 掉线通知
- (void)videoMgrCallBack:(VideoMgrCallBack *)callback lineOff:(CRVIDEOSDK_ERR_DEF)sdkErr {
    if (_dropVC) {
        weakify(self)
        [_dropVC dismissViewControllerAnimated:NO completion:^{
            strongify(wSelf)
            sSelf.dropVC = nil;
            
            if (sdkErr == CRVIDEOSDK_USER_BEEN_KICKOUT) { // 被踢
                [sSelf showAlert:@"您已被踢下线!"];
            } else { // 掉线
                [sSelf showAlert:@"您已掉线!"];
            }
        }];
        return;
    }
    
    if (sdkErr == CRVIDEOSDK_USER_BEEN_KICKOUT) { // 被踢
        [self showAlert:@"您已被踢下线!"];
    } else { // 掉线
        [self showAlert:@"您已掉线!"];
    }
}
#pragma mark - VideoMeetingDelegate
// 入会结果
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback enterMeetingRslt:(CRVIDEOSDK_ERR_DEF)code {
    [HUDUtil hudHiddenProgress:YES];
    
    if (code == CRVIDEOSDK_NOERR) {
        [HUDUtil hudShow:@"进入房间成功!" delay:1 animated:YES];
        [self enterMeetingSuccess];
    } else if (code == CRVIDEOSDK_MEETROOMLOCKED) { // FIXME:房间加锁后,进入房间提示语不正确 added by king 201711291513
        [self enterMeetingFail:@"房间已加锁!"];
    } else {
        [self enterMeetingFail:@"进入房间失败!"];
    }
}

// 房间被结束
- (void)videoMeetingCallBackMeetingStopped:(VideoMeetingCallBack *)callback {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:@"退出房间!" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self jumpToPMeeting];
    }];
    [alertController addAction:doneAction];
    [self presentViewController:alertController animated:YES completion:^{}];
}

// 房间掉线
- (void)videoMeetingCallBackMeetingDropped:(VideoMeetingCallBack *)callback {
    [self showReEnter:@"房间掉线!"];
}

- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyInitBoards:(NSArray<SubPageInfo *> *)boards {
    
    if (boards.count > 0) {
        
        for (SubPageInfo* subPageInfo in boards) {
            NSString* wbKey = [NSString stringWithFormat:@"%d.%d",subPageInfo.boardID.localID,subPageInfo.boardID.termID];
            WhiteBoardModel* wbModel = [[WhiteBoardModel alloc]init];
            wbModel.whiteBoardBaseInfo = subPageInfo;
            wbModel.whiteBoardPageInfo  = [NSMutableDictionary dictionary];
            [self.allWhiteBoardDict setObject:wbModel forKey:wbKey];
            [self.allWhilteBoardKey addObject:wbKey];
        }
        //获取当前白板显示页
        {
            CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
            SubPage * currrentPage = [cloudroomVideoMeeting getCurrentSubPage];
            //如果没有显示的白板，默认显示最后一个
            __block bool noWhiteBoard = YES;
            [self.allWhiteBoardDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
               
                WhiteBoardModel* model = (WhiteBoardModel*)obj;
                if([self isEqualSubPage:model.whiteBoardBaseInfo.boardID with:currrentPage])
                {
                    noWhiteBoard = NO;
                }
                
            }];
            if(noWhiteBoard)
            {
                currrentPage = [boards lastObject].boardID;
            }
            NSString* wbKey = [NSString stringWithFormat:@"%d.%d",currrentPage.localID,currrentPage.termID];
            WhiteBoardModel* wbModel = [self.allWhiteBoardDict objectForKey:wbKey];
            CGSize curBoardSize = (CGSize){wbModel.whiteBoardBaseInfo.width, wbModel.whiteBoardBaseInfo.height};
            [self changeDrawViewSize:curBoardSize];
            //保存当前key
            self.currentWbKey = wbKey;
        }
        
    }else{
        [self checkCreateBoard];
    }
}

/* 通知之前已经创建好的白板上的图元数据 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyInitBoardPageDat:(SubPage *)boardID boardPageNo:(int)boardPageNo bkImgID:(NSString *)bkImgID elements:(NSString *)elements operatorID:(NSString *)operatorID {
    
    NSString* wbKey = [NSString stringWithFormat:@"%d.%d",boardID.localID,boardID.termID];
    WhiteBoardModel *model = [self.allWhiteBoardDict objectForKey:wbKey];
    BKDrawerModel *newModel = [[BKDrawerModel alloc]init];
    newModel.curBoardSize = CGSizeMake(model.whiteBoardBaseInfo.width, model.whiteBoardBaseInfo.height);
    newModel.subPage = boardID;
    newModel.allLayerArray = [NSMutableArray array];
    newModel.lineW = 2;
    newModel.type = PENCIL;
    newModel.currentPage = boardPageNo;
    newModel.color = [UIColor redColor];
    newModel.bkImg  = nil;
    newModel.imgID = bkImgID;
    newModel.percent = 0;
    
    NSObject *elementsAny = [elements mj_JSONObject];
    if ([elementsAny isKindOfClass:[NSArray class]]) {
        NSArray *elementsArray = (NSArray *)elementsAny;
        newModel.allPointStringArray = [NSMutableArray arrayWithArray:elementsArray];
        //设置当前路径
        if([self.currentWbKey isEqualToString:wbKey] && model.whiteBoardBaseInfo.curPage == boardPageNo)
        {
            self.drawerView.drawerModel = newModel;
        }
    }
    [model.whiteBoardPageInfo setObject:newModel forKey:[NSString stringWithFormat:@"%d",boardPageNo]];
    
    if([bkImgID length] > 0)
    {
        //下载文件
        NSString *localPath = [self getWhileBoardImgPath:boardID pageNo:boardPageNo];
        CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
        [cloudroomVideoMeeting downloadNetDiskFile:bkImgID localFilePath:localPath];
    }
    else{
        [self.drawerView drawDoc];
    }
    
}

/* 通知创建子功能页白板 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyCreateBoard:(SubPageInfo *)board operatorID:(NSString *)operatorID {
    
    //创建新文档
    SubPageInfo *subPageInfo = board;
    //设置正确尺寸
    CGSize curBoardSize = (CGSize){subPageInfo.width, subPageInfo.height};
    [self changeDrawViewSize:curBoardSize];
    //保存新创建的白板
    NSString* wbKey = [NSString stringWithFormat:@"%d.%d",subPageInfo.boardID.localID,subPageInfo.boardID.termID];
    WhiteBoardModel* wbModel = [[WhiteBoardModel alloc]init];
    wbModel.whiteBoardBaseInfo = subPageInfo;
    wbModel.whiteBoardPageInfo = [NSMutableDictionary dictionary];
    [self.allWhiteBoardDict setObject:wbModel forKey:wbKey];
    [self.allWhilteBoardKey addObject:wbKey];
    
    self.currentWbKey = wbKey;
}

/* 通知关闭白板 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyCloseBoard:(SubPage *)boardID operatorID:(NSString *)operatorID {
    
    //删除白板数据
    NSString* wbKey = [NSString stringWithFormat:@"%d.%d",boardID.localID,boardID.termID];
    [self.allWhiteBoardDict removeObjectForKey:wbKey];
    [self.allWhilteBoardKey removeObject:wbKey];
    [self.allPicToModelDict removeObjectForKey:self.drawerView.drawerModel.imgID];
    
    WhiteBoardModel* wbModel = [self.allWhiteBoardDict objectForKey:[self.allWhilteBoardKey lastObject]];
    self.drawerView.drawerModel = [wbModel.whiteBoardPageInfo objectForKey:[NSString stringWithFormat:@"%d",wbModel.whiteBoardBaseInfo.curPage]];
    
    CGSize curBoardSize = CGSizeMake(self.drawerView.drawerModel.curBoardSize.width, self.drawerView.drawerModel.curBoardSize.height);
    [self changeDrawViewSize:curBoardSize];
    
    if(![self.drawerView.drawerModel.imgID isEqualToString:@""])
    {
        self.drawerView.drawerModel.percent = [[self.allPicToModelDict objectForKey:self.drawerView.drawerModel.imgID] integerValue];
    }
    //保存当前key
    self.currentWbKey = wbKey;
    
   if([self.allWhiteBoardDict count] == 0)
    {
        _boardW.constant = 0;
        _boardH.constant = 0;
    }
}

/*切换白板文档*/
-(void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifySwitchToPage:(MainPageType)mainPage subPage:(SubPage*)sPage{

    if(self.drawerView.drawerModel == nil) return;
    
    if(self.drawerView.drawerModel.subPage.localID == sPage.localID && self.drawerView.drawerModel.subPage.termID == sPage.termID) return;
    if(sPage.localID == 0 && sPage.termID == -1) return;
    
    NSLog(@"imgID: %@",self.drawerView.drawerModel.imgID);
    
    NSString* wbKey = [NSString stringWithFormat:@"%d.%d",sPage.localID,sPage.termID];
    WhiteBoardModel* wbModel = [self.allWhiteBoardDict objectForKey:wbKey];

    self.drawerView.drawerModel = [wbModel.whiteBoardPageInfo objectForKey:[NSString stringWithFormat:@"%d",wbModel.whiteBoardBaseInfo.curPage]];
    
    CGSize curBoardSize = CGSizeMake(self.drawerView.drawerModel.curBoardSize.width, self.drawerView.drawerModel.curBoardSize.height);
    [self changeDrawViewSize:curBoardSize];

    if(![self.drawerView.drawerModel.imgID isEqualToString:@""])
    {
        self.drawerView.drawerModel.percent = [[self.allPicToModelDict objectForKey:self.drawerView.drawerModel.imgID] integerValue];
    }
    //保存当前key
    self.currentWbKey = wbKey;
}
/* 通知添加图元信息 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback
       notifyAddBoardElement:(SubPage *)boardID
                 boardPageNo:(int)boardPageNo
                     element:(NSString *)element
                  operatorID:(NSString *)operatorID {
    
    NSObject *elementsAny = [element mj_JSONObject];
    if ([elementsAny isKindOfClass:[NSDictionary class]]) {
        
        NSDictionary *elementDict = (NSDictionary *)elementsAny;
        if (![[MeetingHelper shareInstance].nickname isEqualToString:operatorID]) {
            [self.drawerView drawElement:elementDict];
        }else{
            //调整自己画的放在最后
            [self.drawerView changPathOrder];
        }
    }
}

/* 通知修改图元信息 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyModifyBoardElement:(SubPage *)boardID boardPageNo:(int)boardPageNo element:(NSString *)element operatorID:(NSString *)operatorID {
}

/* 通知删除图元 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyDelBoardElement:(SubPage *)boardID boardPageNo:(int)boardPageNo elementIDs:(NSArray<NSString *> *)elementIDs operatorID:(NSString *)operatorID {
    
    [self.drawerView deleteLine:elementIDs];
}

/* 通知设置鼠标热点消息 */
- (void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyMouseHotSpot:(SubPage *)boardID boardPageNo:(int)boardPageNo x:(int)x y:(int)y operatorID:(NSString *)operatorID {
    
}

/* 通知当前页数据*/
-(void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyBoardCurPageNo:(SubPage *)boardID boardPageNo:(int)boardPageNo pos1:(int)pos1 pos2:(int)pos2 operatorID:(NSString*)operatorID{
    
    if(boardPageNo == self.drawerView.drawerModel.currentPage)
        return;
    
    NSString* wbKey = [NSString stringWithFormat:@"%d.%d",boardID.localID,boardID.termID];
    WhiteBoardModel *model = [self.allWhiteBoardDict objectForKey:wbKey];
    model.whiteBoardBaseInfo.curPage = boardPageNo;
    BKDrawerModel* pageInfo = [model.whiteBoardPageInfo objectForKey:[NSString stringWithFormat:@"%d",boardPageNo]];

    self.drawerView.drawerModel = pageInfo;
    self.drawerView.drawerModel.percent = [[self.allPicToModelDict objectForKey:pageInfo.imgID] integerValue];
}

/*下载进度*/
-(void)videoMeetingCallBack:(VideoMeetingCallBack *)callback notifyNetDiskTransforProgressFileID:(NSString*)fileID percent:(int)percent isUpload:(bool)isUpload{
    
    NSString* wbKey = [NSString stringWithFormat:@"%d.%d",self.drawerView.drawerModel.subPage.localID,self.drawerView.drawerModel.subPage.termID];

    WhiteBoardModel *model = [self.allWhiteBoardDict objectForKey:wbKey];
    BKDrawerModel* pageInfo = [model.whiteBoardPageInfo objectForKey:[NSString stringWithFormat:@"%d",self.drawerView.drawerModel.currentPage]];
    
    if([pageInfo.imgID isEqualToString:fileID] )
    {
        self.drawerView.drawerModel.percent = percent;
    }
    [self.allPicToModelDict setObject:@(percent) forKey:fileID];
    
}

#pragma mark - private method
-(void)changeDrawViewSize:(CGSize)size{
    
    _boardW.constant = [self getRealSize:size].width;
    _boardH.constant = [self getRealSize:size].height;
    [self.drawerView setRealW:[self getRealSize:size].width];
    [self.drawerView setRealH:[self getRealSize:size].height];
    NSLog(@"getRealSize %f",_showScale);
    [self.drawerView setShowScale:_showScale];
}

-(NSString*)getWhileBoardImgPath:(SubPage*)subPage pageNo:(int)pageNo{
    
    NSString* wbKey = [NSString stringWithFormat:@"%d.%d",subPage.localID,subPage.termID];
    NSString *libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    NSString *localPath = [libraryDir stringByAppendingPathComponent:[NSString stringWithFormat:@"Caches/CloudroomVideoSDK/Tmp/%@_%d",wbKey,pageNo]];
    return  localPath;
}

-(bool)isEqualSubPage:(SubPage*)s1 with:(SubPage*)s2{
    return (s1.localID == s2.localID && s1.termID == s2.termID);
}

- (void)commonSetup {
    //初始化界面设置
    [self initDefaultUI];
    // 设置代理
    [self updateDelegate];
    // 入会操作
    [self enterMeeting];
}

-(void)initDefaultUI{
    
    int magin =  8;
    self.smallBrushBtn.contentEdgeInsets = UIEdgeInsetsMake(magin, magin, magin, magin);
    self.defaultBrushBtn.contentEdgeInsets = UIEdgeInsetsMake(magin, magin, magin, magin);
    self.bigBrushBtn.contentEdgeInsets = UIEdgeInsetsMake(magin, magin, magin, magin);
    [self.smallBrushBtn setImage:[UIImage imageNamed:@"smallBrushNomal"] forState:UIControlStateNormal];
    [self.smallBrushBtn setImage:[UIImage imageNamed:@"smallBrushSelect"] forState:UIControlStateSelected];
    [self.defaultBrushBtn setImage:[UIImage imageNamed:@"defaultBrushNomal"] forState:UIControlStateNormal];
    [self.defaultBrushBtn setImage:[UIImage imageNamed:@"defaultBrushSelect"] forState:UIControlStateSelected];
    [self.bigBrushBtn setImage:[UIImage imageNamed:@"bigBrushNomal"] forState:UIControlStateNormal];
    [self.bigBrushBtn setImage:[UIImage imageNamed:@"bigBrushSelect"] forState:UIControlStateSelected];
    
    _currrentColorTpye = RED_COLOR;
    self.redColorBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    self.redColorBtn.layer.borderWidth = 3;
    
    [self.smallBrushBtn setSelected:YES];
    _currrentBrushTpye = SMALL_BRUSH;
    
    self.toolView.layer.cornerRadius = 20;
    [self.toolView.layer masksToBounds];
    
    self.brushToolView.layer.cornerRadius = 10;
    [self.brushToolView.layer masksToBounds];
    
    _showScale = 1.0f;
    
}
/**
 设置属性
 */
- (void)setStatusBarBG {
    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    
    if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
        statusBar.backgroundColor = UIColorFromRGBA(0, 0, 0, 0.5);
    }
}

/* 入会操作 */
- (void)enterMeeting {
    WLog(@"");
    
    if (_meetInfo.ID > 0) {
        [HUDUtil hudShowProgress:@"正在进入房间..." animated:YES];
        CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
        NSString *nickname = [[MeetingHelper shareInstance] nickname];
        [cloudroomVideoMeeting enterMeeting:_meetInfo.ID pswd:_meetInfo.pswd userID:nickname nikeName:nickname];
        [self.meetNumLabel setText:[NSString stringWithFormat:@"房间ID：%d",_meetInfo.ID]];
    }
}

/* 入会成功 */
- (void)enterMeetingSuccess {
    //[self performSelector:@selector(checkCreateBoard) withObject:nil afterDelay:0.5];
}

/**
 入会失败
 @param message 失败信息
 */
- (void)enterMeetingFail:(NSString *)message {
    [HUDUtil hudShow:message delay:3 animated:YES];
    
    if (_meetInfo.ID > 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self jumpToPMeeting];
        }];
        UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"重试" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self enterMeeting];
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:doneAction];
        [self presentViewController:alertController animated:NO completion:nil];
    }
}

/**
 重登操作
 @param message 重登信息
 */
- (void)showReEnter:(NSString *)message {
    weakify(self)
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"离开房间" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        strongify(wSelf)
        [sSelf jumpToPMeeting];
        sSelf.dropVC = nil;
        
    }];
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"重新登录" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        strongify(wSelf)
        // 离开房间
        [[CloudroomVideoMeeting shareInstance] exitMeeting];
        // 重新入会
        [sSelf enterMeeting];
        sSelf.dropVC = nil;
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:doneAction];
    [self presentViewController:alertController animated:NO completion:^{}];
    _dropVC = alertController;
}

/* 掉线/被踢下线 */
- (void)showAlert:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示:" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self jumpToPMeeting];
    }];
    [alertController addAction:doneAction];
    [self presentViewController:alertController animated:YES completion:^{}];
}

// TODO: 更新操作
/* 更新代理 */
- (void)updateDelegate {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.videoMgrCallBack setVideoMgrDelegate:self];
    [appDelegate.videoMeetingCallBack setVideoMeetingDelegate:self];
}

/* 退出 */
- (void)handleExit {
    // FIXME: 退出房间,防止误操作 (king 20180717)
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"离开房间?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}];
    UIAlertAction *done = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self jumpToPMeeting];
        
    }];
    [alertVC addAction:cancel];
    [alertVC addAction:done];
    [self presentViewController:alertVC animated:YES completion:nil];
}

/* 跳转到"预入会"界面 */
- (void)jumpToPMeeting {
    // 离开房间
    [[CloudroomVideoMeeting shareInstance] exitMeeting];
    // 注销
    [[CloudroomVideoMgr shareInstance] logout];
    // 退出界面
    [self dismissViewControllerAnimated:NO completion:nil];
    //清空缓存文件
//    NSString *libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
//    NSString *localPath = [libraryDir stringByAppendingPathComponent:@"Caches/CloudroomVideoSDK/Tmp"];
//    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:localPath];
//    for (NSString *fileName in enumerator) {
//        [[NSFileManager defaultManager] removeItemAtPath:[localPath stringByAppendingPathComponent:fileName] error:nil];
//    }
}

/* 横屏 */
- (void)updateToLandscapenRight {
    if (![RotationUtil isOrientationLandscape]) {
        [RotationUtil forceOrientation:(UIInterfaceOrientationLandscapeRight)];
    }
}

- (void)checkCreateBoard {
    
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    CGSize size = CGSizeMake(1280, 720);
    // 创建白板
    SubPage *subPage = [cloudroomVideoMeeting createBoard:@"iOS board" width:size.width height:size.height pageCount:1];
    [cloudroomVideoMeeting initBoardPageDat:subPage boardPageNo:0 imgID:@"" elemets:@""];
    //设置正确尺寸
    [self changeDrawViewSize:size];
    //保存对方创建的白板
    SubPageInfo* subPageInfo = [[SubPageInfo alloc]init];
    subPageInfo.boardID = subPage;
    subPageInfo.title = @"iOS board";
    subPageInfo.width = size.width;
    subPageInfo.height = size.height;
    subPageInfo.pageCount = 1;
    subPageInfo.curPage = 0;
    NSString* wbKey = [NSString stringWithFormat:@"%d.%d",subPage.localID,subPage.termID];
    WhiteBoardModel* wbModel = [[WhiteBoardModel alloc]init];
    wbModel.whiteBoardBaseInfo = subPageInfo;
    
    BKDrawerModel *model = [[BKDrawerModel alloc]init];
    model.curBoardSize = size;
    model.subPage = subPage;
    model.allLayerArray = [NSMutableArray array];
    model.lineW = 2;
    model.type = PENCIL;
    model.color = [UIColor redColor];
    model.currentPage = subPageInfo.curPage;
    model.imgID = @"";
    model.bkImg = nil;
    model.percent = 0;
    self.drawerView.drawerModel = model;
    
    //切换白板
    [cloudroomVideoMeeting switchToPage:MAINPAGE_WHITEBOARD subPage:subPage];
    [wbModel.whiteBoardPageInfo setObject:model forKey:[NSString stringWithFormat:@"%d",model.currentPage]];
    [self.allWhiteBoardDict setObject:wbModel forKey:wbKey];
    [self.allWhilteBoardKey addObject:wbKey];
}

- (CGSize)getRealSize:(CGSize)bwSize{
    
    int width = self.view.bounds.size.width;
    int height = self.view.bounds.size.height;
    float dw = (float) width / bwSize.width;
    float dh = (float) height / bwSize.height;
    if (dw > dh) {
        _showScale  = dh;
        width = (int) (bwSize.width * dh);
        height = height;
    } else {
        _showScale  = dw;
        width = width;
        height = (int) (bwSize.height * dw);
    }
    return CGSizeMake(width, height);
}
#pragma mark - override
- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}
@end
