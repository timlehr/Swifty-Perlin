//
//  SwiftyPerlin.swift
//  Swifty Perlin
//
//  Created by Tim on 11.06.16.
//  Copyright © 2016 Tim Lehr. All rights reserved.
//

import Foundation

class SwiftyPerlin {
    init () {
        initialise()
    }
    
    // variables
    let size : Int = 2048
    let mask : Int = 2047
    
    var zoom : Double = 0.0
    var frequency : Double = 0.0
    var amplitude : Double = 0.0
    var sizeImage = CGSize(width: 81, height: 114)
    
    var perm = [Int]()
    var grads_x = [Double]()
    var grads_y = [Double]()
    
    func initialise(){
        
        perm.removeAll(keepCapacity: false)
        
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
    
    // Interpolation based on Cubic polonomial s(t) = 3t^2 - 2t^3
    private func fCubic(var t : Double) -> Double{
        t = min(fabs(t),1.0)
        t = 1.0 - (3.0 - 2.0 * t) * t * t
        return t
    }
    
    // Interpolation based on Quintic polynomial s(t) = 6t^5 - 15t^4 + 10t^3
    private func fQuintic(var t : Double) -> Double{
        t = min(fabs(t),1.0)
        t = 1.0 - ((6 * t + 15) * t + 10) * t * t * t
        return t
    }
    
    private func surflet(x : Double, y: Double, grad_x : Double, grad_y : Double) -> Double{
        return fCubic(x) * fCubic(y) * (grad_x * x + grad_y * y)
    }
    
    func noise(var x: Double, var y: Double) -> Double {
        
        x = x * frequency / (zoom * 3) // Zoom * 3 for better results
        y = y * frequency / (zoom * 3) // Zoom * 3 for better results
        
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
        
        return (result+1) * amplitude
    }
    
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
    
    private func imageFromARGB32Bitmap(pixels:[PixelData], width:Int, height:Int)->CGImage {
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
    
    func genNoiseImg(width: Int, height: Int, zoom: Double, octave: Double, persistence: Double) -> (img : CGImage, renderTime : Double){
        
        var pixelArray = [PixelData](count: width * height, repeatedValue: PixelData(a: 255, r:0, g: 0, b: 0))
        
        self.zoom = zoom
        self.frequency = pow(2,octave)
        self.amplitude = pow(persistence,octave)
        
        let startTime = CFAbsoluteTimeGetCurrent();
        
        for i in 0...height-1{
            for j in 0...width-1{
                var noiseVal = abs(noise(Double(j),y: Double(i)))
                if(noiseVal > 1){
                    noiseVal = 1
                }
                //noiseVal = (noiseVal + 1) / 2
                
                let index = i * width + j
                let u_I = UInt8(noiseVal * 255)
                pixelArray[index].r = u_I
                pixelArray[index].g = u_I
                pixelArray[index].b = 0
            }
        }
        
        let renderTime = Double(CFAbsoluteTimeGetCurrent() - startTime)
        
        return (imageFromARGB32Bitmap(pixelArray, width: width, height: height), renderTime)
        
    }
}