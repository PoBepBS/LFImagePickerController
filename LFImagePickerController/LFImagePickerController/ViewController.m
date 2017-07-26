//
//  ViewController.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "ViewController.h"
#import "LFImagePickerController.h"

#import "LFImagePickerHeader.h"
#import "LFAssetManager.h"
#import "LFAssetManager+Authorization.h"
#import "UIImage+LF_Format.h"
#import "UIAlertView+LF_Block.h"
#import "LFAssetManager.h"
#import "LFAssetManager+SaveAlbum.h"
#import <MobileCoreServices/UTCoreTypes.h>

@interface ViewController () <LFImagePickerControllerDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    UITapGestureRecognizer *singleTapRecognizer;
}
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageVIew;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) AVPlayerLayer *playerLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _playerLayer.bounds = self.imageView.bounds;
}

- (IBAction)buttonAction1:(id)sender {
//    LFImagePickerController *vc = [[LFImagePickerController alloc] initWithCameraMode:self];
//    [self presentViewController:vc animated:YES completion:nil];
//    return;
    
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
//    imagePicker.allowTakePicture = NO;
//    imagePicker.sortAscendingByCreateDate = NO;
    imagePicker.doneBtnTitleStr = @"确定";
//    imagePicker.allowClip = YES;
//    imagePicker.clipSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.width * 0.75);
//    imagePicker.allowEditting = NO;
//    imagePicker.supportAutorotate = YES; /** 适配横屏 */
//    imagePicker.imageCompressSize = 200; /** 标清图压缩大小 */
//    imagePicker.thumbnailCompressSize = 20; /** 缩略图压缩大小 */
//    imagePicker.allowPickingGif = YES; /** 支持GIF */
//    imagePicker.allowPickingLivePhoto = YES; /** 支持Live Photo */
//    imagePicker.autoSelectCurrentImage = NO; /** 关闭自动选中 */
//    imagePicker.defaultAlbumName = @"123"; /** 指定默认显示相册 */
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)buttonAction2:(id)sender {
    [self takePhoto];
    return;
    
    int limit = 1;
    [[LFAssetManager manager] getCameraRollAlbum:NO allowPickingImage:YES fetchLimit:limit ascending:NO completion:^(LFAlbum *model) {
        [[LFAssetManager manager] getAssetsFromFetchResult:model.result allowPickingVideo:NO allowPickingImage:YES fetchLimit:limit ascending:NO completion:^(NSArray<LFAsset *> *models) {
            NSMutableArray *array = [@[] mutableCopy];
            for (LFAsset *asset in models) {
                [array addObject:asset.asset];
            }
            LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithSelectedAssets:array index:0 excludeVideo:YES];
            imagePicker.pickerDelegate = self;
//            imagePicker.allowPickingGif = YES; /** 支持GIF */
            /** 全选 */
//            imagePicker.selectedAssets = array;
            
            [self presentViewController:imagePicker animated:YES completion:nil];
        }];
    }];
}

- (IBAction)buttonAction3:(id)sender {
    NSString *gifPath = [[NSBundle mainBundle] pathForResource:@"3" ofType:@"gif"];
//    [UIImage imageNamed:@"3.gif"] //这样加载是静态图片
    NSArray *array = @[[UIImage imageNamed:@"1.jpeg"], [UIImage imageNamed:@"2.jpeg"], [UIImage LF_imageWithImagePath:gifPath]];
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithSelectedPhotos:array index:0 complete:^(NSArray *photos) {
        [self.thumbnailImageVIew setImage:nil];
        [self.imageView setImage:photos.firstObject];
    }];
    /** 全选 */
    imagePicker.selectedAssets = array;
    /** 关闭自动选中 */
    imagePicker.autoSelectCurrentImage = NO;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishClipPhoto:(UIImage *)clipImage asset:(id)asset
{
    self.imageView.image = clipImage;
}

- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingResult:(NSArray <LFResultObject /* <LFResultImage/LFResultVideo> */*> *)results;
{
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    NSString *thumbnailFilePath = [documentPath stringByAppendingPathComponent:@"thumbnail"];
    NSString *originalFilePath = [documentPath stringByAppendingPathComponent:@"original"];
    
    NSFileManager *fileManager = [NSFileManager new];
    if (![fileManager fileExistsAtPath:thumbnailFilePath])
    {
        [fileManager createDirectoryAtPath:thumbnailFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (![fileManager fileExistsAtPath:originalFilePath])
    {
        [fileManager createDirectoryAtPath:originalFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    [_playerLayer removeFromSuperlayer];
    
    UIImage *thumbnailImage = nil;
    UIImage *originalImage = nil;
    AVPlayerLayer *playerLayer = [[AVPlayerLayer alloc] init];
    playerLayer.bounds = self.imageView.bounds;
    playerLayer.anchorPoint = CGPointZero;
    [self.imageView.layer addSublayer:playerLayer];
    _playerLayer = playerLayer;
    
    for (NSInteger i = 0; i < results.count; i++) {
        LFResultObject *result = results[i];
        if ([result isKindOfClass:[LFResultImage class]]) {
            
            LFResultImage *resultImage = (LFResultImage *)result;
            
            if (playerLayer.player == nil) {
                thumbnailImage = resultImage.thumbnailImage;
                originalImage = resultImage.originalImage;
                NSString *name = resultImage.info.name;
                NSData *thumnailData = resultImage.thumbnailData;
                NSData *originalData = resultImage.originalData;
                CGFloat byte = resultImage.info.byte;
                CGSize size = resultImage.info.size;
                
                
                /** 缩略图保存到路径 */
                //            [thumnailData writeToFile:[thumbnailFilePath stringByAppendingPathComponent:name] atomically:YES];
                /** 原图保存到路径 */
                //            [originalData writeToFile:[originalFilePath stringByAppendingPathComponent:name] atomically:YES];
                
                NSLog(@"⚠️Info name:%@ -- infoLength:%fK -- thumnailSize:%fK -- originalSize:%fK -- infoSize:%@", name, byte/1000.0, thumnailData.length/1000.0, originalData.length/1000.0, NSStringFromCGSize(size));
                
                NSLog(@"🎉thumbnail_imageOrientation:%ld -- original_imageOrientation:%ld -- thumbnailData_imageOrientation:%ld -- originalData_imageOrientation:%ld", (long)thumbnailImage.imageOrientation, (long)originalImage.imageOrientation, [UIImage imageWithData:thumnailData scale:[UIScreen mainScreen].scale].imageOrientation, [UIImage imageWithData:originalData scale:[UIScreen mainScreen].scale].imageOrientation);
            }
            
        } else if ([result isKindOfClass:[LFResultVideo class]]) {
            
            LFResultVideo *resultVideo = (LFResultVideo *)result;
            if (playerLayer.player == nil && originalImage == nil) {
                /** 保存视频 */
                [resultVideo.data writeToFile:[originalFilePath stringByAppendingPathComponent:resultVideo.info.name] atomically:YES];
                
                thumbnailImage = resultVideo.coverImage;
                
                AVPlayer *player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:[originalFilePath stringByAppendingPathComponent:resultVideo.info.name]]];
                [playerLayer setPlayer:player];
                [player play];
            }
        }
    }
    
    [self.thumbnailImageVIew setImage:thumbnailImage];
    [self.imageView setImage:originalImage];

}

#pragma mark - UIImagePickerController

- (void)takePhoto {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if ((authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied) && iOS7Later) {
        // 无权限 做一个友好的提示
        NSString *appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleDisplayName"];
        if (!appName) appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleName"];
        NSString *message = [NSString stringWithFormat:@"请在iPhone的\"设置-隐私-相机\"中允许%@访问相机",appName];
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"无法使用相机" message:message cancelButtonTitle:@"取消" otherButtonTitles:@"设置" block:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1) { // 去设置界面，开启相机访问权限
                if (iOS8Later) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                } else {
                    NSURL *privacyUrl = [NSURL URLWithString:@"prefs:root=Privacy&path=CAMERA"];
                    if ([[UIApplication sharedApplication] canOpenURL:privacyUrl]) {
                        [[UIApplication sharedApplication] openURL:privacyUrl];
                    } else {
                        NSString *message = @"无法跳转到隐私设置页面，请手动前往设置页面，谢谢";
                        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"抱歉" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
                        [alert show];
                    }
                }
            }
        }];
        
        [alert show];
    } else { // 调用相机
        if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
            LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
            if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(lf_imagePickerControllerTakePhoto:)]) {
                [imagePickerVc.pickerDelegate lf_imagePickerControllerTakePhoto:imagePickerVc];
            } else if (imagePickerVc.imagePickerControllerTakePhoto) {
                imagePickerVc.imagePickerControllerTakePhoto();
            } else {
                /** 调用内置相机模块 */
                UIImagePickerControllerSourceType srcType = UIImagePickerControllerSourceTypeCamera;
                UIImagePickerController *mediaPickerController = [[UIImagePickerController alloc] init];
                mediaPickerController.sourceType = srcType;
                mediaPickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                mediaPickerController.delegate = self;
                mediaPickerController.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
                
                /** warning：Snapshotting a view that has not been rendered results in an empty snapshot. Ensure your view has been rendered at least once before snapshotting or snapshot after screen updates. */
                [self presentViewController:mediaPickerController animated:YES completion:NULL];
            }
        } else {
            NSLog(@"模拟器中无法打开照相机,请在真机中使用");
        }
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [imagePickerVc showProgressHUDText:nil isTop:YES];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if (picker.sourceType==UIImagePickerControllerSourceTypeCamera && [mediaType isEqualToString:@"public.image"]){
        UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
        [[LFAssetManager manager] savePhotoWithImage:chosenImage completion:^(NSError *error) {
            if (!error) {
                [[LFAssetManager manager] getCameraRollAlbum:NO allowPickingImage:YES fetchLimit:1 ascending:NO completion:^(LFAlbum *model) {
                    [[LFAssetManager manager] getAssetsFromFetchResult:model.result allowPickingVideo:NO allowPickingImage:YES fetchLimit:1 ascending:NO completion:^(NSArray<LFAsset *> *models) {
                        NSMutableArray *array = [@[] mutableCopy];
                        for (LFAsset *asset in models) {
                            [array addObject:asset.asset];
                        }
                        LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithSelectedAssets:array index:0 excludeVideo:YES];
                        imagePicker.pickerDelegate = self;
                        [self presentViewController:imagePicker animated:YES completion:nil];
                    }];
                }];
            } else if (error) {
                [imagePickerVc hideProgressHUD];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"拍照错误" message:error.localizedDescription cancelButtonTitle:@"确定" otherButtonTitles:nil block:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    [picker dismissViewControllerAnimated:YES completion:nil];
                }];
                [alertView show];
            }
        }];
    } else {
        [imagePickerVc hideProgressHUD];
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}
@end
