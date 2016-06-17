//
//  ViewController.swift
//  Swifty Perlin
//
//  Created by Tim on 09.06.16.
//  Copyright © 2016 Tim Lehr. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet var noiseView : NSImageView!
    @IBOutlet var newImgBtn : NSButton!
    @IBOutlet var timeLbl : NSTextField!
    @IBOutlet var octave : NSSlider!
    @IBOutlet var zoom : NSSlider!
    @IBOutlet var persistence : NSSlider!
    @IBOutlet var octaveLbl : NSTextField!
    @IBOutlet var zoomLbl : NSTextField!
    @IBOutlet var persistenceLbl : NSTextField!
    
    var gen : SwiftyPerlin = SwiftyPerlin()

    override func viewDidLoad() {
        super.viewDidLoad()
        octaveLbl.stringValue = "\(octave.doubleValue)"
        zoomLbl.stringValue = "\(zoom.doubleValue)"
        persistenceLbl.stringValue = "\(persistence.doubleValue)"
        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func newImage(){
        gen.initialise()
        let noiseResult = gen.genNoiseImg(Int(noiseView.frame.width), height: Int(noiseView.frame.height), zoom: zoom.doubleValue, octave: octave.doubleValue, persistence: persistence.doubleValue)
        let image = NSImage(CGImage: noiseResult.img, size: NSSize(width: noiseView.frame.width, height: noiseView.frame.height))
        noiseView.image = image
        timeLbl.stringValue = "Render time: \(Double(round(1000*noiseResult.renderTime)/1000)) seconds"
    }
    
    @IBAction func newImageRequested(sender: NSButton){
        newImage()
    }
    
    @IBAction func sliderValueChanged(sender: NSSlider){
        octaveLbl.stringValue = "\(octave.doubleValue)"
        zoomLbl.stringValue = "\(zoom.doubleValue)"
        persistenceLbl.stringValue = "\(persistence.doubleValue)"
        newImage()
    }

    
}

