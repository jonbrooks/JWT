//
//  JWTDecriptedViewController.m
//  JWTDesktop
//
//  Created by Lobanov Dmitry on 25.09.16.
//  Copyright © 2016 JWT. All rights reserved.
//

#import "JWTDecriptedViewController.h"
#import "JWTDecriptedCollectionViewItem.h"
#import "JWTTokenTextTypeDescription.h"
@interface JWTDecriptedViewController ()
@property (weak) IBOutlet NSCollectionView *collectionView;
@property (copy, nonatomic, readwrite) NSString *collectionViewItemIdentifier;
@property (strong, nonatomic, readwrite) NSArray *cachedResultArray;
@property (strong, nonatomic, readwrite) NSDictionary *cachedErrorDictionary;

@property (copy, nonatomic, readonly) NSString *errorText;
@property (copy, nonatomic, readonly) NSString *headerText;
@property (copy, nonatomic, readonly) NSString *payloadText;

@property (strong, nonatomic, readwrite) JWTTokenTextTypeDescription *tokenDescription;
@end

@interface JWTDecriptedViewController (NSCollectionViewDelegateFlowLayout)<NSCollectionViewDelegateFlowLayout>
@end

@interface JWTDecriptedViewController (NSCollectionViewDataSource)<NSCollectionViewDataSource>
@end

@implementation JWTDecriptedViewController

- (void)setupUIElements {
    self.view.layer.backgroundColor = [NSColor greenColor].CGColor;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.minItemSize = NSZeroSize;
    self.collectionView.maxItemSize = NSZeroSize;
    [self.collectionView registerClass:[JWTDecriptedCollectionViewItem class] forItemWithIdentifier:self.collectionViewItemIdentifier];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUIElements];
}

- (void)reloadCollectionView {
    [self.collectionView reloadData];
}

- (NSString *)jsonStringWithObject:(NSDictionary *)object {
    if (object == nil) {
        return @"";
    }
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&error];
    if (error != nil) {
        return @"";
    }
    
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return string ?: @"";
}

- (void)reloadData {
    self.cachedResultArray = nil;
    self.cachedErrorDictionary = nil;
    NSDictionary *result = self.builder.decode;
    
    if (self.builder.jwtError != nil) {
        self.cachedErrorDictionary = @{
                                       @"Error" : self.builder.jwtError.localizedDescription
                                       };
    }
    else if (result != nil) {
        self.cachedResultArray =  @[
                                    @{@"header" : result[@"header"] ?: @""},
                                    @{@"payload" : result[@"payload"] ?: @""}
                                    ];
    }
}

- (NSString *)errorText {
    return self.cachedErrorDictionary ? [self jsonStringWithObject:self.cachedErrorDictionary] : nil;
}

- (NSString *)headerText {
    return self.cachedResultArray ? [self jsonStringWithObject:self.cachedResultArray[0]] : nil;
}

- (NSString *)payloadText {
    return self.cachedResultArray ? [self jsonStringWithObject:self.cachedResultArray[1]] : nil;
}

- (NSString *)collectionViewItemIdentifier {
    if (_collectionViewItemIdentifier == nil) {
        _collectionViewItemIdentifier = NSStringFromClass([JWTDecriptedCollectionViewItem class]);
    }
    return _collectionViewItemIdentifier;
}

- (void)setBuilder:(JWTBuilder *)builder {
    if (_builder != builder) {
        _builder = builder;
        [self reloadData];
        [self reloadCollectionView];
    }
}

- (JWTTokenTextTypeDescription *)tokenDescription {
    if (!_tokenDescription) {
        _tokenDescription = [JWTTokenTextTypeDescription new];
    }
    return _tokenDescription;
}

@end

@implementation JWTDecriptedViewController (NSCollectionViewDelegateFlowLayout)

- (NSSize)sizeWithText:(NSString *)text withWidth:(NSInteger)width {
    return NSZeroSize;
}

- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger height = 100;
    if (self.cachedErrorDictionary != nil) {
        // let it be.
    }
    else if (self.cachedResultArray != nil) {
        CGFloat heightParent = [[collectionView enclosingScrollView] bounds].size.height;
        if (indexPath.item == 0) {
            // header, not big.
            // let's say it has 1/5 of view?
            height = heightParent / 5.0f;
        }
        else {
            height = heightParent - heightParent / 5.0f;
        }
    }
    
    CGFloat width = collectionView.frame.size.width;//[[collectionView enclosingScrollView] bounds].size.width;
    NSSize size = NSMakeSize(width, height);
    return size;
}

//- (NSEdgeInsets)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section;
//- (CGFloat)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section;
//- (CGFloat)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section;
//- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section;
//- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section;

@end

@implementation JWTDecriptedViewController (NSCollectionViewDataSource)
- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger count = self.builder == nil ? 0 : (self.cachedErrorDictionary != nil ? 1 : 2);
    return count;
}

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
    return 1;
}

- (NSString *)textForItemAtIndexPath:(NSIndexPath *)path {
    NSDictionary *itemResult = nil;
    if (self.cachedErrorDictionary != nil) {
        itemResult = self.cachedErrorDictionary;
    }
    else if(self.cachedResultArray != nil) {
        itemResult = self.cachedResultArray[path.item];
    }
    NSString *text = [self jsonStringWithObject:itemResult];
    return text;
}

- (NSColor *)colorWithIndexPath:(NSIndexPath *)path {
    NSColor *color = nil;
    if (self.cachedErrorDictionary) {
        color = [self.tokenDescription tokenTextColorForType:JWTTokenTextTypeHeader];
    }
    else if (self.cachedResultArray) {
        color = [self.tokenDescription tokenTextColorForType: path.item == 0 ? JWTTokenTextTypeHeader : JWTTokenTextTypePayload];
    }
    return color;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    NSCollectionViewItem *item = [collectionView makeItemWithIdentifier:self.collectionViewItemIdentifier forIndexPath:indexPath];
    
    NSString *text = [self textForItemAtIndexPath:indexPath];
    JWTDecriptedCollectionViewItem *decriptedItem = (JWTDecriptedCollectionViewItem *)item;
    
    [decriptedItem updateWithText:text];
    [decriptedItem updateWithTextColor:[self colorWithIndexPath:indexPath]];
    return item;
}

@end
