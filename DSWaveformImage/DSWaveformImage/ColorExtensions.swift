import UIKit

extension UIColor {
    var inverted: UIColor {
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: 1 - r, green: 1 - g, blue: 1 - b, alpha: a)
    }

    var highlighted: UIColor {
        return highlighted(brightnessAdjustment: 0.2)
    }

    func highlighted(brightnessAdjustment: CGFloat) -> UIColor {
        var hue: CGFloat = 0.0, saturation: CGFloat = 0.0, brightness: CGFloat = 0.0, alpha: CGFloat = 0.0
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let brightnessAdjustment: CGFloat = brightnessAdjustment
        let adjustmentModifier: CGFloat = brightness < brightnessAdjustment ? 1 : -1
        let newBrightness = brightness + brightnessAdjustment * adjustmentModifier
        return UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
    }
}
