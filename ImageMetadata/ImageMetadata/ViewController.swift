//
//  ViewController.swift
//  ImageMetadata
//
//  Created by L on 2018/9/28.
//  Copyright © 2018年 L. All rights reserved.
//

import UIKit
import Photos
import AssetsLibrary
import MobileCoreServices
import ImageIO

class ViewController: UIViewController {
    
    // 参考链接
    
    // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/ImageIOGuide/ikpg_dest/ikpg_dest.html#//apple_ref/doc/uid/TP40005462-CH219-SW3
    
    // https://blog.csdn.net/j_akill/article/details/52506980?locationNum=13
    
    // https://www.jianshu.com/p/a542751d4ba3
    
    // https://www.jianshu.com/p/71abd51df6f8
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // readiPhoneImageInfo()
        writeImageMetadate()
        
//        test()
    }
    
    func readiPhoneImageInfo() {
        
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
        
        // 图片这样h转Data 会丢失源数据信息
        if let imageData = UIImage(named: "testImage")?.pngData(), let cgImage = UIImage(named: "testImage")?.cgImage {
            if let source = CGImageSourceCreateWithData(imageData as CFData, nil) {
                if let imageInfo = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) {
                    // 获取源数据
                    print(imageInfo)
                    
                    LALA().ads(imageInfo as! [AnyHashable : Any], image: UIImage(named: "testImage")!)
                    var metaDataDic = NSMutableDictionary(dictionary: imageInfo)
                    /*
                    
                    var exifDic = (metaDataDic.value(forKey: "{Exif}") as? NSMutableDictionary) ?? NSMutableDictionary()
//                    var exifDic = metaDataDic["{Exif}"] as? [String: Any] ?? [String: Any]()
//                    var GPSDic = metaDataDic["{GPS}"] as? [String: Any] ?? [String: Any]()
                    // 修改exif数据
                    exifDic[kCGImagePropertyExifExposureTime as String] = 0
                    
                    // 修改GPS数据
//                    GPSDic[kCGImagePropertyGPSDateStamp as String] = "2012:10:18"
//                    GPSDic[kCGImagePropertyGPSLatitude as String] = 116.29353
//                    GPSDic[kCGImagePropertyGPSLatitudeRef as String] = "N"
                    // 合成到 metaDataDic
                    
                    exifDic[kCGImagePropertyExifDictionary as String] = exifDic
//                    metaDataDic[kCGImagePropertyGPSDictionary as String] = GPSDic
 */
                    // 将修改后的文件写入至图片中
                    if let UTI = CGImageSourceGetType(source) {
                        let newImageData = NSMutableData()
                        if let destination = CGImageDestinationCreateWithData(newImageData, UTI, 1, nil) {
                            CGImageDestinationAddImageFromSource(destination, source, 0, metaDataDic as CFDictionary)
                            if CGImageDestinationFinalize(destination) {
                                // 查看修改后图片的Exif信息
                                if let newImage = CIImage(data: newImageData as Data) {
                                    print(newImage.properties)
                                    let image = UIImage(ciImage: newImage)
//                                    saveImage(image: image)
                                    
                                    ALAssetsLibrary().writeImage(toSavedPhotosAlbum: cgImage, metadata: metaDataDic as! [AnyHashable : Any]) { (url, error) in
                                        print(error)
                                    }
                                }
                                
                                let path = NSHomeDirectory()
                                print(path)
                                newImageData.write(toFile: path + "/newImage.png", atomically: true)
                            }
                        }
                    }
                    
                }
            }
        }
        
    }
    
    func saveImage(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
//            let data = try! JSONSerialization.data(withJSONObject: imageWithMetaData, options: .prettyPrinted)
//            let creationRequest = PHAssetCreationRequest.forAsset()
//            creationRequest.addResource(with: .photo, data: data, options: nil)
        
        }) { (success, error) in
            print(error?.localizedDescription ?? "")
        }
    }
    
    func test() {
        
        let image = UIImage(named: "IMG_4492.JPG")!
        
        let sourceOptions: [String: AnyObject] = [kCGImageSourceTypeIdentifierHint as String: kUTTypeJPEG as AnyObject]
        let cfSourceOptions = sourceOptions as CFDictionary
        
        
        let data = image.jpegData(compressionQuality: 1.0)
        let source: CGImageSource = CGImageSourceCreateWithData(data as! CFData, cfSourceOptions)!
        
        let filepath = NSTemporaryDirectory().appending("out.jpg")
        
        print("Output file:")
        print(filepath)
        
        let fileURL: URL = URL(fileURLWithPath: filepath)
        
        let destination: CGImageDestination = CGImageDestinationCreateWithURL(fileURL as CFURL, kUTTypeJPEG, 1, nil)!
        
        var makeTag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceTIFF, kCGImageMetadataPrefixTIFF, kCGImagePropertyTIFFMake, .string, "Make" as CFString
            )!
        
        var modelTag = CGImageMetadataTagCreate(
            kCGImageMetadataNamespaceTIFF, kCGImageMetadataPrefixTIFF, kCGImagePropertyTIFFModel, .string, "Model" as CFString
            )!
        
        var metaDatas = CGImageMetadataCreateMutable()
        
        var tagPath = "tiff:Make" as CFString
        var result = CGImageMetadataSetTagWithPath(metaDatas, nil, tagPath, makeTag)
        
        tagPath = "tiff:Model" as CFString
        result = CGImageMetadataSetTagWithPath(metaDatas, nil, tagPath, modelTag)
        
        let destOptions: [String: AnyObject] = [
            kCGImageDestinationMergeMetadata as String: NSNumber(value: 1),
            kCGImageDestinationMetadata as String: metaDatas
        ]
        
        let cfDestOptions = destOptions as CFDictionary
        
        var error = 0
        var errorPtr: UnsafeMutablePointer<CFError>
        
        withUnsafeMutablePointer(to: &error, { ptr in
            result = CGImageDestinationCopyImageSource(destination, source, cfDestOptions, nil)
            print(String(format: "Write image to file result: %@", result ? "Success" : "Failed"))
//            print(String(format: "With error: %@", error.debugDescription))
        })
        
        let writeResult = CGImageDestinationFinalize(destination)
        
        // This is false, and you may see an error like:
        // " ImageIO: finalize:2031: not allowed for image destination that was updated with CGImageDestinationCopyImageSource "
        // But, in practice, it works. The file is there and the metadata is correct.
        print(writeResult)
    }

}

