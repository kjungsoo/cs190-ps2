//
//  ViewController.swift
//  Counter
//
//  Created by Brian Hill github.com/brianhill on 1/25/16.
//

import UIKit

import QuartzCore

// I'm trying for a slight strobing effect just as the original HP calculators had. They
// had the strobing to conserve battery. We have the strobing solely to get an old-time feel.
// This will dim the LED segments 1/4 of the time:
let strobeMultiple = 4

let clockTicksPerAnimationInterval = 100 // Adjust to make calculator's computation speed realistic.

class ViewController: UIViewController {
    
    @IBOutlet weak var displayView: DisplayView?
    
    var displayLink: CADisplayLink?
    
    var prepares: Int = 0 // The number of prepareForVSync since the view appeared.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        displayLink = CADisplayLink(target:self, selector:Selector("prepareForVSync:"))
        displayLink?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode:NSRunLoopCommonModes)
        displayLink?.paused = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        prepares = 0
        displayLink?.paused = false
    }
    
    override func viewWillDisappear(animated:Bool) {
        displayLink?.paused = true
        super.viewWillDisappear(animated)
    }
    
    func prepareForVSync(displayLink: CADisplayLink) {
        let clock: Driven = Clock.sharedInstance
        for _ in 0..<clockTicksPerAnimationInterval {
            clock.drive() // should take clock from low to high
            clock.drive() // should take clock from high to low
        }
        prepares += 1
        displayView?.strobeOn = prepares % strobeMultiple != 0
        displayView?.setNeedsDisplay()
    }
    
    @IBAction func keyPressed(sender: UIButton) {
        let keyCode = KeyCode(sender.tag)
        let key = Key(rawValue: keyCode)!
        switch key {
        case Key.Key0:
            print("\(__FUNCTION__) is unimplemented for key \(key)")
        case Key.Key1:
            print("Pressed \(key)")
        case Key.Key2:
            print("Pressed \(key)")
        case Key.Key3:
            print("Pressed \(key)")
        case Key.Key4:
            print("Pressed \(key)")
        case Key.Key5:
            print("Pressed \(key)")
        case Key.Key6:
            print("Pressed \(key)")
        case Key.Key7:
            print("Pressed \(key)")
        case Key.Key8:
            print("Pressed \(key)")
        case Key.Key9:
            print("Pressed \(key)")
        case Key.KeyAdd:
            print("Pressed \(key)")
        default:
            print("\(__FUNCTION__) is unimplemented for key \(key)")
        }
    }
    
}