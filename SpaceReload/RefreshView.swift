//
//  RefreshView.swift
//  SpaceReload
//
//  Created by Alex Gibson on 22/10/2020.
//

import UIKit
import RiveRuntime

class RefreshView: UIView {

    private var resourceName: String = "space_reload"
    private var artboard: RiveArtboard?
    private var displayLink: CADisplayLink?
    private var lastTime: CFTimeInterval = 0
    
    private var idle: RiveLinearAnimationInstance?
    private var pull: RiveLinearAnimationInstance?
    private var trigger: RiveLinearAnimationInstance?
    private var loading: RiveLinearAnimationInstance?
    
    let frameHeight: CGFloat
    var isRefreshing: Bool = false
    var _pulledExtent: CGFloat = 0.0
    var pulledExtent: CGFloat {
        set { _pulledExtent = -newValue }
        get { return _pulledExtent }
    }
    
    var isPaused: Bool = false {
        didSet {
            displayLink?.isPaused = isPaused
        }
    }
    
    required init(frameHeight: CGFloat) {
        self.frameHeight = frameHeight
        super.init(frame: .zero)
        initRive()
    }
    
    private override init(frame: CGRect) {
        self.frameHeight = 180
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(),
              let artboard = self.artboard else {
            return
        }
        let renderer = RiveRenderer(context: context);
        renderer.align(with: rect,
                       withContentRect: artboard.bounds(),
                       with: .Center,
                       with: .Cover)
        artboard.draw(renderer)
    }
    
    func initRive() {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "riv") else {
            fatalError("Failed to locate \(resourceName) in bundle.")
        }
        guard var data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(url) from bundle.")
        }
        
        // Import the data into a RiveFile
        let bytes = [UInt8](data)
        
        data.withUnsafeMutableBytes{(riveBytes:UnsafeMutableRawBufferPointer) in
            guard let rawPointer = riveBytes.baseAddress else {
                fatalError("File pointer is messed up")
            }
            let pointer = rawPointer.bindMemory(to: UInt8.self, capacity: bytes.count)
            
            guard let riveFile = RiveFile(bytes:pointer, byteLength: UInt64(bytes.count)) else {
                fatalError("Failed to import \(url).")
            }
            
            let artboard = riveFile.artboard()
            
            if (artboard.animationCount() == 0) {
                fatalError("No animations in the file.")
            }
                        
            let idleAnimation = artboard.animation(at: 0)
            self.idle = idleAnimation.instance()
            
            let pullAnimation = artboard.animation(at: 1)
            self.pull = pullAnimation.instance()
            self.pull?.setTime(1)
            
            let triggerAnimation = artboard.animation(at: 2)
            self.trigger = triggerAnimation.instance()
            
            let loadingAnimation = artboard.animation(at: 3)
            self.loading = loadingAnimation.instance()

            self.artboard = artboard
            
            // Run the looping timer
            initTimer()
        }
    }
    
    // Starts the animation timer
    func initTimer() {
        displayLink = CADisplayLink(target: self, selector: #selector(apply));
        displayLink?.add(to: .main, forMode: .common)
    }
    
    // Stops the animation timer
    func removeTimer() {
        displayLink?.remove(from: .main, forMode: .common)
    }
    
    // Animates a frame
    @objc func apply() {
        
        guard let displayLink = displayLink,
              let artboard = artboard else {
            removeTimer()
            return
        }
        
        let timestamp = displayLink.timestamp
        
        if (lastTime == 0) {
            lastTime = timestamp
        }
        
        // Calculate the time elapsed between ticks
        let elapsedTime = timestamp - lastTime
        lastTime = timestamp;
        
        let idleTime = idle?.time() ?? 0
        idle?.animation().apply(idleTime, to: artboard)
        idle?.advance(by: elapsedTime)
        
        if trigger?.time() == 0 {
            let pos = Float(_pulledExtent / frameHeight)
            let pullTime = pull?.time() ?? 1
            pull?.animation().apply(pullTime * pos, to: artboard)
        }
            
        if isRefreshing {
            let triggerTime = trigger?.time() ?? 0
            trigger?.animation().apply(triggerTime, to: artboard)
            trigger?.advance(by: elapsedTime)
            if trigger?.hasCompleted ?? false {
                let loadingTime = loading?.time() ?? 0
                loading?.animation().apply(loadingTime, to: artboard)
                loading?.advance(by: elapsedTime)
            }
        }
        
        artboard.advance(by: elapsedTime)
        setNeedsDisplay()
    }
    
    func reset() {
        loading?.setTime(0)
        trigger?.setTime(0)
        if let artboard = artboard {
            loading?.animation().apply(0, to: artboard)
            trigger?.animation().apply(0, to: artboard)
        }
    }
}

extension RiveLinearAnimationInstance {
    var hasCompleted: Bool {
        let anim = self.animation()
        let time = self.time()
        return time >= Float(anim.workEnd() / anim.fps())
    }
}
