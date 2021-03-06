//
//  RNTPTDocumentViewManager.m
//  RNPdftron
//
//  Copyright © 2018 PDFTron. All rights reserved.
//

#import "RNTPTDocumentViewManager.h"

@implementation RNTPTDocumentViewManager

RCT_EXPORT_MODULE(RNTPTDocumentView)

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _documentViews = [NSMutableDictionary dictionary];
    }
    return self;
}

RCT_EXPORT_VIEW_PROPERTY(onChange, RCTBubblingEventBlock)

RCT_CUSTOM_VIEW_PROPERTY(document, NSString, RNTPTDocumentView)
{
    if (json && [RCTConvert NSString:json]) {
        view.document = [RCTConvert NSString:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(isBase64String, BOOL, RNTPTDocumentView)
{
    if (json) {
        view.base64String = [RCTConvert BOOL:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(password, NSString, RNTPTDocumentView)
{
    if (json) {
        view.password = [RCTConvert NSString:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(initialPageNumber, int, RNTPTDocumentView)
{
    if (json) {
        view.initialPageNumber = [RCTConvert int:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(pageNumber, int, RNTPTDocumentView)
{
    if (json) {
        view.pageNumber = [RCTConvert int:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(showLeadingNavButton, BOOL, RNTPTDocumentView)
{
    if (json) {
        view.showNavButton = [RCTConvert BOOL:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(leadingNavButtonIcon, NSString, RNTPTDocumentView)
{
    if (json && [RCTConvert NSString:json]) {
        view.navButtonPath = [RCTConvert NSString:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(disabledElements, NSArray, RNTPTDocumentView)
{
    if (json) {
        NSArray *disabledElements = [RCTConvert NSArray:json];
        view.disabledElements = disabledElements;
    }
    
}

RCT_CUSTOM_VIEW_PROPERTY(disabledTools, NSArray, RNTPTDocumentView)
{
    if (json) {
        NSArray *disabledTools = [RCTConvert NSArray:json];
        view.disabledTools = disabledTools;
    }
}

// viewer options
//RCT_CUSTOM_VIEW_PROPERTY(nightModeEnabled, BOOL, RNTPTDocumentView)
//{
//    if (json) {
//        view.nightModeEnabled = [RCTConvert BOOL:json];
//    }
//}

RCT_CUSTOM_VIEW_PROPERTY(topToolbarEnabled, BOOL, RNTPTDocumentView)
{
    if (json) {
        view.topToolbarEnabled = [RCTConvert BOOL:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(bottomToolbarEnabled, BOOL, RNTPTDocumentView)
{
    if (json) {
        view.bottomToolbarEnabled = [RCTConvert BOOL:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(pageIndicatorEnabled, BOOL, RNTPTDocumentView)
{
    if (json) {
        view.pageIndicatorEnabled = [RCTConvert BOOL:json];
    }
}

//RCT_CUSTOM_VIEW_PROPERTY(pageIndicatorShowsOnPageChange, BOOL, RNTPTDocumentView)
//{
//    if (json) {
//        view.pageIndicatorShowsOnPageChange = [RCTConvert BOOL:json];
//    }
//}
//
//RCT_CUSTOM_VIEW_PROPERTY(pageIndicatorShowsWithControls, BOOL, RNTPTDocumentView)
//{
//    if (json) {
//        view.pageIndicatorShowsWithControls = [RCTConvert BOOL:json];
//    }
//}

RCT_CUSTOM_VIEW_PROPERTY(customHeaders, NSDictionary, RNTPTDocumentView)
{
    if (json) {
        view.customHeaders = [RCTConvert NSDictionary:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(readOnly, BOOL, RNTPTDocumentView)
{
    if (json) {
        view.readOnly = [RCTConvert BOOL:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(fitMode, NSString, RNTPTDocumentView)
{
    if (json) {
        view.fitMode = [RCTConvert NSString:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(layoutMode, NSString, RNTPTDocumentView)
{
    if (json) {
        view.layoutMode = [RCTConvert NSString:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(colorMode, int, RNTPTDocumentView)
{
    if (json){
        view.colorMode = [RCTConvert int:json];
    }
    

 
}

RCT_CUSTOM_VIEW_PROPERTY(continuousAnnotationEditing, BOOL, RNTPTDocumentView)
{
    if (json) {
        view.continuousAnnotationEditing = [RCTConvert BOOL:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(annotationAuthor, NSString, RNTPTDocumentView)
{
    if (json) {
        view.annotationAuthor = [RCTConvert NSString:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(showSavedSignatures, BOOL, RNTPTDocumentView)
{
    if (json) {
        view.showSavedSignatures = [RCTConvert BOOL:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(collabEnabled, BOOL, RNTPTDocumentView)
{
    if (json) {
        view.collabEnabled = [RCTConvert BOOL:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(currentUser, NSString, RNTPTDocumentView)
{
    if (json) {
        view.currentUser = [RCTConvert NSString:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(currentUserName, NSString, RNTPTDocumentView)
{
    if (json) {
        view.currentUserName = [RCTConvert NSString:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(autoSaveEnabled, BOOL, RNTPTDocumentView)
{
    if (json) {
        view.autoSaveEnabled = [RCTConvert BOOL:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(annotationMenuItems, NSArray, RNTPTDocumentView)
{
    if (json) {
        view.annotationMenuItems = [RCTConvert NSArray:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(pageChangeOnTap, BOOL, RNTPTDocumentView)
{
    if (json) {
        view.pageChangeOnTap = [RCTConvert BOOL:json];
    }
}

RCT_CUSTOM_VIEW_PROPERTY(thumbnailViewEditingEnabled, BOOL, RNTPTDocumentView)
{
    if (json) {
        view.thumbnailViewEditingEnabled = [RCTConvert BOOL:json];
    }
}

- (UIView *)view
{
    RNTPTDocumentView *documentView = [[RNTPTDocumentView alloc] init];
    documentView.delegate = self;
    return documentView;
}

#pragma mark - Events

- (void)navButtonClicked: (RNTPTDocumentView *) sender
{
    if (sender.onChange) {
        sender.onChange(@{
            @"onLeadingNavButtonPressed": @YES,
        });
    }
}

- (void)documentLoaded:(RNTPTDocumentView *)sender
{
    if (sender.onChange) {
        sender.onChange(@{
            @"onDocumentLoaded": (sender.document ?: @""),
        });
    }
}

- (void)documentError:(RNTPTDocumentView *)sender error:(NSString *)error
{
    if (sender.onChange) {
        sender.onChange(@{
            @"onDocumentError": (error ?: @""),
        });
    }
}

- (void)pageChanged:(RNTPTDocumentView *)sender previousPageNumber:(int)previousPageNumber
{
    if (sender.onChange) {
        sender.onChange(@{
            @"onPageChanged": @"onPageChanged",
            @"previousPageNumber": @(previousPageNumber),
            @"pageNumber": @(sender.pageNumber),
        });
    }
}

- (void)zoomChanged:(RNTPTDocumentView *)sender zoom:(double)zoom
{
    if (sender.onChange) {
        sender.onChange(@{
            @"onZoomChanged" : @"onZoomChanged",
            @"zoom": @(zoom),
        });
    }
}

- (void)annotationChanged:(RNTPTDocumentView *)sender annotation:(NSDictionary *)annotation action:(NSString *)action
{
    if (sender.onChange) {
        sender.onChange(@{
            @"onAnnotationChanged" : @"onAnnotationChanged",
            @"action": action,
            @"annotations": @[annotation],
        });
    }
}

- (void)exportAnnotationCommand:(RNTPTDocumentView *)sender action:(NSString *)action xfdfCommand:(NSString *)xfdfCommand
{
    if (sender.onChange) {
        sender.onChange(@{
            @"onExportAnnotationCommand": @"onExportAnnotationCommand",
            @"action": action,
            @"xfdfCommand": xfdfCommand,
        });
    }
}

#pragma mark - Methods

- (void)setToolModeForDocumentViewTag:(NSNumber *)tag toolMode:(NSString *)toolMode
{
    RNTPTDocumentView *documentView = self.documentViews[tag];
    if (documentView) {
        [documentView setToolMode:toolMode];
    }
}

- (BOOL)commitToolForDocumentViewTag:(NSNumber *)tag
{
    RNTPTDocumentView *documentView = self.documentViews[tag];
    if (documentView) {
        return [documentView commitTool];
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Unable to find DocumentView for tag" userInfo:nil];
        return NO;
    }
}

- (int)getPageCountForDocumentViewTag:(NSNumber *)tag
{
    RNTPTDocumentView *documentView = self.documentViews[tag];
    if (documentView) {
        return [documentView getPageCount];
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Unable to find DocumentView for tag" userInfo:nil];
        return 0;
    }
}

- (NSString *)toTextForDocumentViewTag:(NSNumber *)tag number:(int)number
{
    RNTPTDocumentView *documentView = self.documentViews[tag];
    if (documentView) {
        return [documentView toText:number];
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Unable to find DocumentView for tag" userInfo:nil];
        return nil;
    }
}

- (NSString *)exportAnnotationsForDocumentViewTag:(NSNumber *)tag options:(NSDictionary *)options
{
    RNTPTDocumentView *documentView = self.documentViews[tag];
    if (documentView) {
        return [documentView exportAnnotationsWithOptions:options];
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Unable to find DocumentView for tag" userInfo:nil];
        return nil;
    }
}

- (void)importAnnotationCommandForDocumentViewTag:(NSNumber *)tag xfdfCommand:(NSString *)xfdfCommand initialLoad:(BOOL)initialLoad
{
    RNTPTDocumentView *documentView = self.documentViews[tag];
    if (documentView) {
        [documentView importAnnotationCommand:xfdfCommand initialLoad:initialLoad];
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Unable to find DocumentView for tag" userInfo:nil];
    }
}

- (void)importAnnotationsForDocumentViewTag:(NSNumber *)tag xfdf:(NSString *)xfdfString
{
    RNTPTDocumentView *documentView = self.documentViews[tag];
    if (documentView) {
        [documentView importAnnotations:xfdfString];
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Unable to find DocumentView for tag" userInfo:nil];
    }
}

- (void)flattenAnnotationsForDocumentViewTag:(NSNumber *)tag formsOnly:(BOOL)formsOnly
{
    RNTPTDocumentView *documentView = self.documentViews[tag];
    if (documentView) {
        [documentView flattenAnnotations:formsOnly];
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Unable to find DocumentView for tag" userInfo:nil];
    }
}

- (void)saveDocumentForDocumentViewTag:(NSNumber *)tag completionHandler:(void (^)(NSString * _Nullable filePath))completionHandler
{
    RNTPTDocumentView *documentView = self.documentViews[tag];
    if (documentView) {
        [documentView saveDocumentWithCompletionHandler:^(NSString * _Nullable filePath){
            if (completionHandler) {
                completionHandler(filePath);
            }
        }];
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Unable to find DocumentView for tag"
                                     userInfo:nil];
    }
}

- (void)setFlagForFieldsForDocumentViewTag:(NSNumber *)tag forFields:(NSArray<NSString *> *)fields setFlag:(PTFieldFlag)flag toValue:(BOOL)value
{
    RNTPTDocumentView *documentView = self.documentViews[tag];
    if (documentView) {
        [documentView setFlagForFields:fields setFlag:flag toValue:value];
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Unable to find DocumentView for tag" userInfo:nil];
    }
}

- (void)setValueForFieldsForDocumentViewTag:(NSNumber *)tag map:(NSDictionary<NSString *, id> *)map
{
    RNTPTDocumentView *documentView = self.documentViews[tag];
    if (documentView) {
        [documentView setValueForFields:map];
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Unable to find DocumentView for tag" userInfo:nil];
    }
}

#pragma mark - DocumentView attached/detached

- (void)documentViewAttachedToWindow:(RNTPTDocumentView *)documentView
{
    self.documentViews[documentView.reactTag] = documentView;
}

- (void)documentViewDetachedFromWindow:(RNTPTDocumentView *)documentView
{
    [self.documentViews removeObjectForKey:documentView.reactTag];
}

- (void)pageLabelViewTag:(NSNumber *)tag mapping:(NSArray *)mapping
{
    RNTPTDocumentView *documentView = self.documentViews[tag];
    if (documentView) {
        [documentView setPageLabel: mapping];
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Unable to find DocumentView for tag" userInfo:nil];
    }
}

@end
