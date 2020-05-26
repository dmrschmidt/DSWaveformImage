//
//  SpectralView.swift
//  TempiHarness
//
//  Created by John Scalo on 1/20/16.
//  Copyright © 2016 John Scalo. All rights reserved.
//

import UIKit

public class SpectralView: UIView {

    public var fft: TempiFFT!

    override public func draw(_ rect: CGRect) {
        
        if fft == nil {
            return
        }
        
        let context = UIGraphicsGetCurrentContext()
        
        self.drawSpectrum(context: context!)
        
        // We're drawing static labels every time through our drawRect() which is a waste.
        // If this were more than a demo we'd take care to only draw them once.
        self.drawLabels(context: context!)
    }
    
    private func drawSpectrum(context: CGContext) {
        let viewWidth = self.bounds.size.width
        let viewHeight = self.bounds.size.height
        let plotYStart: CGFloat = 48.0
        
        context.saveGState()
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: 0, y: -viewHeight)
        
        let colors = [UIColor.green.cgColor, UIColor.yellow.cgColor, UIColor.red.cgColor]
        let gradient = CGGradient(
            colorsSpace: nil, // generic color space
            colors: colors as CFArray,
            locations: [0.0, 0.3, 0.6])
        
        var x: CGFloat = 0.0
        
        let count = fft.numberOfBands
        
        // Draw the spectrum.
        let maxDB: Float = 256.0
        let minDB: Float = 0
        let headroom = maxDB - minDB
        let scale: CGFloat = UIScreen.main.scale
        let colWidth = round((viewWidth / CGFloat(count)) * scale) / scale
        
        for i in 0..<count {
            let magnitude = fft.magnitudeAtBand(i)
            
            // Incoming magnitudes are linear, making it impossible to see very low or very high values. Decibels to the rescue!
            var magnitudeDB = TempiFFT.toDB(magnitude)
            
            // Normalize the incoming magnitude so that -Inf = 0
            magnitudeDB = max(0, magnitudeDB + abs(minDB))
            
            let dbRatio = min(1.0, magnitudeDB / headroom)
            let magnitudeNorm = CGFloat(dbRatio) * viewHeight
            
            let colRect: CGRect = CGRect(x: x, y: plotYStart, width: colWidth, height: magnitudeNorm)
            
            let startPoint = CGPoint(x: viewWidth / 2, y: 0)
            let endPoint = CGPoint(x: viewWidth / 2, y: viewHeight)
            
            context.saveGState()
            context.clip(to: colRect)
            context.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))
            context.restoreGState()
            
            x += colWidth
        }
        
        context.restoreGState()
    }
    
    private func drawLabels(context: CGContext) {
        let viewWidth = self.bounds.size.width
        let viewHeight = self.bounds.size.height
        
        context.saveGState()
        context.translateBy(x: 0, y: viewHeight);
        
        let pointSize: CGFloat = 15.0
        let font = UIFont.systemFont(ofSize: 12)
        
        let freqLabelStr = "Frequency (kHz)"
        var attrStr = NSMutableAttributedString(string: freqLabelStr)
        attrStr.addAttribute(.font, value: font, range: NSMakeRange(0, freqLabelStr.count))
        attrStr.addAttribute(.foregroundColor, value: UIColor.yellow, range: NSMakeRange(0, freqLabelStr.count))
        
        var x: CGFloat = viewWidth / 2.0 - attrStr.size().width / 2.0
        attrStr.draw(at: CGPoint(x: x, y: -22))
        
        let labelStrings: [String] = ["5", "10", "15", "20"]
        let labelValues: [CGFloat] = [5000, 10000, 15000, 20000]
        let samplesPerPixel: CGFloat = CGFloat(fft.sampleRate) / 2.0 / viewWidth
        for i in 0..<labelStrings.count {
            let str = labelStrings[i]
            let freq = labelValues[i]
            
            attrStr = NSMutableAttributedString(string: str)
            attrStr.addAttribute(.font, value: font, range: NSMakeRange(0, str.count))
            attrStr.addAttribute(.foregroundColor, value: UIColor.yellow, range: NSMakeRange(0, str.count))
            
            x = freq / samplesPerPixel - pointSize / 2.0
            attrStr.draw(at: CGPoint(x: x, y: -40))
        }
        
        context.restoreGState()
    }
}
