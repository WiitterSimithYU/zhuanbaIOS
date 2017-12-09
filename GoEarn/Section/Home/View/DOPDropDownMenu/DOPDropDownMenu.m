//
//  DOPDropDownMenu.m
//  DOPDropDownMenuDemo
//
//  Created by weizhou on 9/26/14.
//  Copyright (c) 2014 fengweizhou. All rights reserved.
//

#import "DOPDropDownMenu.h"
#import "HomeVC.h"
@implementation DOPIndexPath
- (instancetype)initWithColumn:(NSInteger)column row:(NSInteger)row {
    self = [super init];
    if (self) {
        _column = column;
        _row = row;
    }
    return self;
}

+ (instancetype)indexPathWithCol:(NSInteger)col row:(NSInteger)row {
    DOPIndexPath *indexPath = [[self alloc] initWithColumn:col row:row];
    return indexPath;
}
@end

#pragma mark - menu implementation

static int middleClickCount =0;

static int rightClickCount =0;

@interface DOPDropDownMenu ()
{
    CAShapeLayer *_selectedMiddleShapeLayer;
    CAShapeLayer *_selectedRightShapeLayer;
}
@property(nonatomic,assign)BOOL fromHome;
@property (nonatomic, assign) NSInteger currentSelectedMenudIndex;
@property (nonatomic, assign) BOOL show;
@property (nonatomic, assign) NSInteger numOfMenu;
@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, strong) UIView *backGroundView;
@property (nonatomic, strong) UITableView *tableView;
//data source
@property (nonatomic, copy) NSArray *array;
//layers array
@property (nonatomic, copy) NSArray *titles;
@property (nonatomic, copy) NSArray *indicators;
@property (nonatomic, copy) NSArray *bgLayers;

@property(nonatomic,strong)HomeTableView  * superTab;
@end


@implementation DOPDropDownMenu

#pragma mark - getter
- (UIColor *)indicatorColor {
    if (!_indicatorColor) {
        _indicatorColor = UIColorFromRGB(0x999999);
    }
    return _indicatorColor;
}

- (UIColor *)textColor {
    if (!_textColor) {
        _textColor = UIColorFromRGB(0x4c4c4c);
    }
    return _textColor;
}

- (UIColor *)separatorColor {
    if (!_separatorColor) {
        _separatorColor = [UIColor blackColor];
    }
    return _separatorColor;
}

- (NSString *)titleForRowAtIndexPath:(DOPIndexPath *)indexPath {
    return [self.dataSource menu:self titleForRowAtIndexPath:indexPath];
}

#pragma mark - setter
- (void)setDataSource:(id<DOPDropDownMenuDataSource>)dataSource {
    _dataSource = dataSource;
    
    //configure view
    if ([_dataSource respondsToSelector:@selector(numberOfColumnsInMenu:)]) {
        _numOfMenu = [_dataSource numberOfColumnsInMenu:self];
    } else {
        _numOfMenu = 1;
    }
    
    CGFloat textLayerInterval = self.frame.size.width / ( _numOfMenu * 2);
    CGFloat bgLayerInterval = self.frame.size.width / _numOfMenu;
    
    NSMutableArray *tempTitles = [[NSMutableArray alloc] initWithCapacity:_numOfMenu];
    NSMutableArray *tempIndicators = [[NSMutableArray alloc] initWithCapacity:_numOfMenu];
    NSMutableArray *tempBgLayers = [[NSMutableArray alloc] initWithCapacity:_numOfMenu];
    
    for (int i = 0; i < _numOfMenu; i++) {
        //bgLayer
        CGPoint bgLayerPosition = CGPointMake((i+0.5)*bgLayerInterval, self.frame.size.height/2);
        CALayer *bgLayer = [self createBgLayerWithColor:[UIColor whiteColor] andPosition:bgLayerPosition];
        [self.layer addSublayer:bgLayer];
        [tempBgLayers addObject:bgLayer];
        //title
        CGPoint titlePosition = CGPointMake( (i * 2 + 0.9) * textLayerInterval , self.frame.size.height / 2);
        NSString *titleString = [_dataSource menu:self titleForRowAtIndexPath:[DOPIndexPath indexPathWithCol:i row:0]];
        CATextLayer *title = [self createTextLayerWithNSString:titleString withColor:self.textColor andPosition:titlePosition];
        [self.layer addSublayer:title];
        [tempTitles addObject:title];
        if (i ==0) {
            //indicator
            CAShapeLayer *indicator = [self createIndicatorWithColor:self.indicatorColor andPosition:CGPointMake(titlePosition.x + title.bounds.size.width / 2 + 8, self.frame.size.height / 2) isUp:NO];
            [self.layer addSublayer:indicator];
            [tempIndicators addObject:indicator];
        }else
        {
            //indicator
            CAShapeLayer *indicator1 = [self createIndicatorWithColor:self.indicatorColor andPosition:CGPointMake(titlePosition.x + title.bounds.size.width / 2 + 8, self.frame.size.height / 2 -2.5) isUp:YES];
            //三角的大小设置
            indicator1.affineTransform = CGAffineTransformMakeScale(0.7, 0.7);
            [self.layer addSublayer:indicator1];
            
            //indicator
            CAShapeLayer *indicator2 = [self createIndicatorWithColor:self.indicatorColor andPosition:CGPointMake(titlePosition.x + title.bounds.size.width / 2 + 8, self.frame.size.height / 2 +2.5) isUp:NO];
            //三角的大小设置
            indicator2.affineTransform = CGAffineTransformMakeScale(0.7, 0.7);
            [self.layer addSublayer:indicator2];
            
            [tempIndicators addObject:@[indicator1,indicator2]];
        }
    }
    _titles = [tempTitles copy];
    _indicators = [tempIndicators copy];
    _bgLayers = [tempBgLayers copy];
}

#pragma mark - init method
- (instancetype)initWithOrigin:(CGPoint)origin andHeight:(CGFloat)height fromHome:(BOOL)isHome selectedMenudIndex:(NSInteger)selectedMenudIndex superTab:(UITableView*)superTab{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    self = [self initWithFrame:CGRectMake(origin.x, origin.y, screenSize.width, height)];
    if (self) {
        _origin = origin;
        _currentSelectedMenudIndex = selectedMenudIndex;
        _show = NO;
        _fromHome = isHome;
        _superTab = (HomeTableView*)superTab;
        //tableView init
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(origin.x, self.frame.origin.y + self.frame.size.height, self.frame.size.width, 0) style:UITableViewStylePlain];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.rowHeight = 35;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        
        //self tapped
        self.backgroundColor = [UIColor whiteColor];
        UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuTapped:)];
        [self addGestureRecognizer:tapGesture];
        
        //background init and tapped
        _backGroundView = [[UIView alloc] initWithFrame:CGRectMake(origin.x, 64, screenSize.width, screenSize.height)];
        _backGroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        _backGroundView.opaque = NO;
        UIGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
        [_backGroundView addGestureRecognizer:gesture];
        
        //add bottom shadow
        UIView *bottomShadow = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height-0.5, screenSize.width, 0.5)];
        bottomShadow.backgroundColor = UIColorFromRGB(0xe1e1e6);
        [self addSubview:bottomShadow];
    }
    return self;
}

#pragma mark - init support
- (CALayer *)createBgLayerWithColor:(UIColor *)color andPosition:(CGPoint)position {
    CALayer *layer = [CALayer layer];
    layer.position = position;
    layer.bounds = CGRectMake(0, 0, self.frame.size.width/self.numOfMenu, self.frame.size.height-1);
    layer.backgroundColor = color.CGColor;

    return layer;
}

- (CAShapeLayer *)createIndicatorWithColor:(UIColor *)color andPosition:(CGPoint)point isUp:(BOOL)up {
    CAShapeLayer *layer = [CAShapeLayer new];
    
    UIBezierPath *path = [UIBezierPath new];
    [path moveToPoint:CGPointMake(0, 0)];
    
    [path addLineToPoint:CGPointMake(8, 0)];
    if (up ==YES) {
         [path addLineToPoint:CGPointMake(4, -5)];
    }else
    {
         [path addLineToPoint:CGPointMake(4, 5)];
    }
    [path closePath];
    
    layer.path = path.CGPath;
    layer.lineWidth = 1.0;
    layer.fillColor = color.CGColor;
    
    CGPathRef bound = CGPathCreateCopyByStrokingPath(layer.path, nil, layer.lineWidth, kCGLineCapButt, kCGLineJoinMiter, layer.miterLimit);
    layer.bounds = CGPathGetBoundingBox(bound);
    CGPathRelease(bound);
    
    layer.position = point;
    
    return layer;
}

- (CATextLayer *)createTextLayerWithNSString:(NSString *)string withColor:(UIColor *)color andPosition:(CGPoint)point {
    
    CGSize size = [self calculateTitleSizeWithString:string];
    
    CATextLayer *layer = [CATextLayer new];
    CGFloat sizeWidth = (size.width < (self.frame.size.width / _numOfMenu) - 25) ? size.width : self.frame.size.width / _numOfMenu - 25;
    layer.bounds = CGRectMake(0, 0, sizeWidth, size.height);
    layer.string = string;
    layer.fontSize = 14.0;
    layer.alignmentMode = kCAAlignmentCenter;
    layer.foregroundColor = color.CGColor;
    
    layer.contentsScale = [[UIScreen mainScreen] scale];
    
    layer.position = point;
    
    return layer;
}

- (CGSize)calculateTitleSizeWithString:(NSString *)string
{
    CGFloat fontSize = 14.0;
    NSDictionary *dic = @{NSFontAttributeName: [UIFont systemFontOfSize:fontSize]};
    CGSize size = [string boundingRectWithSize:CGSizeMake(280, 0) options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:dic context:nil].size;
    return size;
}

#pragma mark -  头部点击方法
- (void)menuTapped:(UITapGestureRecognizer *)paramSender {

    CGPoint touchPoint = [paramSender locationInView:self];
    //calculate index
    NSInteger tapIndex = touchPoint.x / (self.frame.size.width / _numOfMenu);
    
    for (int i = 0; i < _numOfMenu; i++) {
        if (i != tapIndex) {
            if (i ==0&&tapIndex ==0) {
                [self animateIndicator:_indicators[i] Forward:NO complete:^{
                    [self animateTitle:_titles[i] show:NO complete:^{
                        
                    }];
                }];
  
            }
            [(CALayer *)self.bgLayers[i] setBackgroundColor:[UIColor whiteColor].CGColor];
        }
    }
    
    if (tapIndex == _currentSelectedMenudIndex && _show) {
        if (tapIndex == 0) {
            [self animateIdicator:_indicators[_currentSelectedMenudIndex] background:_backGroundView tableView:_tableView title:_titles[_currentSelectedMenudIndex] forward:NO complecte:^{
                _currentSelectedMenudIndex = tapIndex;
                _show = NO;
                if ([self.delegate respondsToSelector:@selector(menu:show:)]) {
                    [self.delegate menu:self show:NO];
                }
                
            }];

        }else
        {
            [(CATextLayer *)self.titles[tapIndex] setForegroundColor:self.textColor.CGColor];
            
            NSArray *indicatorArr = self.indicators[tapIndex];
            
            [(CAShapeLayer *)indicatorArr[0] setFillColor:self.indicatorColor.CGColor];
        }
    } else {
        if (tapIndex ==0) {
            if (tapIndex >=_indicators.count) {
                return;
            }
            _currentSelectedMenudIndex = tapIndex;
            
            [_tableView reloadData];
            
            [self animateIdicator:_indicators[tapIndex] background:_backGroundView tableView:_tableView title:_titles[tapIndex] forward:YES complecte:^{
                _show = YES;
                if ([self.delegate respondsToSelector:@selector(menu:show:)]) {
                    [self.delegate menu:self show:YES];
                }
            }];
//            [(CATextLayer *)self.titles[tapIndex] setForegroundColor:UIColorFromRGB(0xff4c61).CGColor];
//            [(CAShapeLayer *)self.indicators[tapIndex] setFillColor:UIColorFromRGB(0xff4c61).CGColor];
        }else
        {
            NSArray *indicatorArr = self.indicators[tapIndex];
            if (tapIndex ==1) {
                if (middleClickCount ==2) {
                    middleClickCount =0;
                    [(CATextLayer *)self.titles[tapIndex] setForegroundColor:self.textColor.CGColor];
                    [_selectedMiddleShapeLayer setFillColor:self.indicatorColor.CGColor];
                    if ([self.delegate respondsToSelector:@selector(munu:disSelectedSort:)]) {
                        [self.delegate munu:self disSelectedSort:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d",middleClickCount],@"money",[NSString stringWithFormat:@"%d",rightClickCount],@"time", nil]];
                    }
                    return;
                }

                
                [(CATextLayer *)self.titles[tapIndex] setForegroundColor:UIColorFromRGB(0xff4c61).CGColor];
                [(CAShapeLayer *)indicatorArr[middleClickCount] setFillColor:UIColorFromRGB(0xff4c61).CGColor];
                [_selectedMiddleShapeLayer setFillColor:self.indicatorColor.CGColor];
                _selectedMiddleShapeLayer = indicatorArr[middleClickCount];
                
                middleClickCount ++;
                
            }else
            {
                if (rightClickCount ==2) {
                    rightClickCount =0;
                    [(CATextLayer *)self.titles[tapIndex] setForegroundColor:self.textColor.CGColor];
                    
                    [_selectedRightShapeLayer setFillColor:self.indicatorColor.CGColor];
                    if ([self.delegate respondsToSelector:@selector(munu:disSelectedSort:)]) {
                        [self.delegate munu:self disSelectedSort:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d",middleClickCount],@"money",[NSString stringWithFormat:@"%d",rightClickCount],@"time", nil]];
                    }
                    return;
                }

                [(CATextLayer *)self.titles[tapIndex] setForegroundColor:UIColorFromRGB(0xff4c61).CGColor];
                [(CAShapeLayer *)indicatorArr[rightClickCount] setFillColor:UIColorFromRGB(0xff4c61).CGColor];
                [_selectedRightShapeLayer setFillColor:self.indicatorColor.CGColor];
                _selectedRightShapeLayer =indicatorArr[rightClickCount];
                rightClickCount ++;
                }
            if ([self.delegate respondsToSelector:@selector(munu:disSelectedSort:)]) {
                [self.delegate munu:self disSelectedSort:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d",middleClickCount],@"money",[NSString stringWithFormat:@"%d",rightClickCount],@"time", nil]];
            }
        }
        
    }
}

- (void)backgroundTapped:(UITapGestureRecognizer *)paramSender
{
    [self animateIdicator:_indicators[_currentSelectedMenudIndex] background:_backGroundView tableView:_tableView title:_titles[_currentSelectedMenudIndex] forward:NO complecte:^{
        [(CATextLayer *)self.titles[0] setForegroundColor:self.textColor.CGColor];
        [(CAShapeLayer *)self.indicators[0] setFillColor:self.indicatorColor.CGColor];
        _show = NO;
        if ([self.delegate respondsToSelector:@selector(menu:show:)]) {
            [self.delegate menu:self show:NO];
        }
    }];
    [(CALayer *)self.bgLayers[_currentSelectedMenudIndex] setBackgroundColor:[UIColor whiteColor].CGColor];
}

#pragma mark - animation method
- (void)animateIndicator:(CAShapeLayer *)indicator Forward:(BOOL)forward complete:(void(^)())complete {
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.25];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.4 :0.0 :0.2 :1.0]];
    
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation"];
    anim.values = forward ? @[ @0, @(M_PI) ] : @[ @(M_PI), @0 ];
    
    if (!anim.removedOnCompletion) {
        [indicator addAnimation:anim forKey:anim.keyPath];
    } else {
        [indicator addAnimation:anim forKey:anim.keyPath];
        [indicator setValue:anim.values.lastObject forKeyPath:anim.keyPath];
    }
    
    [CATransaction commit];
    
    complete();
}

- (void)animateBackGroundView:(UIView *)view show:(BOOL)show complete:(void(^)())complete {
    if (show) {
        [self.superview addSubview:view];
        [view.superview addSubview:self];
        
        [UIView animateWithDuration:0.2 animations:^{
            view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        }];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        } completion:^(BOOL finished) {
            [view removeFromSuperview];
        }];
    }
    complete();
}

- (void)animateTableView:(UITableView *)tableView show:(BOOL)show complete:(void(^)())complete {
    if (show) {
        CGFloat tabMaxY = _fromHome ==YES?45+64:45;
        
        tableView.frame = CGRectMake(self.origin.x, tabMaxY, self.frame.size.width, 0);
        [self.superview addSubview:tableView];
        
        CGFloat tableViewHeight = ([tableView numberOfRowsInSection:0] > 5) ? (5 * tableView.rowHeight +8) : ([tableView numberOfRowsInSection:0] * tableView.rowHeight+8);
        
        [UIView animateWithDuration:0.4 animations:^{
            _tableView.frame = CGRectMake(self.origin.x, tabMaxY, self.frame.size.width, tableViewHeight);
        }];
    } else {
        [UIView animateWithDuration:0.1 animations:^{
            _tableView.frame = CGRectMake(self.origin.x, self.frame.origin.y + self.frame.size.height, self.frame.size.width, 0);
        } completion:^(BOOL finished) {
            [tableView removeFromSuperview];
        }];
    }
    complete();
}

- (void)animateTitle:(CATextLayer *)title show:(BOOL)show complete:(void(^)())complete {
    CGSize size = [self calculateTitleSizeWithString:title.string];
    CGFloat sizeWidth = (size.width < (self.frame.size.width / _numOfMenu) - 25) ? size.width : self.frame.size.width / _numOfMenu - 25;
    title.bounds = CGRectMake(0, 0, sizeWidth, size.height);
    complete();
}

- (void)animateIdicator:(CAShapeLayer *)indicator background:(UIView *)background tableView:(UITableView *)tableView title:(CATextLayer *)title forward:(BOOL)forward complecte:(void(^)())complete{
    
    [self animateIndicator:indicator Forward:forward complete:^{
        [self animateTitle:title show:forward complete:^{
            [(CATextLayer *)self.titles[_currentSelectedMenudIndex] setForegroundColor:UIColorFromRGB(0xff4c61).CGColor];
            [(CAShapeLayer *)self.indicators[_currentSelectedMenudIndex] setFillColor:UIColorFromRGB(0xff4c61).CGColor];
            [self animateBackGroundView:background show:forward complete:^{
                [self animateTableView:tableView show:forward complete:^{
                }];
            }];
        }];
    }];
    
    complete();
}

#pragma mark - table datasource
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 8;
}
-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 8)];
    view.backgroundColor = [UIColor whiteColor];
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSAssert(self.dataSource != nil, @"menu's dataSource shouldn't be nil");
    if ([self.dataSource respondsToSelector:@selector(menu:numberOfRowsInColumn:)]) {
        return [self.dataSource menu:self
                numberOfRowsInColumn:self.currentSelectedMenudIndex];
    } else {
        NSAssert(0 == 1, @"required method of dataSource protocol should be implemented");
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"DropDownMenuCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    NSAssert(self.dataSource != nil, @"menu's datasource shouldn't be nil");
    if ([self.dataSource respondsToSelector:@selector(menu:titleForRowAtIndexPath:)]) {
        cell.textLabel.text = [self.dataSource menu:self titleForRowAtIndexPath:[DOPIndexPath indexPathWithCol:self.currentSelectedMenudIndex row:indexPath.row]];
    } else {
        NSAssert(0 == 1, @"dataSource method needs to be implemented");
    }
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont systemFontOfSize:14.0];
    cell.textLabel.textColor = UIColorFromRGB(0x4c4c4c);
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    if ([cell.textLabel.text isEqualToString: [(CATextLayer *)[_titles objectAtIndex:_currentSelectedMenudIndex] string]]) {
        cell.backgroundColor = [UIColor clearColor];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.tintColor = UIColorFromRGB(0xff4c61);
        cell.textLabel.textColor = UIColorFromRGB(0xff4c61);
    }
    return cell;
}

#pragma mark - tableview delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self confiMenuWithSelectRow:indexPath.row];
    [(CATextLayer *)self.titles[0] setForegroundColor:self.textColor.CGColor];
    [(CAShapeLayer *)self.indicators[0] setFillColor:self.indicatorColor.CGColor];
    if (self.delegate || [self.delegate respondsToSelector:@selector(menu:didSelectRowAtIndexPath:)]) {
        [self.delegate menu:self didSelectRowAtIndexPath:[DOPIndexPath indexPathWithCol:self.currentSelectedMenudIndex row:indexPath.row]];
    }
}

- (void)confiMenuWithSelectRow:(NSInteger)row {
    
    CATextLayer *title = (CATextLayer *)_titles[_currentSelectedMenudIndex];
    title.string = [self.dataSource menu:self titleForRowAtIndexPath:[DOPIndexPath indexPathWithCol:self.currentSelectedMenudIndex row:row]];
    
    [self animateIdicator:_indicators[_currentSelectedMenudIndex] background:_backGroundView tableView:_tableView title:_titles[_currentSelectedMenudIndex] forward:NO complecte:^{
        _show = NO;
        if ([self.delegate respondsToSelector:@selector(menu:show:)]) {
            [self.delegate menu:self show:NO];
        }
    }];
    [(CALayer *)self.bgLayers[_currentSelectedMenudIndex] setBackgroundColor:[UIColor whiteColor].CGColor];
    
    CAShapeLayer *indicator = (CAShapeLayer *)_indicators[_currentSelectedMenudIndex];
    indicator.position = CGPointMake(title.position.x + title.frame.size.width / 2 + 8, indicator.position.y);
}
-(void)inintTitleLayerColor
{
    [(CATextLayer *)self.titles[0] setForegroundColor:_textColor.CGColor];
    [(CAShapeLayer *)self.indicators[0] setFillColor:_indicatorColor.CGColor];
}
- (void)dismiss {
    [self backgroundTapped:nil];
}

@end