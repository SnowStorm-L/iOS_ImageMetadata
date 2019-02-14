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
    
    var imageFormat: ImageFormat {
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
        } else if memcmp(buffer, ImageHeaderData.TIFF_II, 4) == 0 ||
            memcmp(buffer, ImageHeaderData.TIFF_MM, 4) == 0 { // image/tiff (tif, tiff)
            return .tiff
        } else if memcmp(buffer, ImageHeaderData.PNG, 8) == 0 { // image/png (png)
            return .png
        } else if memcmp(buffer, ImageHeaderData.JP2, 12) == 0 { // image/jp2 (JPEG 2000)
            return .jpeg2000
        } else{
            return .unknown
        }
    }
    
    var imageSize: CGSize {
        
        let type = self.imageFormat
        
        if type == .png {
            var buffer = [UInt8](repeating: 0, count: 8)
            copyBytes(to: &buffer, from: Range(16...23))
            return pngImageSize(withData: buffer.data)
        } else if type == .gif {
            var buffer = [UInt8](repeating: 0, count: 4)
            copyBytes(to: &buffer, from: Range(6...9))
            return gifImageSize(withData: buffer.data)
        } else if type == .bmp {
            var buffer = [UInt8](repeating: 0, count: 8)
            copyBytes(to: &buffer, from: Range(18...25))
            return bmpImageSize(withData: buffer.data)
        } else if type == .jpeg {
            return jpgImageSize()
        }
        
        return CGSize.zero
    }
    
    
    private enum JPEGHeaderSegment {
        case next
        case sof
        case skip
        case parse
        case eoi
    }
    
    private func jpgImageSize() -> CGSize {
        let offset = 2
        if count <= offset {
            return .zero
        }
        return parseJPEGData(offset: 2, segment: .next)
    }
    
    private func parseJPEGData(offset: Int, segment: JPEGHeaderSegment) -> CGSize {
        
        if count <= offset {
            return .zero
        }
        
        if segment == .eoi
            || (count <= offset + 1)
            || ((count <= offset + 2) && segment == .skip)
            || ((count <= offset + 7) && segment == .parse) {
            return .zero
        }
        
        switch segment {
        case .next:
            let newOffset = offset + 1
            var byte: UInt8 = 0x0
            copyBytes(to: &byte, from: Range(newOffset...newOffset+1))
            if byte == 0xff {
                return parseJPEGData(offset: newOffset, segment: .sof)
            } else {
                return parseJPEGData(offset: newOffset, segment: .next)
            }
        case .sof:
            let newOffset = offset + 1
            var byte: UInt8 = 0x0
            copyBytes(to: &byte, from: Range(newOffset...newOffset+1))
            
            if 0xEF >= byte && byte >= 0xE0 {
                return parseJPEGData(offset: newOffset, segment: .skip)
            } else if (0xC3 >= byte && byte >= 0xC0)
                || (0xC7 >= byte && byte >= 0xC5)
                || (0xCB >= byte && byte >= 0xC9)
                || (0xCF >= byte && byte >= 0xCD) {
                return parseJPEGData(offset: newOffset, segment: .parse)
            } else if byte == 0xFF {
                return parseJPEGData(offset: newOffset, segment: .sof)
            } else if byte == 0xD9 {
                return parseJPEGData(offset: newOffset, segment: .eoi)
            } else {
                return parseJPEGData(offset: newOffset, segment: .skip)
            }
            
        case .skip:
            var length: UInt8 = 0x0
            copyBytes(to: &length, from: Range(offset+1...offset+3))
            let newOffset: Int = offset + Int(length) - 1
            return parseJPEGData(offset: newOffset, segment: .next)
            
        case .parse:
            let startoffset = offset + 4
            var h1: UInt8 = 0, h2: UInt8 = 0
            copyBytes(to: &h1, from: Range(startoffset+2...startoffset+3))
            copyBytes(to: &h2, from: Range(startoffset+3...startoffset+4))
            
            let height: CGFloat = CGFloat(Int(h1) << 8 + Int(h2))
            
            var w1: UInt8 = 0, w2: UInt8 = 0
            copyBytes(to: &w1, from: Range(startoffset...startoffset+1))
            copyBytes(to: &w2, from: Range(startoffset+1...startoffset+2))
            let width: CGFloat = CGFloat(Int(w1) << 8 + Int(w2))
            
            return CGSize(width: width, height: height)
            
        default:
            return .zero
        }
        
    }
    
    private func bmpImageSize(withData data: Data) -> CGSize {
        
        if data.count != 8 {
            return .zero
        }
        
        var w1: UInt8 = 0, w2: UInt8 = 0, w3: UInt8 = 0, w4: UInt8 = 0
        data.copyBytes(to: &w1, from: Range(0...1))
        data.copyBytes(to: &w2, from: Range(1...2))
        data.copyBytes(to: &w3, from: Range(2...3))
        data.copyBytes(to: &w4, from: Range(3...4))
        
        let width: CGFloat = CGFloat( Int(w1) + Int(w2) << 8 + Int(w3) << 16 + Int(w4) << 24 )
        
        var h1: UInt8 = 0, h2: UInt8 = 0, h3: UInt8 = 0, h4: UInt8 = 0
        data.copyBytes(to: &h1, from: Range(4...5))
        data.copyBytes(to: &h2, from: Range(5...6))
        data.copyBytes(to: &h3, from: Range(6...7))
        data.copyBytes(to: &h4, from: Range(7...8))
        
        let height: CGFloat = CGFloat( Int(h1) + Int(h2) << 8 + Int(h3) << 16 + Int(h4) << 24 )
        
        return CGSize(width: width, height: height)
    }
    
    private func gifImageSize(withData data: Data) -> CGSize {
        
        if data.count != 4 {
            return .zero
        }
        
        var w1: UInt8 = 0, w2: UInt8 = 0
        data.copyBytes(to: &w1, from: Range(0...1))
        data.copyBytes(to: &w2, from: Range(1...2))
        
        let width: CGFloat = CGFloat(Int(w1) + Int(w2) << 8)
        
        var h1: UInt8 = 0, h2: UInt8 = 0
        data.copyBytes(to: &h1, from: Range(2...3))
        data.copyBytes(to: &h2, from: Range(3...4))
        
        let height: CGFloat = CGFloat(Int(h1) + Int(h2) << 8)
        
        return CGSize(width: width, height: height)
    }
    
    private func pngImageSize(withData data: Data) -> CGSize {
        
        if data.count != 8 {
            return .zero
        }
        
        var w1: UInt8 = 0, w2: UInt8 = 0, w3: UInt8 = 0, w4: UInt8 = 0
        data.copyBytes(to: &w1, from: Range(0...1))
        data.copyBytes(to: &w2, from: Range(1...2))
        data.copyBytes(to: &w3, from: Range(2...3))
        data.copyBytes(to: &w4, from: Range(3...4))
        
        let width: CGFloat = CGFloat( Int(w1) << 24 + Int(w2) << 16 + Int(w3) << 8 + Int(w4) )
        
        var h1: UInt8 = 0, h2: UInt8 = 0, h3: UInt8 = 0, h4: UInt8 = 0
        data.copyBytes(to: &h1, from: Range(4...5))
        data.copyBytes(to: &h2, from: Range(5...6))
        data.copyBytes(to: &h3, from: Range(6...7))
        data.copyBytes(to: &h4, from: Range(7...8))
        
        let height: CGFloat = CGFloat( Int(h1) << 24 + Int(h2) << 16 + Int(h3) << 8 + Int(h4) )
        
        return CGSize(width: width, height: height)
    }
    
}

extension Array where Element == UInt8 {
    var data : Data{
        return Data(bytes:(self))
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
        
        //readImageMetadate()
        //writeImageMetadate()
        //imageFormatTest()
        //imageSizeTest()
        //saveToBMP(withImage: UIImage(named: "location"))
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
                                // 真机开了iTunes共享,把沙盒文件复制到电脑,打开后查看元数据已经被更改
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
    
    func imageSizeTest() {
        
        for item in ["png", "gif", "bmp", "jpg"] {
            if let filePath = Bundle.main.path(forResource: "test", ofType: item),
                let imgData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
                print(imgData.imageSize)
            }
        }
        
    }
    
    func saveToBMP(withImage image: UIImage?) {
        guard let image = image else { return }
        guard let cgImage = image.cgImage else { return }
        let width = cgImage.width // 293
        let height = cgImage.height // 190
        let fileManager = FileManager.default
        let cachePath = "\(NSHomeDirectory())/Documents/32.bmp"
        print("BMP save in PATH \(cachePath)")
        fileManager.createFile(atPath: cachePath, contents: nil, attributes: nil)
        guard let fileHandle = FileHandle(forUpdatingAtPath: cachePath) else { return }
        
        // BPP（Bits Per Pixel）为每像素的比特数
        let bitsPerPixel = 32 // 32位位图
        let bitsPerComponent = 8
        
        let bytesPerPixel = bitsPerPixel / bitsPerComponent // 4
    
        let bytesPerRow = width * bytesPerPixel; // 1172
        let bufferLength = bytesPerRow * height; // 222680
        // 第一部分, 头信息, 一共14Byte
        /*
         typedef struct tagBITMAPFILEHEADER
         {
         UINT16 bfType;
         DWORD bfSize;
         UINT16 bfReserved1;
         UINT16 bfReserved2;
         DWORD bfOffBits;
         } BITMAPFILEHEADER;
         */
        
        // 文件类型
        // 占2bytes
        let bfTypeData = Data(bytes: [0x42, 0x4d])
        fileHandle.write(bfTypeData)
        
        // 位图文件大小
        // 占4bytes
        // 例子: 222736 字节, 16进制 36610, 4bytes 补满 00 03 66 10
        let bfSizeData = Data(bytes: [0x10, 0x66, 0x03, 0])
        fileHandle.write(bfSizeData)
        
        // 保留位 2bytes
        let bfReserved1Data = Data(bytes: [0, 0])
        fileHandle.write(bfReserved1Data)
        
        // 保留位 2bytes
        let bfReserved2Data = Data(bytes: [0, 0])
        fileHandle.write(bfReserved2Data)
        
        // 从头文件开始到实际图像数据之间的偏移量
        // (第一部分, 头信息, 一共14Byte + 第二部分, 位图信息头 40Byte + 第三部分, 调色板 0Byte) 一共54
        // 占4bytes
        let bfOffbitsData = Data(bytes: [0x36, 0, 0, 0])
        fileHandle.write(bfOffbitsData)
        
        // 第二部分, 位图信息头 一共40Byte
        
        // BITMAPINFOHEADER 结构所需要的字节数
        // 占4个bytes
        let biSizeData = Data(bytes: [0x28, 0, 0, 0])
        fileHandle.write(biSizeData)
        
        // 以下2个数可以通过width, height 算出来(现在偷懒一下,直接拿demo图的参数去填了)
        
        // 说明图像的宽度,以像素为单位 占4个bytes
        let biWidthData = Data(bytes: [0x25, 0x01, 0, 0]) // 293
        fileHandle.write(biWidthData)
        
        // 说明图像的高度,以像素为单位 占4个bytes
        // 正数,说明图像是倒向的,负数反之
        // 大多数bmp文件都是x倒向位图,也就是高度值是个正数
        let biHeight = Data(bytes: [0xbe, 0, 0, 0]) // 190
        fileHandle.write(biHeight)
        
        // 为设备说明颜色平面数,一般都是1
        // 占2个bytes
        let biPlanesData = Data(bytes: [0x01, 0])
        fileHandle.write(biPlanesData)
        
        // 说明比特数/像素,其值为1,4,8,16,24或32
        /*
         biBitCount字段值确定每个像素所需要的位数，biBitCount字段的取值与biCompression所指定的压缩方法相关。
         比如，如果每个像素由没有经过压缩，每个八位的RGBA组成，那biBitCount值为32，
         如果每个像素由经过压缩的RGB555组成，那biBitCount值为15,
         甚至，如果你的压缩方式只取5位的R，那biBitCount就是5。
         
         当biBitCount=1时，8个像素占1个字节；
         当biBitCount=4时，2个像素占1个字节；
         当biBitCount=8时，1个像素占1个字节；
         当biBitCount=24时,1个像素占3个字节；
         也就是说,一个像素所占的字节数是biBitCount/8。(RGBA)
         */
        // 占2个bytes
        let biBitCountData = Data(bytes: [0x20, 0]) // 32
        fileHandle.write(biBitCountData)
        
        // 说明图像数据压缩类型
        /*
         0 BI_RGB 不压缩(最常用)
         1 BI_RLE8 8比特游程编码(RLE), 只用于8位位图
         2 BI_RLE4 4比特游程编码(RLE), 只用于4位位图
         3 BI_BITFIELDS 比特域,用于16/32位位图
         4 BI_JPEG JPEG 位图含JPEG图像(仅用于打印机)
         5 BI_PNG PNG 位图含PNG图像(仅用于打印机)
         */
        // 占4个bytes
        let biCompressionData = Data(bytes: [0, 0, 0, 0])
        fileHandle.write(biCompressionData)
        
        // 说明图像的大小
        // 以字节为单位. 当用BI_RGB格式时,可设置为0
        // 占4个bytes
        let biSizeImageData = Data(bytes: [0, 0, 0, 0])
        fileHandle.write(biSizeImageData)
        
        // https://blog.csdn.net/blues1021/article/details/44827449
        /*
         It`s not very important.
         You can leave them on 2835 its not going to ruin the image. (72 DPI × 39.3701 inches per meter yields 2834.6472) 一寸等于2.54cm.
         */
        // 指定位图的目标设备的水平打印分辨率（以每米像素为单位) ,有符号整数
        // 占4个bytes
        let biXPelsPerMeterData = Data(bytes: [0x12, 0x0B, 0, 0])
        fileHandle.write(biXPelsPerMeterData)
        
        // 垂直分辨率
        // 占4个bytes
        let biYPelsPerMeter = Data(bytes: [0x12, 0x0B, 0, 0])
        fileHandle.write(biYPelsPerMeter)
        
        // 说明位图实际使用的彩色表中的颜色索引数
        // 设为0的话,则说明使用所有调色板项
        // 占4个bytes
        let biClrUsedData = Data(bytes: [0, 0, 0, 0])
        fileHandle.write(biClrUsedData)
        
        // 说明对图像显示有影响的颜色索引的数目
        // 如果是0,表示都重要
        // 占4个bytes
        let biClrImportantData = Data(bytes: [0, 0, 0, 0])
        fileHandle.write(biClrImportantData)
        
        // 第三部分, 调色板
        // 多少bytes 由颜色索引决定
        
        // 第四部分, 位图数据
        // 多少bytes 由图像尺寸决定
        
        let bmpData = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferLength)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
       
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return
        }
        
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        
        context.draw(cgImage, in: rect)
        
        guard let contextDataRaw = context.data else { return }
        
        /*
         图象数据BGRA：默认的BMP是不支持ALPHA通道的
         但对32位BMP而言，每个象素用32位(4个字节)表示，前三个字节表示RGB分量，最后一个字节可以做为ALPHA通道的值.
         因此32位位图可以存储带ALPHA通道的图像，在文件中，各分量的存储顺序为BGRA，BGRA，BGRA，BGRA…
         另外要注意的是，BMP图像的象素存储顺序是**从下到上**
         */
        
        /*
         BMP存储格式要求每行的字节数必须是4的倍数。
         对于24位的位图，每个像素有3个字节。有如下公式：
         补零的个数=width%4
         int bytesPerRow = (width * 3 + width % 4);
         byteIndex += 3
         biBitCount 也要改成24
         */

        var column = height

        var counter = 0

        for y in 0..<height {
            var byteIndex = 0
            column = column - 1
            for x in 0..<width {
                let point = CGPoint(x: x, y: y)
                let offset = 4 * (width*Int(round(point.y)) + Int(round(point.x)))
                let blue = contextDataRaw.load(fromByteOffset: offset, as: UInt8.self)
                let green = contextDataRaw.load(fromByteOffset: offset + 1, as: UInt8.self)
                let red = contextDataRaw.load(fromByteOffset: offset + 2, as: UInt8.self)
                let alpha = contextDataRaw.load(fromByteOffset: offset + 3, as: UInt8.self)
                let index = column * bytesPerRow + byteIndex
                /*
                 print("counter:\(counter) column:\(column) byteIndex:\(byteIndex)")
                 print("x:\(x) y:\(y) r:\(red) g:\(green) b:\(blue) a:\(alpha)")
                 */
                counter = counter + 1
                bmpData[index] = red
                bmpData[index + 1] = green
                bmpData[index + 2] = blue
                bmpData[index + 3] = alpha
                byteIndex = byteIndex + 4
            }
        }
        
        let colorData = Data(bytes: bmpData, count: bufferLength)
        fileHandle.write(colorData)
        fileHandle.closeFile()
        print("finish")
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
