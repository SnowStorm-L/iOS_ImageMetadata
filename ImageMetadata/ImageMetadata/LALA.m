//
//  LALA.m
//  ImageMetadata
//
//  Created by L on 2018/9/28.
//  Copyright © 2018年 L. All rights reserved.
//

#import "LALA.h"
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation LALA

- (instancetype)init {
    if (self = [super init]) {
        
       
    }
    return self;
}

- (void)ads:(NSDictionary *)lala image:(UIImage *)image {
    
    
    NSDictionary *imageMetadata = [[NSMutableDictionary alloc] initWithDictionary:lala];
    
    NSLog(@"metadata:--%@",imageMetadata);
    
    NSDictionary *gpsDic = [imageMetadata objectForKey:@"{GPS}"];
    NSDictionary *exifDic = [imageMetadata objectForKey:@"{Exif}"];
    NSDictionary *tiffDic = [imageMetadata objectForKey:@"{TIFF}"];
    
    NSLog(@"UserComment:%@",[exifDic valueForKey:@"UserComment"]);
    
    //可交换图像文件
    NSLog(@"Exif info:--%@",exifDic);
    //地理位置信息
    NSLog(@"GPS info:--%@",gpsDic);
    //图像文件格式
    NSLog(@"tiff info:--%@",tiffDic);
    
    //写入DateTimeOriginal
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY:MM:dd hh:mm:ss"];
    NSString *now = [formatter stringFromDate:[NSDate date]];
    
    [exifDic setValue:now forKey:(NSString*)kCGImagePropertyExifDateTimeOriginal];
    
    [exifDic setValue:[NSNumber numberWithFloat:0.52] forKey:(NSString*)kCGImagePropertyExifExposureTime];
    
    [imageMetadata setValue:exifDic forKey:@"{Exif}"];
    
    //写入UserComment
    NSString *userComment = @"this is a test text for writing data in UserComment";
    //        NSData *encodeData = [userComment dataUsingEncoding:NSUTF8StringEncoding];
    //        NSData *aesData = [encodeData AES256EncryptWithKey:@"key"];
    //        NSString *encryptString = [aesData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    [exifDic setValue:userComment forKey:(NSString*)kCGImagePropertyTIFFImageDescription];
    [imageMetadata setValue:exifDic forKey:@"{TIFF}"];
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeImageToSavedPhotosAlbum:[image CGImage] metadata:imageMetadata completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error == nil)
            NSLog(@"metadata write success!");
        else
            NSLog(@"write error:%@",error.userInfo);
    }];
}

@end
