//
//  EUCImageDisplayViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/28/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCImageDisplayViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "EUCDatabase.h"
#import "EUCNetwork.h"
#import "EUCTimeUtilities.h"
#import "Toast+UIView.h"

@interface EUCImageDisplayViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

@property (weak, nonatomic) IBOutlet UIImageView *displayImage;

@property (strong, nonatomic) UIImage *backgroundImage;

@property (strong, nonatomic) NSURL * assetURL;

@property (strong, nonatomic) NSString *fileName;

@property (strong, nonatomic) ALAssetsLibrary *assetsLibrary;



- (IBAction)done:(id)sender;
@end

@implementation EUCImageDisplayViewController

static BOOL DEV = NO;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil backgroundImage: (UIImage *) backgroundImage assetURL: (NSURL *) assetURL fileName: (NSString *) fileName
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
        _backgroundImage = backgroundImage;
        _assetURL = assetURL;
        _fileName = fileName;
    }
    return self;
}

-(NSDictionary *) backpackEntryForUrl: (NSString *) url {
    return @{@"item_type": @"photomat_image",
             @"image_url": [NSString stringWithFormat:@"http://pikachu.badger.encorelab.org/%@", url],
             @"created_at": [EUCTimeUtilities currentTimeInZulu]
             };
}

- (IBAction)addToBackpack:(id)sender {
    EUCDatabase * db = [EUCDatabase sharedInstance];
    NSString * className = [db className];
    NSString * groupName = [db groupName];
    
    NSString * backpackURL;
    NSDictionary * selector = @{@"selector": [NSString stringWithFormat:@"{\"owner\": \"%@\"}", groupName]};
    if (DEV) {
        backpackURL = [NSString stringWithFormat:@"http://drowsy.badger.encorelab.org/dev-safari-%@/backpacks", className];
    }
    else {
        backpackURL = [NSString stringWithFormat:@"http://drowsy.badger.encorelab.org/safari-%@/backpacks", className];
    }
    
    NSString * repoURL = @"http://pikachu.badger.encorelab.org/";
    __block NSData * data;
    
    void (^restBlock)() = ^{
        [EUCNetwork uploadImageData:data toRepo:repoURL completion:^(NSString *payloadURL, NSString *errorCode) {
            if (errorCode) {
                [self alertWithTitle:@"Error" message:errorCode];
                //[self activityStopped];
            }
            else {
                NSLog(@"URL Is %@", payloadURL);
                
                // get backpack(backpackurl)
                // if backpack is empty
                //    create backpack(url)
                // else
                //    add to content
                // PUT to backpack url
//                self.status.text = @"Fetching backpack...";
                [EUCNetwork getBackpack:backpackURL
                           withSelector: selector
                       withSuccessBlock:^(NSArray *objects) {
                           if ([objects count]) {
                               // backpack exists
                               // extract dictionary
                               NSDictionary * robackpack = (NSDictionary *)[objects firstObject];
                               NSMutableDictionary * backpack = [[NSMutableDictionary alloc] init];
                               NSDictionary * _id = robackpack[@"_id"];
                               NSString * oid = _id[@"$oid"];
                               
                               backpack[@"_id"] = _id;
                               backpack[@"owner"] = robackpack[@"owner"];
                               
                               NSMutableArray * contents = [NSMutableArray arrayWithArray: robackpack[@"content"]];
                               backpack[@"content"] = contents;
                               
                               [contents addObject:[self backpackEntryForUrl:payloadURL]];
                               NSString * putURL = [NSString stringWithFormat:@"%@/%@", backpackURL, oid];
                               
                               //self.status.text = @"Adding image to backpack...";
                               [EUCNetwork putBackpack:backpack
                                                 toUrl:putURL
                                          successBlock:^(NSURLSessionDataTask *task, id responseObject) {
                                               [self alertWithTitle:@"Success" message:@"The picture has been added to your backpack"];
                                               //[self activityStopped];
                                          } failureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                                               [self alertWithTitle:@"Error" message:[error localizedDescription]];
                                               //[self activityStopped];
                                          }];
                           }
                           else {
                               // create backpack dictionary
                               NSMutableDictionary * backpack = [[NSMutableDictionary alloc] init];
                               backpack[@"owner"] = groupName;
                               NSMutableArray * contents = [NSMutableArray arrayWithCapacity:1];
                               [contents addObject:[self backpackEntryForUrl:payloadURL]];
                               backpack[@"content"] = contents;
                               
                              // self.status.text = @"Uploading new backpack...";
                               [EUCNetwork postBackpack:backpack
                                                  toUrl:backpackURL
                                           successBlock:^(AFHTTPRequestOperation *operation, id responseObject) {
                                               NSLog(@"Got %@", responseObject);
                                               [self alertWithTitle:@"Success" message:@"The picture has been added to your backpack"];
                                               //[self activityStopped];
                                           } failureBlock:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                [self alertWithTitle:@"Error" message:[error localizedDescription]];
                                                //[self activityStopped];
                                           }];
                               
                           }
                       }
                           failureBlock:^(NSString *reason) {
                                [self alertWithTitle:@"Error" message:reason];
                                //[self activityStopped];
                               
                           }];
            }
        }];
    };
    
    if (self.assetURL == nil) {
        data = UIImageJPEGRepresentation(self.displayImage.image, 1.0);
        restBlock();
    }
    else {
        [self.assetsLibrary assetForURL:self.assetURL
                            resultBlock:^(ALAsset *asset) {
                                NSLog(@"Asset is %@", asset);
                                if (asset != nil) {
                                    // from: http://stackoverflow.com/a/8801656/772526
                                    ALAssetRepresentation *rep = [asset defaultRepresentation];
                                    Byte *buffer = (Byte*)malloc((unsigned long)rep.size);
                                    NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:(unsigned int)rep.size error:nil];
                                    data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                                    
                                    restBlock();
                                }
                            }
                           failureBlock:^(NSError *error) {
                               [self alertWithTitle:@"Error" message:[error localizedDescription]];
                               NSLog(@"Error: %@", [error localizedDescription]);
                           }
         ];
    }

}

-(void) activityStopped {
    //[self.toastView hideToastActivity];
}

-(void) alertWithTitle: (NSString *) title message: (NSString *) message {
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:title
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles: nil];

    [alertView show];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.backgroundImageView.image = self.backgroundImage;
    
    if (self.assetURL) {
        ALAssetsLibrary * library = [[ALAssetsLibrary alloc] init];
        [library assetForURL:self.assetURL
                 resultBlock:^(ALAsset *asset) {
                     UIImage * image = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
                     self.displayImage.image = image;
                 } failureBlock:^(NSError *error) {
                     UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                          message:@"Cannot open image"
                                                                         delegate:nil
                                                                cancelButtonTitle:nil
                                                                otherButtonTitles:@"OK", nil];
                     
                     [alertView show];
                 }];
    }
    else {
        UIImage * image = [UIImage imageWithContentsOfFile:self.fileName];
        self.displayImage.image = image;
    }
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
