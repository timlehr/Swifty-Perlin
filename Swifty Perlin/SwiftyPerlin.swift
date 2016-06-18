//
//  SwiftyPerlin.swift
//  Swifty Perlin
//
//  Created by Tim on 11.06.16.
//  Copyright © 2016 Tim Lehr. All rights reserved.
//

import Foundation

class SwiftyPerlin2D {
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

class SwiftySimplex : NSObject {
    
    let size : Int = 256
    var mask : Int = 0
    var perm = [Int]()
    
    // Gradients for noise
    let grad2D = [Vector2.init(0, 1), Vector2.init(0, 1), Vector2.init(0, -1), Vector2.init(0, -1), Vector2.init(1, 0), Vector2.init(1, 0), Vector2.init(-1, 0), Vector2.init(-1, 0), Vector2.init(1, 1), Vector2.init(1, -1), Vector2.init(-1, 1), Vector2.init(-1, -1)]
    
    let grad3D = [Vector3.init(0, 1, 1), Vector3.init(0, 1, -1), Vector3.init(0, -1, 1), Vector3.init(0, -1, -1), Vector3.init(1, 0, 1), Vector3.init(1, 0, -1), Vector3.init(-1, 0, 1), Vector3.init(-1, 0, -1), Vector3.init(1, 1, 0), Vector3.init(1, -1, 0), Vector3.init(-1, 1, 0), Vector3.init(-1, -1, 0)]
    
    override init(){
        super.init()
        initialization()
    }
    
    func initialization(){
        mask = size - 1
        perm = permutation(size)
    }
    
    // Permutation function
    func permutation(size : Int) -> [Int] {
        
        for index in 0...size-1{
            let other : Int = random() % (index + 1)
            perm.insert(index, atIndex: other)
            if(index > other) {
                perm[index]=perm[other]
            }
        }
        
        for index in size...size*2-1{
            perm.append(perm[index & mask])
        }
        
        return perm
    }
    
    // Simplex noise 2D
    func simplex2D(x: Double, y: Double) -> Double {
        
        var noise = [Double]()                      // Noise components
        var points = [Vector2]()                    // Points of the triangle as 2D vectors
        
        let f2d : Double = 0.5 * (sqrt(3.0) - 1.0)  // skew factor
        let g2d : Double = (3.0 - sqrt(3.0)) / 6.0  // unskew factor
        
        let s : Double = (x+y) * f2d                // hairy factor
        
        let i : Int = Int(floor(x+s))               // ?? skewed x
        let j : Int = Int(floor(y+s))               // ?? skewed y
        
        
        let u : Double = Double((i+j)) * g2d        // unhairy factor
        
        let originX : Double = Double(i) - u        // cell origin in unskewed space
        let originY : Double = Double(j) - u
        
        // point 1 - distance between cell origin and x,y
        let p0 = Vector2.init(x - originX, y - originY)
        points.append(p0)
        
        let midX, midY : Double
        
        if(p0.x > p0.y){
            // lower triangle with XY order -> ▲
            midX = 1
            midY = 0
        } else {
            // upper triangle with YX order -> ▼
            midX = 0
            midY = 1
        }
        
        // point 2 - triangle middle point (unskewed)
        let p1 = Vector2.init(p0.x - midX + g2d, p0.y - midY + g2d)
        points.append(p1)
        
        // point 3 - last corner (unskewed)
        let p2 = Vector2.init(p0.x - 1 + 2 * g2d, p0.y - 1 + 2 * g2d)
        points.append(p2)
        
        // determine gradient index with hash
        let mi = i & mask
        let mj = j & mask
        
        var gIndex = [Int]()
        gIndex.append(perm[mi + perm[mj]] % 12)
        gIndex.append(perm[mi + Int(midX) + perm[mj + Int(midY)]] % 12)
        gIndex.append(perm[mi + 1 + perm[mj + 1]] % 12)
        
        //debugPrint(points, gIndex)
        
        for index in 0...2{
            var t : Double = 0.5 - points[index].x * points[index].x - points[index].y * points[index].y
            
            if(t < 0.0){
                noise.append(0.0)
            } else {
                t = t * t
                let result = t * t * grad2D[gIndex[index]].dot(points[index])
                noise.append(result)
            }
        }
        
        return 70 * (noise[0] + noise[1] + noise[2])
        
    }
    
    func octaveSimplex(x: Double, y: Double, octaves: Int, persistence: Double) -> Double {
        var total: Double = 0
        //var maxValue : Double = 0  // Used for normalizing result to 0.0 - 1.0
        
        for i in 0...octaves-1 {
            let frequency : Double = pow(2,Double(i))
            let amplitude : Double = pow(persistence,Double(i))
            total += simplex2D(x * frequency, y: y * frequency) * amplitude
            //maxValue += amplitude
        }
        
        let result = total // / maxValue
        //debugPrint(result)
        return result
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
    
    func genNoiseImg(width: Int, height: Int, octaves: Int, persistence: Double) -> (img : CGImage, renderTime : Double){
        
        var pixelArray = [PixelData](count: width * height, repeatedValue: PixelData(a: 255, r:0, g: 0, b: 0))
        
        let startTime = CFAbsoluteTimeGetCurrent();
        
        for i in 0...height-1{
            for j in 0...width-1{
                var noiseVal = abs(octaveSimplex(Double(j), y: Double(i), octaves: octaves, persistence: persistence))
                if(noiseVal > 1){
                    noiseVal = 1
                }
                
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
    
//    func simplex3D(x : Double, y: Double, z: Double) -> Double{
//        // Skewing factors
//        
//        let f3d : Double = 1.0 / 3.0
//        let g3d : Double = 1 / 6.0
//        
//        
//    }
}