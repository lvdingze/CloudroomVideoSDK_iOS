#import <UIKit/UIKit.h>
#import "BKShapeLayer.h"

@interface BKDrawerModel :NSObject
@property (nonatomic, assign) CGFloat lineW; /**< 线宽 */
@property (nonatomic, assign) DrawShapeType type; /**> 画笔类型 */
@property (nonatomic, assign) CGSize curBoardSize; /**< 当前白板尺寸 */
@property (nonatomic, strong) SubPage *subPage; /**< 白板信息 */
@property (nonatomic, strong) NSMutableArray *allLayerArray;
@property (nonatomic, assign) int currentPage;
@property (nonatomic, strong) UIColor* color;
@property (nonatomic, copy)  NSString* imgID;  /*当前图片id*/
@property (nonatomic, assign) NSInteger percent;/*图片进度*/
@property (nonatomic, strong) UIImage* bkImg; /*背景图片*/
@property (nonatomic, strong) NSMutableArray *allPointStringArray; /*初始化路径字符数据*/
-(void)clearData;
-(void)equal:(BKDrawerModel*) model;
@end

@class BKDrawer;
@interface BKDrawer : UIView
@property (nonatomic, strong) BKDrawerModel *drawerModel;
@property (nonatomic, assign) NSInteger localLineW;
@property (nonatomic, assign) NSInteger realW;
@property (nonatomic, assign) NSInteger realH;
@property (assign,nonatomic) CGFloat showScale;
/*绘制图元*/
- (void) draw:(NSDictionary*)element;
/*删除图元*/
-(void)deleteLine:(NSArray<NSString *> *)elementIDs;
/*撤销图元*/
-(void)redoLocalLine;
/*反撤销图元*/
-(void)undoLocalLine;
/*删除本地所有图元*/
-(void)deleteAllLine;
/*调整图元排序*/
-(void)changPathOrder;
/*绘制文档基础数据*/
-(void) drawDoc;

@end
