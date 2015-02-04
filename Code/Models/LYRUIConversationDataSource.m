//
//  LYRConversationQueryController.m
//  Pods
//
//  Created by Kevin Coleman on 2/4/15.
//
//

#import "LYRUIConversationDataSource.h"

@interface LYRUIConversationDataSource ()

@property (nonatomic) BOOL expandingPaginationWindow;
@property (nonatomic, readwrite) NSInteger paginationWindow;

@end

@implementation LYRUIConversationDataSource

NSInteger const LYRUINumberOfSectionsBeforeFirstMessageSection = 1;
NSInteger const LYRUIQueryControllerPaginationWindow = 30;

+ (instancetype)initWithLayerClient:(LYRClient *)layerClient conversation:(LYRConversation *)conversation
{
    return [[self alloc] initWithLayerClient:layerClient conversation:conversation];
}

- (id)initWithLayerClient:(LYRClient *)layerClient conversation:(LYRConversation *)conversation
{
    self = [super init];
    if (self) {
        LYRQuery *query = [LYRQuery queryWithClass:[LYRMessage class]];
        query.predicate = [LYRPredicate predicateWithProperty:@"conversation" operator:LYRPredicateOperatorIsEqualTo value:conversation];
        query.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]];
       
        NSUInteger numberOfMessagesAvailable = [layerClient countForQuery:query error:nil];
        self.paginationWindow = LYRUIQueryControllerPaginationWindow;
        NSUInteger numberOfMessagesToDisplay = MIN(numberOfMessagesAvailable, self.paginationWindow);
    
        _queryController = [layerClient queryControllerWithQuery:query];
        _queryController.paginationWindow = -numberOfMessagesToDisplay;
        NSError *error = nil;
        BOOL success = [self.queryController execute:&error];
        if (!success) NSLog(@"LayerKit failed to execute query with error: %@", error);
    }
    return self;
}

- (void)incrementPaginationWindow
{
    if (!self.queryController) return;
    
    BOOL moreMessagesAvailable = self.queryController.totalNumberOfObjects > ABS(self.queryController.paginationWindow);
    if (!moreMessagesAvailable) return;
    
    NSUInteger numberOfMessagesToDisplay = MIN(-self.queryController.paginationWindow + self.paginationWindow, self.queryController.totalNumberOfObjects);
    self.queryController.paginationWindow = -numberOfMessagesToDisplay;
}

- (BOOL)moreMessagesAvailable
{
    return self.queryController.totalNumberOfObjects > ABS(self.queryController.count);
}

- (NSIndexPath *)queryControllerIndexPathForCollectionViewIndexPath:(NSIndexPath *)collectionViewIndexPath
{
    return [self queryControllerIndexPathForCollectionViewSection:collectionViewIndexPath.section];
}

- (NSIndexPath *)queryControllerIndexPathForCollectionViewSection:(NSInteger)collectionViewSection
{
    NSInteger queryControllerRow = [self queryControllerRowForCollectionViewSection:collectionViewSection];
    NSIndexPath *queryControllerIndexPath = [NSIndexPath indexPathForRow:queryControllerRow inSection:0];
    return queryControllerIndexPath;
}

- (NSInteger)queryControllerRowForCollectionViewSection:(NSInteger)collectionViewSection
{
    return collectionViewSection - LYRUINumberOfSectionsBeforeFirstMessageSection;
}

- (NSIndexPath *)collectionViewIndexPathForQueryControllerIndexPath:(NSIndexPath *)queryControllerIndexPath
{
    return [self collectionViewIndexPathForQueryControllerRow:queryControllerIndexPath.row];
}

- (NSIndexPath *)collectionViewIndexPathForQueryControllerRow:(NSInteger)queryControllerRow
{
    NSInteger collectionViewSection = [self collectionViewSectionForQueryControllerRow:queryControllerRow];
    NSIndexPath *collectionViewIndexPath = [NSIndexPath indexPathForRow:0 inSection:collectionViewSection];
    return collectionViewIndexPath;
}

- (NSInteger)collectionViewSectionForQueryControllerRow:(NSInteger)queryControllerRow
{
    return queryControllerRow + LYRUINumberOfSectionsBeforeFirstMessageSection;
}

- (LYRMessage *)messageAtCollectionViewIndexPath:(NSIndexPath *)collectionViewIndexPath
{
    NSIndexPath *queryControllerIndexPath = [self queryControllerIndexPathForCollectionViewIndexPath:collectionViewIndexPath];
    LYRMessage *message = [self.queryController objectAtIndexPath:queryControllerIndexPath];
    return message;
}

- (LYRMessage *)messageAtCollectionViewSection:(NSInteger)collectionViewSection
{
    NSIndexPath *queryControllerIndexPath = [self queryControllerIndexPathForCollectionViewSection:collectionViewSection];
    LYRMessage *message = [self.queryController objectAtIndexPath:queryControllerIndexPath];
    return message;
}

@end
