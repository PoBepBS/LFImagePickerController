//
//  LFPhotoClipManager.h
//  LFImagePickerController
//
//  Created by 范宝珅 on 2017/7/26.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface LFPhotoClipManager : NSObject

/** 裁剪背景框处理 */
+ (void)overlayClippingWithView:(UIView *)view cropREct:(CGRect)cropRect containerView:(UIView *)containerView needCircleClip:(BOOL)needCircleClip;

/** 获得裁剪后图片 */
+ (UIImage *)clipImageView:(UIImageView *)imageView toRect:(CGRect)rect zoomScale:(double)zoomScale containerView:(UIView *)containerView;

/** 获取圆形图片 */
+ (UIImage *)clipCircleImage:(UIImage *)image;
@end
