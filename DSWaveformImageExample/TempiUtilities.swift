//
//  TempiUtilities.swift
//  TempiFFT
//
//  Created by John Scalo on 1/8/16.
//  Copyright © 2016 John Scalo. See accompanying License.txt for terms.

import Foundation
import UIKit

func tempi_dispatch_main(closure:@escaping ()->()) {
    DispatchQueue.main.async {
        closure()
    }
}

func tempi_dispatch_delay(delay:Double, closure:@escaping ()->()) {
    
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        closure()
    }
}

func tempi_round_device_scale(d: CGFloat) -> CGFloat
{
    let scale: CGFloat = UIScreen.main.scale
    return round(d * scale) / scale
}
