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

enum ImageFormat {
    case unknown
    case jpeg
    case jpeg2000
    case tiff
    case bmp
    case ico
    case icns
    case gif
    case png
    case webp
    case psd
    case iff
    case swf
    case swc
}

// 其实这个,选中工程的图片文件,右键Open As(选Hex), 查看不同文件16进制的构成
// 就能知道不同格式的图片的构成了, 一般文件格式,都在Data的前几个字节中
struct ImageHeaderData{
    static var BMP: [UInt8] = [0x42, 0x4D] // 'B', 'M'
    static var GIF: [UInt8] = [0x47, 0x49, 0x46] // 'G', 'I', 'F'
    static var SWF: [UInt8] = [0x46, 0x57, 0x53] // 'F', 'W', 'S'
    static var SWC: [UInt8] = [0x43, 0x57, 0x53] // 'C', 'W', 'S'
    static var JPG: [UInt8] = [0xff, 0xd8, 0xff]
    static var PSD: [UInt8] = [0x38, 0x42, 0x50, 0x53] // '8', 'B', 'P', 'S'
    static var IFF: [UInt8] = [0x46, 0x4F, 0x52, 0x4D] // 'F', 'O', 'R', 'M'
    static var WEBP: [UInt8] = [0x52, 0x49, 0x46, 0x46] // 'R', 'I', 'F', 'F'
    static var ICO: [UInt8] = [0x00, 0x00, 0x01, 0x00]
    static var ICNS: [UInt8] = [0x69, 0x63, 0x6E, 0x73] // 'i', 'c', 'n', 's'
    static var TIFF_II: [UInt8] = [0x49, 0x49, 0x2A, 0x00] // 'I','I' 前2位
    static var TIFF_MM: [UInt8] = [0x4D, 0x4D, 0x00, 0x2A] // 'M','M' 前2位
    static var PNG: [UInt8] = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]
    static var JP2: [UInt8] = [0x00, 0x00, 0x00, 0x0c, 0x6a, 0x50, 0x20, 0x20, 0x0d, 0x0a, 0x87, 0x0a]
}

extension Data {
    
    var imageFormat: ImageFormat{
        var buffer = [UInt8](repeating: 0, count: 12)
        copyBytes(to: &buffer, count: 12)
        if memcmp(buffer, ImageHeaderData.BMP, 2) == 0 { // image/x-ms-bmp (bmp)
            return .bmp
        } else if memcmp(buffer, ImageHeaderData.GIF, 3) == 0 { // image/gif (gif)
            return .gif
        } else if memcmp(buffer, ImageHeaderData.SWF, 3) == 0 {
            return .swf
        } else if memcmp(buffer, ImageHeaderData.SWC, 3) == 0 {
            return .swc
        } else if memcmp(buffer, ImageHeaderData.JPG, 3) == 0 { // image/jpeg (jpg, jpeg)
            return .jpeg
        } else if memcmp(buffer, ImageHeaderData.PSD, 4) == 0 { // image/psd (psd)
            return .psd
        } else if memcmp(buffer, ImageHeaderData.IFF, 4) == 0 { // image/iff (iff)
            return .iff
        } else if memcmp(buffer, ImageHeaderData.WEBP, 4) == 0 { // image/webp (webp)
            return .webp
        } else if memcmp(buffer, ImageHeaderData.ICO, 4) == 0 { // image/vnd.microsoft.icon (ico)
            return .ico
        } else if memcmp(buffer, ImageHeaderData.ICNS, 4) == 0 {
            return .icns
        } else if memcmp(buffer, ImageHeaderData.TIFF_II, 4) == 0 || memcmp(buffer, ImageHeaderData.TIFF_MM, 4) == 0 { // image/tiff (tif, tiff)
            return .tiff
        } else if memcmp(buffer, ImageHeaderData.PNG, 8) == 0 { // image/png (png)
            return .png
        } else if memcmp(buffer, ImageHeaderData.JP2, 12) == 0 { // image/jp2 (JPEG 2000)
            return .jpeg2000
        } else{
            return .unknown
        }
    }
    
}

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
        imageFormatTest()
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
                                
                                // 写入后查看元数据,真机测试(模拟器沙盒貌似不保留)
                                // 真机开了iTunes共享,把沙盒文件复制到电脑,k打开后查看元数据已经被更改
                                let path = NSHomeDirectory()
                                let imagePath = path + "/Documents/newImage.png"
                                print(imagePath)
                                /* 写入方法1
                                let fp = fopen(imagePath, "w+")
                                let uint8 = [UInt8](newImageData as Data)
                                fwrite(newImageData.bytes, uint8.count, 1, fp)
                                fclose(fp)
                                */
                                
                                // 写入方法2
                                newImageData.write(toFile: imagePath, atomically: true)
                            }
                        }
                    }
                    
                }
            }
        }
        
    }
    
    /*
     关于无法修改Exif值的几点注意事项：
     
     1. 传入的数据格式与Exif规定的不符
     
     Exif的每条信息都有对应的数据类型，如：String Float... 如果数据类型传入错误将无法写入文件。
     
     2. 传入的字段超过规定字段长度
     
     3. 相互依赖的字段只添加了一个字段
     
     在GPS文件中经纬度的度数的字段与经纬度的方向的字段相互依赖，修改经／纬度数需要经／纬方向字段的存在，否则修改无效。
     */
    
    func imageFormatTest() {
        
        for item in ["gif", "ico", "bmp", "webp", "jpg", "png", "psd", "icns", "svg"] {
            if let filePath = Bundle.main.path(forResource: "test", ofType: item),
                let imgData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
                print(imgData.imageFormat)
            }
        }
        
    }
    
}


// MARK: - Util
extension ViewController {
    
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
    
}
