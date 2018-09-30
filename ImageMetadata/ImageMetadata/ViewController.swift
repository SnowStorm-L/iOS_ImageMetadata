//
//  ViewController.swift
//  ImageMetadata
//
//  Created by L on 2018/9/28.
//  Copyright © 2018年 L. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

class ViewController: UIViewController {
    
    // 参考链接
    
    // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/ImageIOGuide/ikpg_dest/ikpg_dest.html#//apple_ref/doc/uid/TP40005462-CH219-SW3
    
    // https://developer.apple.com/documentation/imageio/cgimageproperties#//apple_ref/doc/constant_group/Canon_Camera_Dictionary_Keys
    
    // https://blog.csdn.net/j_akill/article/details/52506980?locationNum=13
    
    // https://www.jianshu.com/p/a542751d4ba3
    
    // https://www.jianshu.com/p/71abd51df6f8
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        readImageMetadate()
        writeImageMetadate()
        
    }
    
    func readImageMetadate() {
        
        // 获取图片文件
        if let fileUrl = Bundle.main.url(forResource: "IMG_4492", withExtension: "JPG") {
            // 创建CGImageSourceRef
            if let imageSource = CGImageSourceCreateWithURL(fileUrl as CFURL, nil) {
                // 利用imageSource获取全部ExifData
                if let imageInfo = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {
                    print(imageInfo)
                    // 从全部ExifData中取出EXIF文件
                    // print(imageInfo["{Exif}"] ?? "")
                }
            }
            
        }
        
        // PHAsset 获取图片信息
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true //download asset metadata from iCloud if needed
        PHAsset().requestContentEditingInput(with: options) { (contentEditingInput, info) in
            if let fullSizeImageURL = contentEditingInput?.fullSizeImageURL {
                if let fullImage = CIImage(contentsOf: fullSizeImageURL) {
                    print(fullImage.properties)
                }
            }
        }
        
        // UIImagePickerController 获取
        
        // UIImagePickerControllerDelegate 里面
        // UIImagePickerController.InfoKey.phAsset
        // let assetURL = info.object(forKey: UIImagePickerController.InfoKey.referenceURL)
    }
    
    func writeImageMetadate() {
        
        // 图片这样转Data 会丢失元数据信息
        if let imageData = UIImage(named: "testImage")?.pngData() {
            if let source = CGImageSourceCreateWithData(imageData as CFData, nil) {
                if let imageInfo = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] {
                    // 获取元数据
                    var metaDataDic = imageInfo
                    var exifDic = metaDataDic["{Exif}"] as? [String: Any] ?? [String: Any]()
                    // 修改exif数据
                    exifDic[kCGImagePropertyExifExposureTime as String] = NSNumber(value: 0.5)
                    metaDataDic[kCGImagePropertyExifDictionary as String] = exifDic
                    
                    // 将修改后的文件写入至图片中
                    if let UTI = CGImageSourceGetType(source) {
                        let newImageData = NSMutableData()
                        if let destination = CGImageDestinationCreateWithData(newImageData, UTI, 1, nil) {
                            CGImageDestinationAddImageFromSource(destination, source, 0, metaDataDic as CFDictionary)
                            if CGImageDestinationFinalize(destination) {
                                // 查看修改后图片的Exif信息
                                // self.getMutableMetadataFrom(imageData: newImageData as Data)
                                // 或者以下方法
                                if let newImage = CIImage(data: newImageData as Data) {
                                    print(newImage.properties)
                                }
                                // 保存修改元数据后的图片  至相册
                                // self.saveImage(with: newImageData as Data)
                                
                                // 传图片上服务器的时候别写入沙盒(这样会丢失元数据)
                                // 直接传拼接了元数据的Data(newImageData)
                                // URLSession.shared.uploadTask(with: URLRequest, from: newImageData)
                                
                                let path = NSHomeDirectory()
                                print(path)
                                // 写到沙盒不保留元数据
                                // newImageData.write(toFile: path + "/newImage.png", atomically: true)
                            }
                        }
                    }
                    
                }
            }
        }
        
    }
    
    func saveImage(with metaData: Data) {
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: metaData, options: nil)
        }) { (success, error) in
            print(error?.localizedDescription ?? "")
        }
    }
    
    // 元数据 拼接图片数据
    func attach(metadata: [String: Any], toImageData imageData:Data) -> Data? {
        // 这个方法,注意图片的类型 来调用不同的 函数 CGImage  jpg/png
        guard
            let imageDataProvider = CGDataProvider(data: imageData as CFData),
            let cgImage = CGImage(pngDataProviderSource: imageDataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent),
            let newImageData = CFDataCreateMutable(nil, 0),
            let type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, "image/png" as CFString, kUTTypeImage),
            let destination = CGImageDestinationCreateWithData(newImageData, (type.takeRetainedValue()), 1, nil)
            else {
                return nil
        }
        
        CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary)
        CGImageDestinationFinalize(destination)
        
        guard
            let newProvider = CGDataProvider(data: newImageData),
            let newCGImage =  CGImage(pngDataProviderSource: newProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
            else {
                return nil
        }
        return UIImage(cgImage: newCGImage).pngData()
    }
    
    // 从图片数据, 获取元数据
    func getMutableMetadataFrom(imageData data: Data) -> NSMutableDictionary? {
        
        if let imageSourceRef = CGImageSourceCreateWithData(data as CFData, nil),
            let currentProperties = CGImageSourceCopyPropertiesAtIndex(imageSourceRef, 0, nil) {
            return NSMutableDictionary(dictionary: currentProperties)
        }
        
        return nil
    }
    
    /*
     关于无法修改Exif值的几点注意事项：
     
     1. 传入的数据格式与Exif规定的不符
     
     Exif的每条信息都有对应的数据类型，如：String Float... 如果数据类型传入错误将无法写入文件。
     
     2. 传入的字段超过规定字段长度
     
     3. 相互依赖的字段只添加了一个字段
     
     在GPS文件中经纬度的度数的字段与经纬度的方向的字段相互依赖，修改经／纬度数需要经／纬方向字段的存在，否则修改无效。
     */
    
}

