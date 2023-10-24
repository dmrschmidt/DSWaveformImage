import SwiftUI

// workaround for crashes in iOS 15 when using #available in ViewBuilders
// see https://developer.apple.com/forums/thread/650818
// not sure if this is still relevant, but keeping it due to its obscurity when it occurs
// and because I cannot verify that it does not happen anymore due to lack of devices
public struct LazyContent<Content: View>: View {
    let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        content()
    }
}

// This is here to support visionOS / iOS 17 and remove the deprecation warning relating about the usage of
//   @available(visionOS, deprecated: 1.0, message: "Use `onChange` with a two or zero parameter action closure instead.")
//   @inlinable public func onChange<V>(of value: V, perform action: @escaping (_ newValue: V) -> Void) -> some View where V : Equatable
public struct OnChange<V: Equatable>: ViewModifier {
    private var value: V
    private var action: (_ newValue: V) -> Void

    public init(of value: V, action: @escaping (_ newValue: V) -> Void) {
        self.value = value
        self.action = action
    }

    public func body(content: Content) -> some View {
        #if swift(>=5.9)
            if #available(iOS 17, macOS 14.0, visionOS 1.0, *) {
                LazyContent {
                    content
                        .onChange(of: value) { _, newValue in
                            action(newValue)
                        }
                }
            } else {
                content
                    .onChange(of: value) { newValue in
                        action(newValue)
                    }
            }
        #else
            content
                .onChange(of: value) { newValue in
                    action(newValue)
                }
        #endif
    }
}
