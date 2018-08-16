#import "BKDrawer.h"
#import <CoreGraphics/CGPath.h>
#import "MJExtension.h"
#import "BKShapeLayer.h"
#import "MBProgressHUD+MF.h"

@implementation BKDrawerModel
@end

@interface BKDrawer ()
@property (nonatomic, strong) NSMutableArray *undoLayerArray;
@property (nonatomic, strong) BKPath *localPath;/** 当前本地绘制的路径 */
@property (nonatomic, strong) BKPath *remotePath;/** 当前远端绘制的路径 */
@property (nonatomic, strong) BKShapeLayer *localLayer;
@property (nonatomic, strong) BKShapeLayer *remotelayer;
@property (nonatomic, strong) UIColor* remoteColor;
@property (nonatomic, assign) NSInteger remoteLineW;
@property (nonatomic, assign) DrawShapeType type; /**> 画笔类型 */
@end

@implementation BKDrawer
#pragma mark - life cycle
- (void)awakeFromNib {
    [super awakeFromNib];
    [self commonSetup];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    self.realW = self.bounds.size.width;
    self.realH = self.bounds.size.height;
    [self commonSetup];
    return self;
}

#pragma mark  -懒加载路径数组

-(NSMutableArray *)undoLayerArray{
    if (_undoLayerArray == nil) {
        _undoLayerArray = [NSMutableArray array];
    }
    return _undoLayerArray;
}
#pragma mark - public method
- (void) drawElement:(NSDictionary*)element{
    
    if([self.drawerModel.allLayerArray count] == 100)
    {
        [MBProgressHUD showMessage:@"一页最多画100个图元"];
        return;
    }
    NSInteger type = [[element objectForKey:@"type"] integerValue];
    NSInteger left = [[element objectForKey:@"left"] integerValue];
    NSInteger top = [[element objectForKey:@"top"] integerValue];
    NSString* elementID = [element objectForKey:@"elementID"];
    NSInteger lineW = [[element objectForKey:@"pixel"] integerValue];
    long long argb = [[element objectForKey:@"color"] longLongValue];
    
    int clra = argb>>24;
    int clrr = argb>>16 & 0xFF;
    int clrg = argb>>8 &0xFF;
    int clrb = argb & 0xFF;
    
    _remoteColor = [UIColor colorWithRed:clrr / 255.0 green:clrg/255.0 blue:clrb/255.0 alpha:clra/255.0];
    _remoteLineW = lineW;
    /* 数据结构: <x, y, x, y, x, y, ...> */
    NSMutableArray<NSNumber *> *dstPoints = [NSMutableArray array];
    switch (type) {
        case PENCIL:
        {
            NSArray *srcPoints = [element objectForKey:@"dot"];
            for (NSDictionary *point in srcPoints) {
                [dstPoints addObject:@([[point objectForKey:@"x"] integerValue] + left)];
                [dstPoints addObject:@([[point objectForKey:@"y"] integerValue] + top)];
            }
        }
            break;
        case LINE:
        {
            NSString *line = [element objectForKey:@"line"];
            NSDictionary *lineDict = [line mj_JSONObject];
            NSInteger x1 = [[lineDict objectForKey:@"x1"] integerValue];
            NSInteger x2 = [[lineDict objectForKey:@"x2"] integerValue];
            NSInteger y1 = [[lineDict objectForKey:@"y1"] integerValue];
            NSInteger y2 = [[lineDict objectForKey:@"y2"] integerValue];
            
            [dstPoints addObject:@(x1 + left)];
            [dstPoints addObject:@(y1 + top)];
            [dstPoints addObject:@(x2 + left)];
            [dstPoints addObject:@(y2 + top)];
            
        }
            break;
        case HOLLRECT:
        {
            NSString *rect = [element objectForKey:@"rect"];
            [self drawRect:elementID rectInfo:rect left:left top:top];
        }
            break;
    }
    if (dstPoints.count > 0) {
        [self drawLine:elementID points:[dstPoints copy]];
    }
}

/* 画线 */
- (void)drawLine:(NSString *)elementID points:(NSArray<NSNumber *> *)points{
    // 3. 解析画笔点数
    NSUInteger count = [points count];
    if (count < 1) {
        return;
    }
    if (self.drawerModel.curBoardSize.width == 0 || self.drawerModel.curBoardSize.height == 0) {
        return;
    }
    // 4. 解析画笔单点
    for (int i = 0; i < count; i = i + 2) {
        NSInteger x = [[points objectAtIndex:i] integerValue];
        NSInteger y = [[points objectAtIndex:(i + 1)] integerValue];
        
        NSInteger trueX = self.realW / self.drawerModel.curBoardSize.width * x;
        NSInteger trueY = self.realH / self.drawerModel.curBoardSize.height * y;
        
        if (i == 0) { // 开始
            [self drawBegin:(CGPoint){(CGFloat)trueX, (CGFloat)trueY} elementID:(elementID)];

        } else {
            [self drawMove:(CGPoint){(CGFloat)trueX, (CGFloat)trueY}];
        }
    }
}

- (void)drawRect:(NSString *)elementID rectInfo:(NSString*)rectInfo left:(NSInteger)left top:(NSInteger)top{
    
    NSDictionary *lineDict = [rectInfo mj_JSONObject];
    NSInteger x = [[lineDict objectForKey:@"x"] integerValue] + left ;
    NSInteger y = [[lineDict objectForKey:@"y"] integerValue] + top;
    NSInteger width = [[lineDict objectForKey:@"width"] integerValue];
    NSInteger height = [[lineDict objectForKey:@"height"] integerValue];
    
    float scaleX = self.bounds.size.width / self.drawerModel.curBoardSize.width  ;
    float scaleY = self.bounds.size.height / self.drawerModel.curBoardSize.height ;
    
    CGRect rect = CGRectMake(x*scaleX, y*scaleY, width*scaleX, height*scaleY);
    CGPathRef path = CGPathCreateWithRect(rect,nil);
    
    BKShapeLayer *slayer = [BKShapeLayer layer];
    slayer.path = path;
    slayer.backgroundColor = [UIColor clearColor].CGColor;
    slayer.fillColor = [UIColor clearColor].CGColor;
    
    slayer.strokeColor = _remoteColor.CGColor;
    slayer.lineWidth = _remoteLineW;
    
    slayer.lineCap = kCALineCapRound;
    slayer.lineJoin = kCALineJoinRound;
    slayer.elementID = elementID;
    
    [self.layer addSublayer:slayer];
    _remotelayer = slayer;
   
    [self.drawerModel.allLayerArray addObject:_remotelayer];
    
}
/*删除一条线*/
-(void)deleteLine:(NSArray<NSString *> *)elementIDs{
    
    [elementIDs enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString* elementID = (NSString*)obj;
        [self.drawerModel.allLayerArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            BKShapeLayer *layer = (BKShapeLayer*)obj;
            if([layer.elementID isEqualToString:elementID])
            {
                [layer removeFromSuperlayer];
                [self.drawerModel.allLayerArray removeObject:layer];
                //            *stop = YES;
                NSLog(@"delete line");
            }
        }];
        
    }];
}
/*撤消*/
-(void)redoLocalLine{
    
    for (NSInteger i = [self.drawerModel.allLayerArray count] -1; i >=0 ; i--) {
        BKShapeLayer *layer = self.drawerModel.allLayerArray[i];
        if(layer != nil && layer.bLocal)
        {
            //远端删除
            CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
            [cloudroomVideoMeeting delBoardElement:self.drawerModel.subPage boardPageNo:0 elementIDs:[NSArray arrayWithObject:layer.elementID]];
            [self.undoLayerArray addObject:layer];
            break;
        }
    }
}
/*反撤消*/
-(void)undoLocalLine{

    BKShapeLayer *layer = self.undoLayerArray.lastObject;
    if(layer != nil)
    {
        [self.drawerModel.allLayerArray addObject:layer];
        [self.layer addSublayer:layer];
        [self.undoLayerArray removeObject:layer];
        //远端添加
        CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
        // 添加白板图元
        NSString *element = [self createBoardElement:layer.points elementID:layer.elementID];
        [cloudroomVideoMeeting addBoardElement:self.drawerModel.subPage boardPageNo:0 elementData:element];
    }
}

-(void)deleteAllLine{
    
    NSMutableArray* elementIDs = [NSMutableArray array];
    [self.drawerModel.allLayerArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BKShapeLayer* layer = (BKShapeLayer*)obj;
        [elementIDs addObject:layer.elementID];
    }];
    //远端删除
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    [cloudroomVideoMeeting delBoardElement:self.drawerModel.subPage boardPageNo:self.drawerModel.currentPage elementIDs:elementIDs];
    [self.undoLayerArray removeAllObjects];
}

-(void)changPathOrder{
    
    BKShapeLayer* layer =  self.drawerModel.allLayerArray.lastObject;
    BKShapeLayer* tLayer= _localLayer;
    if(layer != _localLayer)
    {
        [self.drawerModel.allLayerArray removeObject:_localLayer];
        [self.drawerModel.allLayerArray addObject:tLayer];
    }
}

-(NSString*)getWhileBoardImgPath:(SubPage*)subPage pageNo:(int)pageNo{
    
    NSString* wbKey = [NSString stringWithFormat:@"%d.%d",subPage.localID,subPage.termID];
    NSString *libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    NSString *localPath = [libraryDir stringByAppendingPathComponent:[NSString stringWithFormat:@"Caches/CloudroomVideoSDK/Tmp/%@_%d",wbKey,pageNo]];
    return  localPath;
}

-(void) drawDoc{
    
    if(![self.drawerModel.imgID isEqualToString:@""])
    {
        if(self.drawerModel.bkImg == nil && self.drawerModel.percent == 100)
        {
            NSString *imgPath =  [self getWhileBoardImgPath:self.drawerModel.subPage pageNo:self.drawerModel.currentPage];
            //绘制
            NSData *imageData;
            imageData = [NSData dataWithContentsOfFile: imgPath];
            NSUInteger length = [imageData length];
            NSData *content = [imageData subdataWithRange:NSMakeRange(14, length - 14)];//取得内容
            UIImage* img = [UIImage imageWithData:content];
            self.drawerModel.bkImg = img;
            [self.layer setContents:img.CGImage];
        }
        else{
            [self.layer setContents:self.drawerModel.bkImg.CGImage];
        }
    }
    
    
    [self.drawerModel.allLayerArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

        BKShapeLayer* layer = (BKShapeLayer*)obj;
        [self.layer addSublayer:layer];

    }];
    
    [self.drawerModel.allPointStringArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSDictionary *element = (NSDictionary*)obj;
        [self drawElement:element];
        
    }];
    
    [self.drawerModel.allPointStringArray removeAllObjects];
  
}

#pragma mark - private method
- (void)commonSetup {
    self.drawerModel.lineW = 2.0;
    self.drawerModel.type = PENCIL;
    [self setBackgroundColor:[UIColor whiteColor]];
    
    self.clipsToBounds = YES;
    _localLineW = 2;
    _remoteLineW = 2;
    _type = PENCIL;
    _showScale = 1.0f;
}

/* 获取当前触摸点 */
- (CGPoint)_cPointWithTouches:(NSSet *)touches {
    UITouch *touch = [touches anyObject];
    
    return [touch locationInView:self];
}

/* 获取上一个触摸点 */
- (CGPoint)_pPointWithTouches:(NSSet *)touches {
    UITouch *touch = [touches anyObject];
    
    return [touch previousLocationInView:self];
}

/* 获取中间触摸点 */
- (CGPoint)_midPoint:(CGPoint)prePoint curPoint:(CGPoint)curPoint {
    return CGPointMake((prePoint.x + curPoint.x) * 0.5, (prePoint.y + curPoint.y) * 0.5);
}

- (void)draw:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    if(_localPath == nil)
        return;
    if ([event allTouches].count == 1) {
        CGPoint curPoint = [self _cPointWithTouches:touches];
        CGPoint prePoint = [self _pPointWithTouches:touches];
        CGPoint midPoint = [self _midPoint:prePoint curPoint:curPoint];
        
        [_localLayer.points addObject:NSStringFromCGPoint(curPoint)];
        
        switch (_localPath.type) {
            case PENCIL: { // 笔画
                [_localPath addQuadCurveToPoint:midPoint controlPoint:prePoint];
                _localLayer.path = _localPath.CGPath;
                break;
            }
            case LINE: {  // 直线
                [_localPath removeAllPoints];
                CGPoint sPoint = CGPointFromString(_localLayer.points.firstObject);
                CGPoint ePoint = CGPointFromString(_localLayer.points.lastObject);
                [_localPath moveToPoint:sPoint];
                [_localPath addLineToPoint:ePoint];
                _localLayer.path = _localPath.CGPath;
                break;
            }
            case HOLLRECT: {  // 矩形
                CGPoint sPoint = CGPointFromString(_localLayer.points.firstObject);
                CGPoint ePoint = CGPointFromString(_localLayer.points.lastObject);
                CGFloat width = fabs(sPoint.x - ePoint.x);
                CGFloat height = fabs(sPoint.y - ePoint.y);
                CGPathRef path = CGPathCreateWithRect((CGRect){sPoint.x > ePoint.x ? (int)ePoint.x : (int)sPoint.x,
                    sPoint.y > ePoint.y ? (int)ePoint.y : (int)sPoint.y,
                    width, height}, nil);
                _localPath.CGPath = path;
                _localLayer.path = _localPath.CGPath;
                CGPathRelease(path);
                break;
            }
            default:
                break;
        }
    }
}

- (void)drawBegin:(CGPoint)point elementID:(NSString*)elementID{

    BKPath *path = [BKPath pathWithWidth:(self.remoteLineW * _showScale) sPoint:point type:_type];
    _remotePath = path;

    BKShapeLayer *slayer = [BKShapeLayer layer];
    slayer.path = path.CGPath;
    slayer.backgroundColor = [UIColor clearColor].CGColor;
    slayer.fillColor = [UIColor clearColor].CGColor;
    
    slayer.strokeColor = _remoteColor.CGColor;
    slayer.lineWidth = path.lineWidth;
    
    slayer.lineCap = kCALineCapRound;
    slayer.lineJoin = kCALineJoinRound;
    slayer.elementID = elementID;
    slayer.bLocal = NO;
    [slayer.points addObject:NSStringFromCGPoint(point)];
    [self.layer addSublayer:slayer];
    _remotelayer = slayer;
    [self.drawerModel.allLayerArray addObject:slayer];

}

- (void)drawMove:(CGPoint)point {
    [_remotelayer.points addObject:NSStringFromCGPoint(point)];
    [_remotePath addQuadCurveToPoint:point controlPoint:point];
    _remotelayer.path = _remotePath.CGPath;
}

/*本地绘制点集转换*/
- (NSString *)createBoardElement:(NSArray<NSString *> *)points elementID:(NSString*)elementID {
    if (self.drawerModel.curBoardSize.width == 0 || self.drawerModel.curBoardSize.height == 0) {
        return nil;
    }
    
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    CGSize localSize = self.bounds.size;
    NSMutableArray *dot = [NSMutableArray array];
    CGPoint startP = CGPointZero;
    
    if (points.count >= 1) {
        startP = CGPointFromString([points firstObject]);
    }
    
    NSInteger left = (NSInteger)(startP.x * (self.drawerModel.curBoardSize.width / (localSize.width * 1.0)));
    NSInteger top = (NSInteger)(startP.y * (self.drawerModel.curBoardSize.height / (localSize.height * 1.0)));
    
    for (NSString *pointStr in points) {
        CGPoint point = CGPointFromString(pointStr);
        NSInteger trueX = (point.x - startP.x) * (self.drawerModel.curBoardSize.width / (localSize.width * 1.0));
        NSInteger trueY = (point.y - startP.y) * (self.drawerModel.curBoardSize.height / (localSize.height * 1.0));
        [dot addObject:@{@"x" : @(trueX), @"y" : @(trueY)}];
    }
    //elementID为空表示本地绘制
    if(elementID == nil)
    {
        elementID = [cloudroomVideoMeeting createElementID];
        //设置本地绘制的id
        _localLayer.elementID = elementID;
    }
    
    NSDictionary *colorDict = [self getRGBDictionaryByColor:self.drawerModel.color];
    long long int r = [[colorDict objectForKey:@"R"] floatValue] *255.0;
    long long int g = [[colorDict objectForKey:@"G"] floatValue] *255.0;
    long long int b= [[colorDict objectForKey:@"B"] floatValue] *255.0;
    long long int a = [[colorDict objectForKey:@"A"] floatValue] * 255.0;
    
    long long  argb = a<<24|r<<16|g<<8|b;
    
    NSDictionary *element = @{@"color" : @(argb),
                              @"dot" : dot,
                              @"elementID" : elementID,
                              @"left" : @(left),
                              @"orderID" : @(1002),
                              @"pixel" : @(_localLineW),
                              @"style" : @(1),
                              @"top" : @(top),
                              @"type" : @(4)};
    return [element mj_JSONString];
}

#pragma mark - override
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    if([self.drawerModel.allLayerArray count] == 100)
    {
        [MBProgressHUD showMessage:@"一页最多画100个图元"];
        _localPath = nil;
        return;
    }
    CGPoint startP = [self _cPointWithTouches:touches];
    if ([event allTouches].count == 1) {
        CGFloat scale = [UIScreen mainScreen].scale;
        BKPath *path = [BKPath pathWithWidth:(_localLineW*_showScale) sPoint:startP type:_type];
        _localPath = path;
        
        BKShapeLayer *slayer = [BKShapeLayer layer];
        slayer.path = path.CGPath;
        slayer.backgroundColor = [UIColor clearColor].CGColor;
        slayer.fillColor = [UIColor clearColor].CGColor;
        
        slayer.strokeColor = self.drawerModel.color.CGColor;
        slayer.lineWidth = path.lineWidth;
        
        slayer.lineCap = kCALineCapRound;
        slayer.lineJoin = kCALineJoinRound;
        
        slayer.bLocal = YES;
        
        [self.layer addSublayer:slayer];
        _localLayer = slayer;
        [self.drawerModel.allLayerArray addObject:slayer];
        [self.undoLayerArray removeAllObjects];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //限制一笔最多600个点
    if([_localLayer.points count] >= 600)
    {
        [MBProgressHUD showMessage:@"一笔最多绘制600个点"];
        return;
    }
    [self draw:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    if(_localPath == nil)
        return;
    //[self draw:touches withEvent:event];
    //绘制直线
    CloudroomVideoMeeting *cloudroomVideoMeeting = [CloudroomVideoMeeting shareInstance];
    // 添加白板图元
    NSString *element = [self createBoardElement:_localLayer.points elementID:nil];
  
    [cloudroomVideoMeeting addBoardElement:self.drawerModel.subPage boardPageNo:self.drawerModel.currentPage elementData:element];
    
}
-(void)setDrawerModel:(BKDrawerModel *)drawerModel{
    
    _drawerModel = drawerModel;
    //清空数据
    [self.undoLayerArray removeAllObjects];
    //清空本地所有的图层
    NSInteger count = [self.layer.sublayers count];
    for (NSInteger i = 0; i<count; i++) {
        CALayer* layer = self.layer.sublayers[0];
        [layer removeFromSuperlayer];
    }
 
    if([drawerModel.imgID isEqualToString:@""])
    {
        UIImage *img = [UIImage imageNamed:@""];
        [self.layer setContents:img.CGImage];
        [self drawDoc];
        
    }else{
        
        if(drawerModel.percent < 100 && ![drawerModel.imgID isEqualToString:@""])
        {
            [HUDUtil hudShowProgress:@"正在下载..." animated:YES];
            NSLog(@"loading: %@",self.drawerModel.imgID);
        }
        //监听下载进度
        [self.drawerModel  addObserver:self forKeyPath:@"percent" options:NSKeyValueObservingOptionNew context:nil];
    }
    
}

#pragma arguments - Observer
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if([keyPath isEqualToString:@"percent"] && object == self.drawerModel)
    {
        NSLog(@"Observer %ld",(long)self.drawerModel.percent);
        if(self.drawerModel.percent == 100)
        {
            [HUDUtil hudHiddenProgress:YES];
            NSLog(@"download finish: %@",self.drawerModel.imgID);
            [self drawDoc];
        }
    }

}


#pragma arguments  -color change
- (NSDictionary *)getRGBDictionaryByColor:(UIColor *)originColor
{
    CGFloat r=0,g=0,b=0,a=0;
    if ([self respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
        [originColor getRed:&r green:&g blue:&b alpha:&a];
    }
    else {
        const CGFloat *components = CGColorGetComponents(originColor.CGColor);
        r = components[0];
        g = components[1];
        b = components[2];
        a = components[3];
    }
    return @{@"R":@(r),@"G":@(g),@"B":@(b),@"A":@(a)};
}
@end
