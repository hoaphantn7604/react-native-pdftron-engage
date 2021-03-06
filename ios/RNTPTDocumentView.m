#import "RNTPTDocumentView.h"

#import "RNTPTDocumentViewController.h"
#import "RNTPTCollaborationDocumentViewController.h"
#import "CPTDocumentViewSettingsController.h"

NS_ASSUME_NONNULL_BEGIN

@interface RNTPTDocumentView () <RNTPTDocumentViewControllerDelegate, PTCollaborationServerCommunication>

@property (nonatomic, nullable) PTDocumentViewController *documentViewController;

@property (nonatomic, readonly, nullable) PTPDFViewCtrl *pdfViewCtrl;
@property (nonatomic, readonly, nullable) PTToolManager *toolManager;

@property (nonatomic, readonly, nullable) RNTPTDocumentViewController *rnt_documentViewController;

@property (nonatomic, readonly, nullable) RNTPTCollaborationDocumentViewController *rnt_collabDocumentViewController;

@property (nonatomic, assign) BOOL needsCustomHeadersUpdate;

@end

NS_ASSUME_NONNULL_END

@implementation RNTPTDocumentView

- (void)RNTPTDocumentView_commonInit
{
    _topToolbarEnabled = YES;
    _bottomToolbarEnabled = YES;
    
    _pageIndicatorEnabled = YES;
    _pageIndicatorShowsOnPageChange = YES;
    _pageIndicatorShowsWithControls = YES;
    
    _autoSaveEnabled = YES;
    
    _pageChangeOnTap = NO;
    _thumbnailViewEditingEnabled = YES;
}

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self RNTPTDocumentView_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self RNTPTDocumentView_commonInit];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)didMoveToWindow
{
    if (self.window) {
        if ([self.delegate respondsToSelector:@selector(documentViewAttachedToWindow:)]) {
            [self.delegate documentViewAttachedToWindow:self];
        }
        
        [self loadDocumentViewController];
    } else {
        if ([self.delegate respondsToSelector:@selector(documentViewDetachedFromWindow:)]) {
            [self.delegate documentViewDetachedFromWindow:self];
        }
    }
}

- (void)didMoveToSuperview
{
    if (!self.superview) {
        [self unloadDocumentViewController];
    }
}

#pragma mark - DocumentViewController

- (RNTPTDocumentViewController *)rnt_documentViewController
{
    if ([self.documentViewController isKindOfClass:[RNTPTDocumentViewController class]]) {
        return (RNTPTDocumentViewController *)self.documentViewController;
    }
    return nil;
}

- (RNTPTCollaborationDocumentViewController *)rnt_collabDocumentViewController
{
    if ([self.documentViewController isKindOfClass:[RNTPTCollaborationDocumentViewController class]]) {
        return (RNTPTCollaborationDocumentViewController *)self.documentViewController;
    }
    return nil;
}

#pragma mark - Convenience

- (nullable PTPDFViewCtrl *)pdfViewCtrl
{
    return self.documentViewController.pdfViewCtrl;
}

- (nullable PTToolManager *)toolManager
{
    return self.documentViewController.toolManager;
}

#pragma mark - DocumentViewController loading

- (void)loadDocumentViewController
{
    if (!self.documentViewController) {
        if ([self isCollabEnabled]) {
            self.documentViewController = [[RNTPTCollaborationDocumentViewController alloc] initWithCollaborationService:self];
        } else {
            self.documentViewController = [[RNTPTDocumentViewController alloc] init];
        }
        self.documentViewController.delegate = self;
        
        [self applyViewerSettings];
    }
    
    [self registerForDocumentViewControllerNotifications];
    [self registerForPDFViewCtrlNotifications];
    
    // Check if document view controller has already been added to a navigation controller.
    if (self.documentViewController.navigationController) {
        return;
    }
    
    // Find the view's containing UIViewController.
    UIViewController *parentController = [self findParentViewController];
    if (parentController == nil || self.window == nil) {
        return;
    }
    
    if (self.showNavButton) {
        UIImage *navImage = [UIImage imageNamed:self.navButtonPath];
        UIBarButtonItem *navButton = [[UIBarButtonItem alloc] initWithImage:navImage
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(navButtonClicked)];
        self.documentViewController.navigationItem.leftBarButtonItem = navButton;
    }
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.documentViewController];
    
    const BOOL translucent = self.documentViewController.hidesControlsOnTap;
    navigationController.navigationBar.translucent = translucent;
    self.documentViewController.thumbnailSliderController.toolbar.translucent = translucent;
    
    UIView *controllerView = navigationController.view;
    
    // View controller containment.
    [parentController addChildViewController:navigationController];
    
    controllerView.frame = self.bounds;
    controllerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self addSubview:controllerView];
    
    [navigationController didMoveToParentViewController:parentController];
    
    navigationController.navigationBarHidden = !self.topToolbarEnabled;
    
    if (![self isBase64String]) {
        // Open a file URL.
        NSURL *fileURL = [[NSBundle mainBundle] URLForResource:self.document withExtension:@"pdf"];
        if ([self.document containsString:@"://"]) {
            fileURL = [NSURL URLWithString:self.document];
        } else if ([self.document hasPrefix:@"/"]) {
            fileURL = [NSURL fileURLWithPath:self.document];
        }
        
        [self.documentViewController openDocumentWithURL:fileURL
                                                password:self.password];
        
          [PTOverrides overrideClass:[PTDocumentViewSettingsController class] withClass:[CPTDocumentViewSettingsController class]];
        [self applyLayoutMode];
    } else {
        NSData *data = [[NSData alloc] initWithBase64EncodedString:self.document options:0];
        
        PTPDFDoc *doc = nil;
        @try {
            doc = [[PTPDFDoc alloc] initWithBuf:data buf_size:data.length];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@, %@", exception.name, exception.reason);
            return;
        }
        
        [self.documentViewController openDocumentWithPDFDoc:doc];
        
          [PTOverrides overrideClass:[PTDocumentViewSettingsController class] withClass:[CPTDocumentViewSettingsController class]];
        [self applyLayoutMode];
    }
}

- (void)unloadDocumentViewController
{
    [self deregisterForPDFViewCtrlNotifications];
    
    UINavigationController *navigationController = self.documentViewController.navigationController;
    if (navigationController) {
        // Clear navigation stack (PTDocumentViewController).
        navigationController.viewControllers = @[];
        
        // Remove from parent view controller.
        [navigationController willMoveToParentViewController:nil];
        [navigationController.view removeFromSuperview];
        [navigationController removeFromParentViewController];
    }
}

#pragma mark Notifications

- (void)registerForDocumentViewControllerNotifications
{
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center addObserver:self
               selector:@selector(documentViewControllerDidOpenDocumentWithNotification:)
                   name:PTDocumentViewControllerDidOpenDocumentNotification
                 object:self.documentViewController];
}

- (void)registerForPDFViewCtrlNotifications
{
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center addObserver:self
               selector:@selector(pdfViewCtrlDidChangePageWithNotification:)
                   name:PTPDFViewCtrlPageDidChangeNotification
                 object:self.documentViewController.pdfViewCtrl];
    
    [center addObserver:self
               selector:@selector(toolManagerDidAddAnnotationWithNotification:)
                   name:PTToolManagerAnnotationAddedNotification
                 object:self.documentViewController.toolManager];
    
    [center addObserver:self
               selector:@selector(toolManagerDidModifyAnnotationWithNotification:)
                   name:PTToolManagerAnnotationModifiedNotification
                 object:self.documentViewController.toolManager];
    
    [center addObserver:self
               selector:@selector(toolManagerDidRemoveAnnotationWithNotification:)
                   name:PTToolManagerAnnotationRemovedNotification
                 object:self.documentViewController.toolManager];
}

- (void)deregisterForPDFViewCtrlNotifications
{
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center removeObserver:self
                      name:PTPDFViewCtrlPageDidChangeNotification
                    object:self.documentViewController.pdfViewCtrl];
    
    [center removeObserver:self
                      name:PTToolManagerAnnotationAddedNotification
                    object:self.documentViewController.toolManager];
    
    [center removeObserver:self
                      name:PTToolManagerAnnotationModifiedNotification
                    object:self.documentViewController.toolManager];
    
    [center removeObserver:self
                      name:PTToolManagerAnnotationRemovedNotification
                    object:self.documentViewController.toolManager];
}

#pragma mark - Disabling elements

- (int)getPageCount
{
    return self.documentViewController.pdfViewCtrl.pageCount;
}

- (void)setDisabledElements:(NSArray<NSString *> *)disabledElements
{
    _disabledElements = [disabledElements copy];
    
    if (self.documentViewController) {
        [self disableElementsInternal:disabledElements];
    }
}

- (void)disableElementsInternal:(NSArray<NSString*> *)disabledElements
{
    typedef void (^HideElementBlock)(void);
    
    
    NSDictionary *hideElementActions = @{
        @"exportButtonItem":
          ^{
              self.documentViewController.exportButtonHidden = YES;
          },
        @"addPagesButtonHidden":
           ^{
               self.documentViewController.addPagesButtonHidden = YES;
           },
        @"toolsButton":
            ^{
                self.documentViewController.annotationToolbarButtonHidden = YES;
            },
        @"searchButton":
            ^{
                self.documentViewController.searchButtonHidden = YES;
            },
        @"shareButton":
            ^{
                self.documentViewController.shareButtonHidden = YES;
            },
        @"viewControlsButton":
            ^{
                self.documentViewController.viewerSettingsButtonHidden = YES;
            },
        @"thumbnailsButton":
            ^{
                self.documentViewController.thumbnailBrowserButtonHidden = YES;
            },
        @"listsButton":
            ^{
                self.documentViewController.navigationListsButtonHidden = YES;
            },
        @"moreItemsButton":
            ^{
                self.documentViewController.moreItemsButtonHidden = YES;
            },
        
        @"thumbnailSlider":
            ^{
                self.documentViewController.thumbnailSliderHidden = YES;
            },
        
        @"outlineListButton":
            ^{
                self.documentViewController.outlineListHidden = YES;
            },
        @"annotationListButton":
            ^{
                self.documentViewController.annotationListHidden = YES;
            },
        @"userBookmarkListButton":
            ^{
                self.documentViewController.bookmarkListHidden = YES;
            },
        @"reflowButton":
            ^{
                self.documentViewController.readerModeButtonHidden = YES;
            },
    };
    
    for (NSObject *item in disabledElements) {
        if ([item isKindOfClass:[NSString class]]) {
            HideElementBlock block = hideElementActions[item];
            if (block) {
                block();
            }
        }
    }
    
    // Disable the elements' corresponding tools/annotation types creation.
    [self setToolsPermission:disabledElements toValue:NO];
}

#pragma mark - Disabled tools

- (void)setDisabledTools:(NSArray<NSString *> *)disabledTools
{
    _disabledTools = [disabledTools copy];
    
    if (self.documentViewController) {
        [self setToolsPermission:disabledTools toValue:NO];
    }
}

- (void)setToolsPermission:(NSArray<NSString *> *)stringsArray toValue:(BOOL)value
{
    // TODO: AnnotationCreateDistanceMeasurement
    // AnnotationCreatePerimeterMeasurement
    // AnnotationCreateAreaMeasurement
    
    for (NSObject *item in stringsArray) {
        if ([item isKindOfClass:[NSString class]]) {
            NSString *string = (NSString *)item;
            
            if ([string isEqualToString:@"AnnotationEdit"]) {
                // multi-select not implemented
            }
            else if ([string isEqualToString:@"AnnotationCreateSticky"] ||
                     [string isEqualToString:@"stickyToolButton"]) {
                self.toolManager.textAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateFreeHand"] ||
                     [string isEqualToString:@"freeHandToolButton"]) {
                self.toolManager.inkAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"TextSelect"]) {
                self.toolManager.textSelectionEnabled = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateTextHighlight"] ||
                     [string isEqualToString:@"highlightToolButton"]) {
                self.toolManager.highlightAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateTextUnderline"] ||
                     [string isEqualToString:@"underlineToolButton"]) {
                self.toolManager.underlineAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateTextSquiggly"] ||
                     [string isEqualToString:@"squigglyToolButton"]) {
                self.toolManager.squigglyAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateTextStrikeout"] ||
                     [string isEqualToString:@"strikeoutToolButton"]) {
                self.toolManager.strikeOutAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateFreeText"] ||
                     [string isEqualToString:@"freeTextToolButton"]) {
                self.toolManager.freeTextAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateCallout"] ||
                     [string isEqualToString:@"calloutToolButton"]) {
                // not supported
            }
            else if ([string isEqualToString:@"AnnotationCreateSignature"] ||
                     [string isEqualToString:@"signatureToolButton"]) {
                self.toolManager.signatureAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateLine"] ||
                     [string isEqualToString:@"lineToolButton"]) {
                self.toolManager.lineAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateArrow"] ||
                     [string isEqualToString:@"arrowToolButton"]) {
                self.toolManager.arrowAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreatePolyline"] ||
                     [string isEqualToString:@"polylineToolButton"]) {
                self.toolManager.polylineAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateStamp"] ||
                     [string isEqualToString:@"stampToolButton"]) {
                self.toolManager.stampAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateRectangle"] ||
                     [string isEqualToString:@"rectangleToolButton"]) {
                self.toolManager.squareAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateEllipse"] ||
                     [string isEqualToString:@"ellipseToolButton"]) {
                self.toolManager.circleAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreatePolygon"] ||
                     [string isEqualToString:@"polygonToolButton"]) {
                self.toolManager.polygonAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreatePolygonCloud"] ||
                     [string isEqualToString:@"cloudToolButton"]) {
                self.toolManager.cloudyAnnotationOptions.canCreate = value;
            }
            else if ([string isEqualToString:@"AnnotationCreateFileAttachment"]) {
                self.toolManager.fileAttachmentAnnotationOptions.canCreate = value;
            }
        }
    }
}

- (void)setToolMode:(NSString *)toolMode
{
    if (toolMode.length == 0) {
        return;
    }
    
    Class toolClass = Nil;
    
    if( [toolMode isEqualToString:@"AnnotationEdit"] )
    {
        // multi-select not implemented
    }
    else if( [toolMode isEqualToString:@"AnnotationCreateSticky"])
    {
        toolClass = [PTStickyNoteCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateFreeHand"])
    {
        toolClass = [PTFreeHandCreate class];
    }
    else if ( [toolMode isEqualToString:@"TextSelect"] )
    {
        toolClass = [PTTextSelectTool class];
    }
    else if ( [toolMode isEqualToString:@"Pan"] )
    {
        toolClass = [PTPanTool class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateTextHighlight"])
    {
        toolClass = [PTTextHighlightCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateTextUnderline"])
    {
        toolClass = [PTTextUnderlineCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateTextSquiggly"])
    {
        toolClass = [PTTextSquigglyCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateTextStrikeout"])
    {
        toolClass = [PTTextStrikeoutCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateFreeText"])
    {
        toolClass = [PTFreeTextCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateCallout"])
    {
        // not supported
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateSignature"])
    {
        toolClass = [PTDigitalSignatureTool class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateLine"])
    {
        toolClass = [PTLineCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateArrow"])
    {
        toolClass = [PTArrowCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreatePolyline"])
    {
        toolClass = [PTPolylineCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateStamp"])
    {
        // not implemented
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateRectangle"])
    {
        toolClass = [PTRectangleCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreateEllipse"])
    {
        toolClass = [PTEllipseCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreatePolygon"])
    {
        toolClass = [PTPolygonCreate class];
    }
    else if ( [toolMode isEqualToString:@"AnnotationCreatePolygonCloud"])
    {
        toolClass = [PTCloudCreate class];
    }
    
    if (toolClass) {
        [self.documentViewController.toolManager changeTool:toolClass];
    }
}

- (BOOL)commitTool
{
    if ([self.toolManager.tool respondsToSelector:@selector(commitAnnotation)]) {
        [self.toolManager.tool performSelector:@selector(commitAnnotation)];
        
        [self.toolManager changeTool:[PTPanTool class]];
        
        return YES;
    }
    
    return NO;
}

- (void)setPageNumber:(int)pageNumber
{
    if (_pageNumber == pageNumber) {
        // No change.
        return;
    }
    
    BOOL success = NO;
    @try {
        success = [self.documentViewController.pdfViewCtrl SetCurrentPage:pageNumber];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        success = NO;
    }
    
    if (success) {
        _pageNumber = pageNumber;
    } else {
        NSLog(@"Failed to set current page number");
    }
}

#pragma mark - Annotation import/export

- (PTAnnot *)findAnnotWithUniqueID:(NSString *)uniqueID onPageNumber:(int)pageNumber
{
    if (uniqueID.length == 0 || pageNumber < 1) {
        return nil;
    }
    PTPDFViewCtrl *pdfViewCtrl = self.documentViewController.pdfViewCtrl;
    
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        NSArray<PTAnnot *> *annots = [pdfViewCtrl GetAnnotationsOnPage:pageNumber];
        for (PTAnnot *annot in annots) {
            if (![annot IsValid]) {
                continue;
            }
            
            // Check if the annot's unique ID matches.
            NSString *annotUniqueId = nil;
            PTObj *annotUniqueIdObj = [annot GetUniqueID];
            if ([annotUniqueIdObj IsValid]) {
                annotUniqueId = [annotUniqueIdObj GetAsPDFText];
            }
            if (annotUniqueId && [annotUniqueId isEqualToString:uniqueID]) {
                return annot;
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@, %@", exception.name, exception.reason);
    }
    @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlockRead];
        }
    }
    
    return nil;
}

- (NSString *)toText:(int)number
{
    PTPDFViewCtrl *pdfViewCtrl = self.documentViewController.pdfViewCtrl;
    PTPDFDoc *doc = [pdfViewCtrl GetDoc];
    PTPage *page = [doc GetPage:number];
    PTTextExtractor *txt = [[PTTextExtractor alloc] init];
    [txt Begin: page clip_ptr: 0 flags: 0]; // Read the page.

    PTTextExtractorLine *line = [txt GetFirstLine];
    PTWord *word;
    for (; [line IsValid]; line=[line GetNextLine]) {
        for (word=[line GetFirstWord]; [word IsValid]; word=[word GetNextWord]) {
            //[word GetString];
        }
    }
    NSString *text = [txt GetAsText:true];
    return text;
}

- (NSString *)exportAnnotationsWithOptions:(NSDictionary *)options
{
    PTPDFViewCtrl *pdfViewCtrl = self.documentViewController.pdfViewCtrl;
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        if (!options || !options[@"annotList"]) {
            PTFDFDoc *fdfDoc = [[pdfViewCtrl GetDoc] FDFExtract:e_ptboth];
            return [fdfDoc SaveAsXFDFToString];
        } else {
            PTVectorAnnot *annots = [[PTVectorAnnot alloc] init];
            
            NSArray *arr = options[@"annotList"];
            for (NSDictionary *annotation in arr) {
                NSString *annotationId = annotation[@"id"];
                int pageNumber = ((NSNumber *)annotation[@"pageNumber"]).intValue;
                if (annotationId.length > 0) {
                    PTAnnot *annot = [self findAnnotWithUniqueID:annotationId
                                                    onPageNumber:pageNumber];
                    if ([annot IsValid]) {
                        [annots add:annot];
                    }
                }
            }
            
            if ([annots size] > 0) {
                PTFDFDoc *fdfDoc = [[pdfViewCtrl GetDoc] FDFExtractAnnots:annots];
                return [fdfDoc SaveAsXFDFToString];
            } else {
                return nil;
            }
        }
    }
    @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlockRead];
        }
    }
    
    return nil;
}

- (void)importAnnotations:(NSString *)xfdfString
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLockRead];
        shouldUnlock = YES;
        
        PTFDFDoc *fdfDoc = [PTFDFDoc CreateFromXFDF:xfdfString];
        
        [[pdfViewCtrl GetDoc] FDFUpdate:fdfDoc];
        [pdfViewCtrl Update:YES];
    }
    @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlockRead];
        }
    }
}

- (void)setPageLabel: (NSArray *)mapping
{
    PTPDFViewCtrl *pdfViewCtrl = self.documentViewController.pdfViewCtrl;

    PTPageLabelManager *manager = self.documentViewController.toolManager.pageLabelManager;

    NSError *error = nil;
    [pdfViewCtrl DocLock:YES withBlock:^(PTPDFDoc * _Nullable doc) {
    
        for (int i = 0; i < [mapping count]; i++){
            NSString *item = [mapping objectAtIndex:i];
            [manager setPageLabelStyle:item prefix:item startValue:i+1 fromPageNumber:i+1 toPageNumber:i+1];
        }

    } error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
    }
   
    return;
}

#pragma mark - Flatten annotations

- (void)flattenAnnotations:(BOOL)formsOnly
{
    [self.toolManager changeTool:[PTPanTool class]];
    
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        
        PTPDFDoc *doc = [pdfViewCtrl GetDoc];
        
        [doc FlattenAnnotations:formsOnly];
    }
    @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlock];
        }
    }
    
    [pdfViewCtrl Update:YES];
}

#pragma mark - Saving

- (void)saveDocumentWithCompletionHandler:(void (^)(NSString * _Nullable filePath))completionHandler
{
    if (![self isBase64String]) {
        NSString *filePath = self.documentViewController.coordinatedDocument.fileURL.path;
        
        [self.documentViewController saveDocument:e_ptincremental completionHandler:^(BOOL success) {
            if (completionHandler) {
                completionHandler((success) ? filePath : nil);
            }
        }];
    } else {
        __block NSString *base64String = nil;
        __block BOOL success = NO;
        NSError *error = nil;
        [self.pdfViewCtrl DocLockReadWithBlock:^(PTPDFDoc * _Nullable doc) {
            NSData *data = [doc SaveToBuf:0];
            
            base64String = [data base64EncodedStringWithOptions:0];
            success = YES;
        } error:&error];
        if (completionHandler) {
            completionHandler((error == nil) ? base64String : nil);
        }
    }
}

#pragma mark - Fields

- (void)setFlagForFields:(NSArray<NSString *> *)fields setFlag:(PTFieldFlag)flag toValue:(BOOL)value
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        
        PTPDFDoc *doc = [pdfViewCtrl GetDoc];
        
        for (NSString *fieldName in fields) {
            PTField *field = [doc GetField:fieldName];
            if ([field IsValid]) {
                [field SetFlag:flag value:value];
            }
        }
        
        [pdfViewCtrl Update:YES];
    }
    @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlock];
        }
    }
}

- (void)setValueForFields:(NSDictionary<NSString *, id> *)map
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    BOOL shouldUnlock = NO;
    @try {
        [pdfViewCtrl DocLock:YES];
        shouldUnlock = YES;
        
        PTPDFDoc *doc = [pdfViewCtrl GetDoc];
        
        for (NSString *fieldName in map) {
            PTField *field = [doc GetField:fieldName];
            if ([field IsValid]) {
                id value = map[fieldName];
                [self setFieldValue:field value:value];
            }
        }
    }
    @finally {
        if (shouldUnlock) {
            [pdfViewCtrl DocUnlock];
        }
    }
}

// write-lock acquired around this method
- (void)setFieldValue:(PTField *)field value:(id)value
{
    PTPDFViewCtrl *pdfViewCtrl = self.pdfViewCtrl;
    
    const PTFieldType fieldType = [field GetType];
    
    // boolean or number
    if ([value isKindOfClass:[NSNumber class]]) {
        NSNumber *numberValue = (NSNumber *)value;
        
        if (fieldType == e_ptcheck) {
            const BOOL fieldValue = numberValue.boolValue;
            PTViewChangeCollection *changeCollection = [field SetValueWithBool:fieldValue];
            [pdfViewCtrl RefreshAndUpdate:changeCollection];
        }
        else if (fieldType == e_pttext) {
            NSString *fieldValue = numberValue.stringValue;
            
            PTViewChangeCollection *changeCollection = [field SetValueWithString:fieldValue];
            [pdfViewCtrl RefreshAndUpdate:changeCollection];
        }
    }
    // string
    else if ([value isKindOfClass:[NSString class]]) {
        NSString *fieldValue = (NSString *)value;
        
        if (fieldValue &&
            (fieldType == e_pttext || fieldType == e_ptradio)) {
            PTViewChangeCollection *changeCollection = [field SetValueWithString:fieldValue];
            [pdfViewCtrl RefreshAndUpdate:changeCollection];
        }
    }
}

#pragma mark - Collaboration

- (void)importAnnotationCommand:(NSString *)xfdfCommand initialLoad:(BOOL)initialLoad
{
    if (self.collaborationManager) {
        [self.collaborationManager importAnnotationsWithXFDFCommand:xfdfCommand
                                                          isInitial:initialLoad];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"set collabEnabled to true is required" userInfo:nil];
    }
}

#pragma mark - Viewer options

-(void)setNightModeEnabled:(BOOL)nightModeEnabled
{
    _nightModeEnabled = nightModeEnabled;
    
    [self applyViewerSettings];
}

#pragma mark - Top/bottom toolbar

-(void)setTopToolbarEnabled:(BOOL)topToolbarEnabled
{
    _topToolbarEnabled = topToolbarEnabled;
    
    [self applyViewerSettings];
}

-(void)setBottomToolbarEnabled:(BOOL)bottomToolbarEnabled
{
    _bottomToolbarEnabled = bottomToolbarEnabled;
    
    [self applyViewerSettings];
}

#pragma mark - Page indicator

-(void)setPageIndicatorEnabled:(BOOL)pageIndicatorEnabled
{
    _pageIndicatorEnabled = pageIndicatorEnabled;
    
    [self applyViewerSettings];
}

-(void)setPageIndicatorShowsOnPageChange:(BOOL)pageIndicatorShowsOnPageChange
{
    _pageIndicatorShowsOnPageChange = pageIndicatorShowsOnPageChange;
    
    [self applyViewerSettings];
}

-(void)setPageIndicatorShowsWithControls:(BOOL)pageIndicatorShowsWithControls
{
    _pageIndicatorShowsWithControls = pageIndicatorShowsWithControls;
    
    [self applyViewerSettings];
}

- (void)setAutoSaveEnabled:(BOOL)autoSaveEnabled
{
    _autoSaveEnabled = autoSaveEnabled;
    
    if (self.documentViewController) {
        [self applyViewerSettings];
    }
}

- (void)setPageChangeOnTap:(BOOL)pageChangeOnTap
{
    _pageChangeOnTap = pageChangeOnTap;
    
    if (self.documentViewController) {
        [self applyViewerSettings];
    }
}

- (void)setThumbnailViewEditingEnabled:(BOOL)enabled
{
    _thumbnailViewEditingEnabled = enabled;
    
    if (self.documentViewController) {
        [self applyViewerSettings];
    }
}

#pragma mark -

- (void)applyViewerSettings
{
    [self applyReadonly];
    
    // Thumbnail editing enabled.
    self.documentViewController.thumbnailsViewController.editingEnabled = self.thumbnailViewEditingEnabled;
    
    // Auto save.
    self.documentViewController.automaticallySavesDocument = self.autoSaveEnabled;
    
    // Top toolbar.
    if (!self.topToolbarEnabled) {
        self.documentViewController.hidesControlsOnTap = NO;
        self.documentViewController.controlsHidden = YES;
    } else {
        self.documentViewController.hidesControlsOnTap = YES;
        self.documentViewController.controlsHidden = NO;
    }
    const BOOL translucent = self.documentViewController.hidesControlsOnTap;
    self.documentViewController.thumbnailSliderController.toolbar.translucent = translucent;
    self.documentViewController.navigationController.navigationBar.translucent = translucent;
    
    // Bottom toolbar.
    self.documentViewController.bottomToolbarEnabled = self.bottomToolbarEnabled;
    
    // Page indicator.
    self.documentViewController.pageIndicatorEnabled = self.pageIndicatorEnabled;
    
    // Page change on tap.
    self.documentViewController.changesPageOnTap = self.pageChangeOnTap;
    
    // Fit mode.
    if ([self.fitMode isEqualToString:@"FitPage"]) {
        [self.pdfViewCtrl SetPageViewMode:e_trn_fit_page];
        [self.pdfViewCtrl SetPageRefViewMode:e_trn_fit_page];
    }
    else if ([self.fitMode isEqualToString:@"FitWidth"]) {
        [self.pdfViewCtrl SetPageViewMode:e_trn_fit_width];
        [self.pdfViewCtrl SetPageRefViewMode:e_trn_fit_width];
    }
    else if ([self.fitMode isEqualToString:@"FitHeight"]) {
        [self.pdfViewCtrl SetPageViewMode:e_trn_fit_height];
        [self.pdfViewCtrl SetPageRefViewMode:e_trn_fit_height];
    }
    else if ([self.fitMode isEqualToString:@"Zoom"]) {
        [self.pdfViewCtrl SetPageViewMode:e_trn_zoom];
        [self.pdfViewCtrl SetPageRefViewMode:e_trn_zoom];
    }
    
    // Layout mode.
    [self applyLayoutMode];
    
    // Annotation author.
    self.toolManager.annotationAuthor = self.annotationAuthor;
    
    // Shows saved signatures.
    self.toolManager.showDefaultSignature = self.showSavedSignatures;
    
    // Disable UI elements.
    [self disableElementsInternal:self.disabledElements];
    
    // Disable tools.
    [self setToolsPermission:self.disabledTools toValue:NO];
    
    // Custom HTTP request headers.
    [self applyCustomHeaders];
    
    // Color mode.
    [self applyColorMode];
}

- (void)applyLayoutMode
{
    if ([self.layoutMode isEqualToString:@"Single"]) {
        [self.pdfViewCtrl SetPagePresentationMode:e_trn_single_page];
    }
    else if ([self.layoutMode isEqualToString:@"Continuous"]) {
        [self.pdfViewCtrl SetPagePresentationMode:e_trn_single_continuous];
    }
    else if ([self.layoutMode isEqualToString:@"Facing"]) {
        [self.pdfViewCtrl SetPagePresentationMode:e_trn_facing];
    }
    else if ([self.layoutMode isEqualToString:@"FacingContinuous"]) {
        [self.pdfViewCtrl SetPagePresentationMode:e_trn_facing_continuous];
    }
    else if ([self.layoutMode isEqualToString:@"FacingCover"]) {
        [self.pdfViewCtrl SetPagePresentationMode:e_trn_facing_cover];
    }
    else if ([self.layoutMode isEqualToString:@"FacingCoverContinuous"]) {
        [self.pdfViewCtrl SetPagePresentationMode:e_trn_facing_continuous_cover];
    }
}

- (void)applyColorMode
{
    if (self.colorMode == 1){
         [self.pdfViewCtrl SetColorPostProcessMode: e_ptpostprocess_none];
    }else if (self.colorMode == 2){
          [self.pdfViewCtrl SetColorPostProcessMode: e_ptpostprocess_gradient_map];
    }else if (self.colorMode == 3){
        [self.pdfViewCtrl SetColorPostProcessMode: e_ptpostprocess_night_mode];
    }
}

#pragma mark - Custom headers

- (void)setCustomHeaders:(NSDictionary<NSString *, NSString *> *)customHeaders
{
    _customHeaders = [customHeaders copy];
    
    self.needsCustomHeadersUpdate = YES;
    
    if (self.documentViewController) {
        [self applyCustomHeaders];
    }
}

- (void)applyCustomHeaders
{
    if (!self.needsCustomHeadersUpdate) {
        return;
    }
    
    PTHTTPRequestOptions *options = self.documentViewController.httpRequestOptions;
    [self.customHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [options AddHeader:key val:value];
    }];
    
    self.needsCustomHeadersUpdate = NO;
}

#pragma mark - Readonly

- (void)setReadOnly:(BOOL)readOnly
{
    _readOnly = readOnly;
    
    if (self.documentViewController) {
        [self applyReadonly];
    }
}

- (void)applyReadonly
{
    // Enable readonly flag on tool manager *only* when not already readonly.
    // If the document is being streamed or converted, we don't want to accidentally allow editing by
    // disabling the readonly flag.
    if (![self.documentViewController.toolManager isReadonly]) {
        self.documentViewController.toolManager.readonly = self.readOnly;
    }
    
    self.documentViewController.thumbnailsViewController.editingEnabled = !self.readOnly;
}

#pragma mark - Fit mode

- (void)setFitMode:(NSString *)fitMode
{
    _fitMode = [fitMode copy];
    
    if (self.documentViewController) {
        [self applyViewerSettings];
    }
}

#pragma mark - Layout mode

- (void)setLayoutMode:(NSString *)layoutMode
{
    _layoutMode = [layoutMode copy];
    
    if (self.documentViewController) {
        [self applyViewerSettings];
    }
}

#pragma mark - Color mode

- (void)setColorMode:(int)colorMode
{
    _colorMode = colorMode;
    
    if (self.documentViewController) {
        [self applyViewerSettings];
    }
}

#pragma mark - Continuous annotation editing

- (void)setContinuousAnnotationEditing:(BOOL)continuousAnnotationEditing
{
    _continuousAnnotationEditing = continuousAnnotationEditing;
}

#pragma mark - Annotation author

- (void)setAnnotationAuthor:(NSString *)annotationAuthor
{
    _annotationAuthor = [annotationAuthor copy];
    
    if (self.documentViewController) {
        [self applyViewerSettings];
    }
}

#pragma mark - Show saved signatures

- (void)setShowSavedSignatures:(BOOL)showSavedSignatures
{
    _showSavedSignatures = showSavedSignatures;
    
    if (self.documentViewController) {
        [self applyViewerSettings];
    }
}

#pragma mark - Actions

- (void)navButtonClicked
{
    if([self.delegate respondsToSelector:@selector(navButtonClicked:)]) {
        [self.delegate navButtonClicked:self];
    }
}

#pragma mark - Convenience

- (UIViewController *)findParentViewController
{
    UIResponder *parentResponder = self;
    while ((parentResponder = parentResponder.nextResponder)) {
        if ([parentResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)parentResponder;
        }
    }
    return nil;
}

#pragma mark - <PTDocumentViewControllerDelegate>

- (BOOL)documentViewController:(PTDocumentViewController *)documentViewController shouldExportCachedDocumentAtURL:(NSURL *)cachedDocumentUrl
{
   // Don't export the downloaded file (ie. keep using the cache file).
   return NO;
}

- (BOOL)documentViewController:(PTDocumentViewController *)documentViewController shouldDeleteCachedDocumentAtURL:(NSURL *)cachedDocumentUrl
{
    // Don't delete the cache file.
    // (This will only be called if -documentViewController:shouldExportCachedDocumentAtURL: returns YES)
    return NO;
}

#pragma mark - <RNTPTDocumentViewControllerDelegate>

- (void)rnt_documentViewControllerDocumentLoaded:(PTDocumentViewController *)documentViewController
{
    if (self.initialPageNumber > 0) {
        [documentViewController.pdfViewCtrl SetCurrentPage:self.initialPageNumber];
    }
    
    if ([self isReadOnly] && ![self.documentViewController.toolManager isReadonly]) {
        self.documentViewController.toolManager.readonly = YES;
    }
    
    [self applyLayoutMode];
    
    if ([self.delegate respondsToSelector:@selector(documentLoaded:)]) {
        [self.delegate documentLoaded:self];
    }
    
    [self applyColorMode];
}

- (void)rnt_documentViewControllerDidZoom:(PTDocumentViewController *)documentViewController
{
    const double zoom = self.pdfViewCtrl.zoom * self.pdfViewCtrl.zoomScale;
    
    if ([self.delegate respondsToSelector:@selector(zoomChanged:zoom:)]) {
        [self.delegate zoomChanged:self zoom:zoom];
    }
}

- (BOOL)rnt_documentViewControllerShouldGoBackToPan:(PTDocumentViewController *)documentViewController
{
    return !self.continuousAnnotationEditing;
}

- (BOOL)rnt_documentViewControllerIsTopToolbarEnabled:(PTDocumentViewController *)documentViewController
{
    return self.topToolbarEnabled;
}

- (void)rnt_documentViewController:(PTDocumentViewController *)documentViewController filterMenuItemsForAnnotationSelectionMenu:(UIMenuController *)menuController
{
    if (self.annotationMenuItems.count == 0) {
        return;
    }
    
    NSDictionary<NSString *, NSString *> *map = @{
        @"Style": @"style",
        @"Note": @"note",
        @"Copy": @"copy",
        @"Delete": @"delete",
        @"Type": @"markupType",
        @"Search": @"search",
        @"Edit": @"editInk",
        @"Edit Text": @"editText",
        @"Flatten": @"flatten",
        @"Open": @"openAttachment",
    };
    NSMutableDictionary<NSString *, NSString *> *localizedMap = [NSMutableDictionary dictionary];
    for (NSString *key in map) {
        NSString *localizedKey = PTLocalizedString(key, nil);
        if (!localizedKey) {
            localizedKey = key;
        }
        localizedMap[localizedKey] = map[key];
    }
    
    NSMutableArray<UIMenuItem *> *permittedItems = [NSMutableArray array];
    
    for (UIMenuItem *menuItem in menuController.menuItems) {
        NSString *menuItemId = localizedMap[menuItem.title];
        if (menuItemId && [self.annotationMenuItems containsObject:menuItemId]) {
            [permittedItems addObject:menuItem];
        }
    }
    
    menuController.menuItems = [permittedItems copy];
}

#pragma mark - <PTDocumentViewControllerDelegate>

- (void)documentViewController:(PTDocumentViewController *)documentViewController didFailToOpenDocumentWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(documentError:error:)]) {
        [self.delegate documentError:self error:error.localizedFailureReason];
    }
}

#pragma mark - <PTCollaborationServerCommunication>

- (NSString *)documentID
{
    return self.document;
}

- (NSString *)userID
{
    return self.currentUser;
}

- (void)documentLoaded
{
    // Use rnt_documentViewControllerDocumentLoaded
}

- (void)localAnnotationAdded:(PTCollaborationAnnotation *)collaborationAnnotation
{
    [self rnt_sendExportAnnotationCommandWithAction:@"add"
                                        xfdfCommand:collaborationAnnotation.xfdf];
}

- (void)localAnnotationModified:(PTCollaborationAnnotation *)collaborationAnnotation
{
    [self rnt_sendExportAnnotationCommandWithAction:@"modify"
                                        xfdfCommand:collaborationAnnotation.xfdf];
}

- (void)localAnnotationRemoved:(PTCollaborationAnnotation *)collaborationAnnotation
{
    [self rnt_sendExportAnnotationCommandWithAction:@"delete"
                                        xfdfCommand:collaborationAnnotation.xfdf];
}

- (void)rnt_sendExportAnnotationCommandWithAction:(NSString *)action xfdfCommand:(NSString *)xfdfCommand
{
    if ([self.delegate respondsToSelector:@selector(exportAnnotationCommand:action:xfdfCommand:)]) {
        [self.delegate exportAnnotationCommand:self action:action xfdfCommand:xfdfCommand];
    }
}

#pragma mark - Notifications

- (void)documentViewControllerDidOpenDocumentWithNotification:(NSNotification *)notification
{
    if (notification.object != self.documentViewController) {
        return;
    }
    
    if ([self isReadOnly] && ![self.documentViewController.toolManager isReadonly]) {
        self.documentViewController.toolManager.readonly = YES;
    }
}

- (void)pdfViewCtrlDidChangePageWithNotification:(NSNotification *)notification
{
    if (notification.object != self.documentViewController.pdfViewCtrl) {
        return;
    }
    
    int previousPageNumber = ((NSNumber *)notification.userInfo[PTPDFViewCtrlPreviousPageNumberUserInfoKey]).intValue;
    int pageNumber = ((NSNumber *)notification.userInfo[PTPDFViewCtrlCurrentPageNumberUserInfoKey]).intValue;
    
    _pageNumber = pageNumber;
    
    // Notify delegate of change.
    if ([self.delegate respondsToSelector:@selector(pageChanged:previousPageNumber:)]) {
        [self.delegate pageChanged:self previousPageNumber:previousPageNumber];
    }
}

- (void)toolManagerDidAddAnnotationWithNotification:(NSNotification *)notification
{
    if (notification.object != self.documentViewController.toolManager) {
        return;
    }
    
    PTAnnot *annot = notification.userInfo[PTToolManagerAnnotationUserInfoKey];
    int pageNumber = ((NSNumber *)notification.userInfo[PTToolManagerPageNumberUserInfoKey]).intValue;
    
    NSString *annotId = [[annot GetUniqueID] IsValid] ? [[annot GetUniqueID] GetAsPDFText] : @"";
    if (annotId.length == 0) {
        PTPDFViewCtrl *pdfViewCtrl = self.documentViewController.pdfViewCtrl;
        BOOL shouldUnlock = NO;
        @try {
            [pdfViewCtrl DocLock:YES];
            shouldUnlock = YES;
            
            annotId = [NSUUID UUID].UUIDString;
            [annot SetUniqueID:annotId id_buf_sz:0];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@, %@", exception.name, exception.reason);
        }
        @finally {
            if (shouldUnlock) {
                [pdfViewCtrl DocUnlock];
            }
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(annotationChanged:annotation:action:)]) {
        [self.delegate annotationChanged:self annotation:@{
            @"id": annotId,
            @"pageNumber": @(pageNumber),
        } action:@"add"];
    }
}

- (void)toolManagerDidModifyAnnotationWithNotification:(NSNotification *)notification
{
    if (notification.object != self.documentViewController.toolManager) {
        return;
    }
    
    PTAnnot *annot = notification.userInfo[PTToolManagerAnnotationUserInfoKey];
    int pageNumber = ((NSNumber *)notification.userInfo[PTToolManagerPageNumberUserInfoKey]).intValue;
    
    NSString *annotId = [[annot GetUniqueID] IsValid] ? [[annot GetUniqueID] GetAsPDFText] : @"";
    
    if ([self.delegate respondsToSelector:@selector(annotationChanged:annotation:action:)]) {
        [self.delegate annotationChanged:self annotation:@{
            @"id": annotId,
            @"pageNumber": @(pageNumber),
        } action:@"modify"];
    }
}

- (void)toolManagerDidRemoveAnnotationWithNotification:(NSNotification *)notification
{
    if (notification.object != self.documentViewController.toolManager) {
        return;
    }
    
    PTAnnot *annot = notification.userInfo[PTToolManagerAnnotationUserInfoKey];
    int pageNumber = ((NSNumber *)notification.userInfo[PTToolManagerPageNumberUserInfoKey]).intValue;
    
    NSString *annotId = [[annot GetUniqueID] IsValid] ? [[annot GetUniqueID] GetAsPDFText] : @"";
    
    if ([self.delegate respondsToSelector:@selector(annotationChanged:annotation:action:)]) {
        [self.delegate annotationChanged:self annotation:@{
            @"id": annotId,
            @"pageNumber": @(pageNumber),
        } action:@"remove"];
    }
}

@end
