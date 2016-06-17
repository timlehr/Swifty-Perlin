//: Playground - noun: a place where people can play

import Cocoa

// variables
let size : Int = 256
let mask : Int = size - 1

var zoom : Double = 1.16
var sizeImage = CGSize(width: 81, height: 114)

var perm = [Int]()
var grads_x = [Double]()
var grads_y = [Double]()

func initialise(){
    for index in 0...size-1{
        let other : Int = random() % (index + 1)
        perm.insert(index, atIndex: other)
        if(index > other) {
            perm[index]=perm[other]
        }
        
        let grad_x = cos(2.0 * M_PI * Double(index) / Double(size))
        let grad_y = sin(2.0 * M_PI * Double(index) / Double(size))
        grads_x.insert(grad_x, atIndex: index)
        grads_y.insert(grad_y, atIndex: index)
    }
}

// Falloff based on Cubic polonomial s(t) = 3t^2 - 2t^3
func falloff(var t : Double) -> Double{
    t = min(fabs(t),1.0)
    t = 1.0 - (3.0 - 2.0 * t) * t * t
    return t
}

func surflet(x : Double, y: Double, grad_x : Double, grad_y : Double) -> Double{
    return falloff(x) * falloff(y) * (grad_x * x + grad_y * y)
}

func noise(var x: Double, var y: Double) -> Double {
    
    x = x * 2 / zoom
    y = y * 2 / zoom
    
    var result : Double = 0.0
    let cell_x : Int = Int(floor(x))
    let cell_y : Int = Int(floor(y))
    
    for(var grid_y = cell_y; grid_y <= cell_y + 1; grid_y += 1){
        for(var grid_x = cell_x; grid_x <= cell_x + 1; grid_x += 1){
            let hash : Int = perm[(perm[grid_x & mask] + grid_y) & mask]
            //debugPrint(x,grid_x,y,grid_y,grads_x[hash],grads_y[hash])
            result = result + surflet(x - Double(grid_x), y: y - Double(grid_y), grad_x: grads_x[hash], grad_y: grads_y[hash])
        }
    }
    
    return result
}

initialise()
noise(7,y:91)

////////////////////////////////////////
///////////////////////////////////////

struct PixelData {
    var a:UInt8 = 255
    var r:UInt8
    var g:UInt8
    var b:UInt8
}

private let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
private let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue)

func imageFromARGB32Bitmap(pixels:[PixelData], width:Int, height:Int)->CGImage {
    let bitsPerComponent:Int = 8
    let bitsPerPixel:Int = 32
    
    assert(pixels.count == Int(width * height))
    
    var data = pixels // Copy to mutable []
    let providerRef = CGDataProviderCreateWithCFData(NSData(bytes: &data, length: data.count * sizeof(PixelData)))
    
    let cgim = CGImageCreate(
        width,
        height,
        bitsPerComponent,
        bitsPerPixel,
        width * Int(sizeof(PixelData)),
        rgbColorSpace,
        bitmapInfo,
        providerRef,
        nil,
        false,
        CGColorRenderingIntent.RenderingIntentDefault
    )
    return cgim!
}

func genNoiseImg(){
    
    initialise()
    
    let width = Int(sizeImage.width)
    let height = Int(sizeImage.height)
    
    var pixelArray = [PixelData](count: width * height, repeatedValue: PixelData(a: 255, r:0, g: 0, b: 0))
    
    for i in 0...height-1{
        for j in 0...width-1{
            var noiseVal = abs(noise(Double(j),y: Double(i)))
            if noiseVal > 1 {
                noiseVal = 1
            }
            
            let index = i * width + j
            let u_I = UInt8(noiseVal * 255)
            pixelArray[index].r = u_I
            pixelArray[index].g = u_I
            pixelArray[index].b = 0
        }
    }
    
    let outputImage = imageFromARGB32Bitmap(pixelArray, width: width, height: height)
    NSImage(CGImage: outputImage, size: NSSize(width: Int(sizeImage.width), height: Int(sizeImage.height)))
}

genNoiseImg()
