//
//  RiveRefreshControl.swift
//  SpaceReload
//
//  Created by Alex Gibson on 20/10/2020.
//

import UIKit
import RiveRuntime

class RiveRefreshControl: UIRefreshControl {

    fileprivate var resourceName: String = "space_reload"
    fileprivate var artboard: RiveArtboard?
    fileprivate var riveView: RiveView?
    fileprivate var displayLink: CADisplayLink?
    fileprivate var lastTime: CFTimeInterval = 0
    
    fileprivate var idleInstance: RiveLinearAnimationInstance?
    fileprivate var pullInstance: RiveLinearAnimationInstance?
    fileprivate var triggerInstance: RiveLinearAnimationInstance?
    fileprivate var loadingInstance: RiveLinearAnimationInstance?
    
    let frameHeight: CGFloat = 60
    var _pulledExtent: CGFloat = 0.0
    var pulledExtent: CGFloat {
        set { _pulledExtent = -newValue }
        get { return _pulledExtent }
    }
    
    override init() {
        super.init(frame: .zero)
        setupView()
        setupLayout()
        startRive()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func beginRefreshing() {
        super.beginRefreshing()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.endRefreshing()
        }
    }

    override func endRefreshing() {
        super.endRefreshing()
    }
    
    func setupView() {
        // hide default indicator view
        tintColor = .clear
        backgroundColor = .clear
        addTarget(self, action: #selector(beginRefreshing), for: .valueChanged)
        riveView = RiveView()
        if let riveView = riveView {
            addSubview(riveView)
        }
    }
    
    func setupLayout() {
        guard let riveView = riveView else { return }
        riveView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            riveView.leadingAnchor.constraint(equalTo: leadingAnchor),
            riveView.trailingAnchor.constraint(equalTo: trailingAnchor),
            riveView.topAnchor.constraint(equalTo: topAnchor),
            riveView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    func startRive() {
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
            
            self.artboard = artboard
            riveView?.updateArtboard(artboard)
            
            if (artboard.animationCount() == 0) {
                fatalError("No animations in the file.")
            }
                        
            // Fetch two animations and advance the artboard
            let idleAnimation = artboard.animation(at: 0)
            self.idleInstance = idleAnimation.instance()
            
            let pullAnimation = artboard.animation(at: 1)
            self.pullInstance = pullAnimation.instance()
            
            let triggerAnimation = artboard.animation(at: 2)
            self.triggerInstance = triggerAnimation.instance()
            
            let loadingAnimation = artboard.animation(at: 3)
            self.loadingInstance = loadingAnimation.instance()

            artboard.advance(by: 0)
            
            // Run the looping timer
            runTimer()
        }
    }
    
    // Starts the animation timer
    func runTimer() {
        displayLink = CADisplayLink(target: self, selector: #selector(tick));
        displayLink?.add(to: .main, forMode: .common)
    }
    
    // Stops the animation timer
    func stopTimer() {
        displayLink?.remove(from: .main, forMode: .common)
    }
    
    // Animates a frame
    @objc func tick() {
        guard let displayLink = displayLink, let artboard = artboard else {
            // Something's gone wrong, clean up and bug out
            stopTimer()
            return
        }
        
        let timestamp = displayLink.timestamp
        // last time needs to be set on the first tick
        if (lastTime == 0) {
            lastTime = timestamp
        }
        // Calculate the time elapsed between ticks
        let elapsedTime = timestamp - lastTime;
        lastTime = timestamp;
        
        guard let idleInstance = idleInstance,
              let pullInstance = pullInstance,
              let triggerInstance = triggerInstance,
              let loadingInstance = loadingInstance else {
            return
        }
        
        let idleTime = idleInstance.time()
        idleInstance.animation().apply(idleTime, to: artboard)
        idleInstance.advance(by: elapsedTime)
        
        if !isRefreshing {
            let animationPosition = Float(pulledExtent / frameHeight);
            let pullTime = pullInstance.time() * animationPosition
            pullInstance.animation().apply(pullTime, to: artboard)
            pullInstance.advance(by: elapsedTime)
        } else {
            let triggerTime = triggerInstance.time()
            triggerInstance.animation().apply(triggerTime, to: artboard)
            triggerInstance.advance(by: elapsedTime)
            
            let triggerAnimation = triggerInstance.animation()
            if triggerTime >= Float(triggerAnimation.workEnd() / triggerAnimation.fps()) {
                let loadingTime = loadingInstance.time()
                loadingInstance.animation().apply(loadingTime, to: artboard)
                loadingInstance.advance(by: elapsedTime)
            }
        }
        
        artboard.advance(by: elapsedTime)
        
        // Trigger a redraw
        riveView?.setNeedsDisplay()
    }
    
    func reset() {
        guard let artboard = artboard,
              let triggerInstance = triggerInstance,
              let loadingInstance = loadingInstance else {
            return
        }
        
        triggerInstance.setTime(0)
        loadingInstance.setTime(0)
        
        let triggerTime = triggerInstance.time()
        triggerInstance.animation().apply(triggerTime, to: artboard)
        
        let loadingTime = loadingInstance.time()
        loadingInstance.animation().apply(loadingTime, to: artboard)
    }
}
