import Foundation

class SwiftySimplex {
    
    // Gradients for noise
    let grad2D = [Vector2.init(0, 1), Vector2.init(0, 1), Vector2.init(0, -1), Vector2.init(0, -1), Vector2.init(1, 0), Vector2.init(1, 0), Vector2.init(-1, 0), Vector2.init(-1, 0), Vector2.init(1, 1), Vector2.init(1, -1), Vector2.init(-1, 1), Vector2.init(-1, -1)]
    
    let grad3D = [Vector3.init(0, 1, 1), Vector3.init(0, 1, -1), Vector3.init(0, -1, 1), Vector3.init(0, -1, -1), Vector3.init(1, 0, 1), Vector3.init(1, 0, -1), Vector3.init(-1, 0, 1), Vector3.init(-1, 0, -1), Vector3.init(1, 1, 0), Vector3.init(1, -1, 0), Vector3.init(-1, 1, 0), Vector3.init(-1, -1, 0)]
    
    // Permutation function
    func permutation(size : Int) -> [Int] {
        var perm = [Int]()
        
        for index in 0...size-1{
            let other : Int = random() % (index + 1)
            perm.insert(index, atIndex: other)
            if(index > other) {
                perm[index]=perm[other]
            }
        }
        return perm
    }
    
    // Simplex noise 2D
    func simplex2D(x: Double, y: Double) -> Double {
        
        let size : Int = 256
        let mask : Int = size - 1
        let perm : [Int] = permutation(size)
        
        var noise = [Double]()                      // Noise components
        var points = [Vector2]()                    // Points of the triangle as 2D vectors
        
        let f2d : Double = 0.5 * (sqrt(3.0) - 1.0)  // skew factor
        let s : Double = (x+y) * f2d                // hairy factor
        
        let i : Int = Int(floor(x+s))               // ?? skewed x
        let j : Int = Int(floor(y+s))               // ?? skewed y
        
        let g2d : Double = (3.0 - sqrt(3.0) - 1.0)  // unskew factor
        let t : Double = Double((i+j)) * g2d        // unhairy factor
        
        let originX : Double = Double(i) - t        // cell origin in unskewed space
        let originY : Double = Double(j) - t
        
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
        
        for index in 0...2{
            var t : Double = 0.5 - points[index].x * points[index].x - points[index].y * points[index].y
            if(t<0){
                noise[index] = 0.0
            } else {
                t = t * t
                noise[index] = t * t * grad2D[gIndex[index]].dot(points[index])
            }
        }
        
        return 70 * (noise[0] + noise[1] + noise[2])
}
