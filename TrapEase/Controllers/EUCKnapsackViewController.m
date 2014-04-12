//
//  EUCKnapsackViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCKnapsackViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "EUCDatabase.h"
#import "EUCNetwork.h"
#import "Toast+UIView.h"

static BOOL DEV = YES;

@interface EUCKnapsackViewController () {}

@property (assign, nonatomic) BOOL asSnapshot;
@property (assign, nonatomic) BOOL hasCamera;
@property (assign, nonatomic) BOOL hasLibrary;
@property (strong, nonatomic) UIImagePickerController *picker;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) ALAssetsLibrary *assetsLibrary;
@property (strong, nonatomic) NSURL *assetURL;
@property (weak, nonatomic) IBOutlet UIView *toastView;
@property (weak, nonatomic) IBOutlet UILabel *status;


@end

@implementation EUCKnapsackViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil asSnapshot: (BOOL) asSnapshot {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _assetsLibrary = [[ALAssetsLibrary alloc] init];

        _asSnapshot = asSnapshot;
        if (asSnapshot) {
            self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Screenshot", "Screenshot")
                                                            image:[UIImage imageNamed:@"camera"]
                                                    selectedImage:nil];
        }
        else {
            self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Photos", "Photos")
                                                            image:[UIImage imageNamed:@"photo"]
                                                    selectedImage:nil];
        }
        
    }
    return self;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Knapsack", "Knapsack")
                                                        image:[UIImage imageNamed:@"hiking"]
                                                selectedImage:nil];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (self.asSnapshot) {
        self.importButton.hidden = YES;
        self.clearButton.hidden = YES;
    }
    else {
        self.saveButton.hidden = YES;
        self.clearButton.hidden = YES;
    }
    
    self.clearButton.hidden = YES;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clear:(id)sender {

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are You Sure?", @"Are You Sure?")
                                                             delegate:self
                                                    cancelButtonTitle:@"Never mind"
                                               destructiveButtonTitle:@"Yes. Clear the image"
                                                    otherButtonTitles:
                                  nil];
    actionSheet.tag = 1;
    [actionSheet showFromRect:[(UIButton *)sender frame] inView:self.view animated:YES];

}

- (IBAction)save:(id)sender {
    // get the backpack
    
    self.saveButton.enabled = NO;
    [self.toastView makeToastActivity];
    
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
    
    [self.assetsLibrary assetForURL:self.assetURL
                        resultBlock:^(ALAsset *asset) {
                            NSLog(@"Asset is %@", asset);
                            if (asset != nil) {
                                // from: http://stackoverflow.com/a/8801656/772526
                                ALAssetRepresentation *rep = [asset defaultRepresentation];
                                Byte *buffer = (Byte*)malloc((unsigned long)rep.size);
                                NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:(unsigned int)rep.size error:nil];
                                data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];

                                self.status.text = @"Uploading image...";
                                [EUCNetwork uploadImageData:data toRepo:repoURL completion:^(NSString *payloadURL, NSString *errorCode) {
                                    if (errorCode) {
                                        [self alertWithTitle:@"Error" message:errorCode];
                                        [self activityStopped];
                                    }
                                    else {
                                        NSLog(@"URL Is %@", payloadURL);
                                        
                                        // get backpack(backpackurl)
                                        // if backpack is empty
                                        //    create backpack(url)
                                        // else
                                        //    add to content
                                        // PUT to backpack url
                                        self.status.text = @"Fetching backpack...";
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
                                                       
                                                       self.status.text = @"Adding image to backpack...";
                                                       [EUCNetwork putBackpack:backpack
                                                                         toUrl:putURL
                                                                  successBlock:^(NSURLSessionDataTask *task, id responseObject) {
                                                                      [self alertWithTitle:@"Success" message:@"The picture has been added to your backpack"];
                                                                      [self activityStopped];
                                                                      self.saveButton.hidden = YES;
                                                                  } failureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                                                                      [self alertWithTitle:@"Error" message:[error localizedDescription]];
                                                                      [self activityStopped];
                                                                  }];
                                                   }
                                                   else {
                                                       // create backpack dictionary
                                                       NSMutableDictionary * backpack = [[NSMutableDictionary alloc] init];
                                                       backpack[@"owner"] = groupName;
                                                       backpack[@"owner"] = @"aijaztest3";
                                                       NSMutableArray * contents = [NSMutableArray arrayWithCapacity:1];
                                                       [contents addObject:[self backpackEntryForUrl:payloadURL]];
                                                       backpack[@"content"] = contents;
                                                       
                                                       self.status.text = @"Uploading new backpack...";
                                                       [EUCNetwork postBackpack:backpack
                                                                          toUrl:backpackURL
                                                                   successBlock:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                       NSLog(@"Got %@", responseObject);
                                                                       [self alertWithTitle:@"Success" message:@"The picture has been added to your backpack"];
                                                                       [self activityStopped];
                                                                       self.saveButton.hidden = YES;
                                                                   } failureBlock:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                       [self alertWithTitle:@"Error" message:[error localizedDescription]];
                                                                       [self activityStopped];
                                                                   }];
                                                       
                                                   }
                                               }
                                                   failureBlock:^(NSString *reason) {
                                                       [self alertWithTitle:@"Error" message:reason];
                                                       [self activityStopped];

                                                   }];
                                    }
                                }];
                            }
                        }
                       failureBlock:^(NSError *error) {
                           NSLog(@"Error: %@", [error localizedDescription]);
                       }
     ];


}

-(void) activityStopped {
    self.saveButton.enabled = YES;
    [self.toastView hideToastActivity];
    self.status.text = @"";
}

-(void) alertWithTitle: (NSString *) title message: (NSString *) message {
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:title
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles: nil];
    
    [alertView show];
}

-(NSDictionary *) backpackEntryForUrl: (NSString *) url {
    NSDate* datetime = [NSDate date];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:SS.SSS'Z'"];
    NSString* dateTimeInIsoFormatForZuluTimeZone = [dateFormatter stringFromDate:datetime];

    return @{@"item_type": @"photomat_image",
             @"image_url": [NSString stringWithFormat:@"http://pikachu.badger.encorelab.org/%@", url],
             @"created_at": dateTimeInIsoFormatForZuluTimeZone
             };
}



- (IBAction)import:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select Source", @"selectSource")
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:
                                  nil];
    actionSheet.tag = 0;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Camera", @"Camera")];
        self.hasCamera = YES;
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Photo Library", @"Photo Library")];
        self.hasLibrary = YES;
    }
    
    [actionSheet showFromRect:[(UIButton *)sender frame] inView:self.view animated:YES];

}


#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 0) {
        NSInteger i = buttonIndex;
        BOOL useLibrary = NO;
        BOOL useCamera = NO;
        
        if (self.hasLibrary) {
            if (self.hasCamera) {
                if (i == 0) { useCamera = YES; }
                else if (i == 1) { useLibrary = YES; }
            }
            else {
                if (i == 0) { useLibrary = YES; }
            }
        }
        else {
            if (self.hasCamera) {
                if (i == 0) { useCamera = YES; }
            }
        }
        
        if (useLibrary) {
            self.picker = [[UIImagePickerController alloc] init];
            self.picker.delegate = self;
            self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            self.popover = [[UIPopoverController alloc] initWithContentViewController:self.picker];
            [self.popover presentPopoverFromRect:self.importButton.bounds
                                          inView:self.importButton
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
        }
        else if (useCamera) {
            self.picker = [[UIImagePickerController alloc] init];
            self.picker.delegate = self;
            self.picker.allowsEditing = NO;
            self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            self.popover = [[UIPopoverController alloc] initWithContentViewController:self.picker];
            [self.popover presentPopoverFromRect:self.importButton.bounds
                                          inView:self.importButton
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
        }
    }
    else if (actionSheet.tag == 1) {
        if (buttonIndex == 0) {
            self.imageView.image = nil;
            self.clearButton.hidden = YES;
            self.saveButton.hidden = YES;
        }
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Picking Image from Camera/ Library
    [self.popover dismissPopoverAnimated:YES];
    UIImage * selectedImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
    if (!selectedImage) {
        return;
    }
    
    self.saveButton.hidden = NO;
//    self.clearButton.hidden = NO;
    self.imageView.image = selectedImage;
    
    if (self.picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        // from http://stackoverflow.com/questions/10166575/photo-taken-with-camera-does-not-contain-any-alasset-metadata≥
        [self.assetsLibrary writeImageToSavedPhotosAlbum:selectedImage.CGImage
                                                metadata:[info objectForKey:UIImagePickerControllerMediaMetadata]
                                         completionBlock:^(NSURL *assetURL, NSError *error) {
                                             // work with assetURL
                                             self.assetURL = assetURL;
                                         }];
    }
    else {
        self.assetURL = [info valueForKey:UIImagePickerControllerReferenceURL];

    }
    
}


@end
