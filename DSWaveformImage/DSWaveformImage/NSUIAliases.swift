#if os(OSX)
    import AppKit

    public typealias Image = NSImage
    public typealias ImageView = NSImageView
    public typealias Color = NSColor
    public typealias Screen = NSScreen

    public var mainScreenScale:CGFloat = 1

#elseif os(iOS)

    import UIKit

    public typealias Image = UIImage
    public typealias ImageView = UIImageView
    public typealias Color = UIColor
    public typealias Screen = UIScreen

    public var mainScreenScale = Screen.main.scale

#endif
