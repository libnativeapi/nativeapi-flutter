import Cocoa
import ObjectiveC.runtime

extension NSWindow {
    // Call this early in app lifecycle (applicationWillFinishLaunching / didFinishLaunching)
    static func enableSwizzling() {
        _ = Self._swizzleOnce
    }

    // Ensures swizzling runs exactly once and is thread-safe.
    private static let _swizzleOnce: Void = {
        let original = #selector(NSWindow.init(contentRect:styleMask:backing:defer:))
        let swizzled = #selector(NSWindow.swizzled_init(contentRect:styleMask:backing:defer:))
        guard
            let originalMethod = class_getInstanceMethod(NSWindow.self, original),
            let swizzledMethod = class_getInstanceMethod(NSWindow.self, swizzled)
        else {
            assertionFailure("[Swizzle] Failed to find methods for NSWindow init swizzling")
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)

        // Swizzle makeKeyAndOrderFront(_:)
        let originalMakeKey = #selector(NSWindow.makeKeyAndOrderFront(_:))
        let swizzledMakeKey = #selector(NSWindow.swizzled_makeKeyAndOrderFront(_:))
        guard
            let originalMakeKeyMethod = class_getInstanceMethod(NSWindow.self, originalMakeKey),
            let swizzledMakeKeyMethod = class_getInstanceMethod(NSWindow.self, swizzledMakeKey)
        else {
            assertionFailure("[Swizzle] Failed to find methods for makeKeyAndOrderFront swizzling")
            return
        }
        method_exchangeImplementations(originalMakeKeyMethod, swizzledMakeKeyMethod)
    }()

    // MARK: - Swizzled implementation

    // This will be called instead of the original init(contentRect:styleMask:backing:defer:)
    @objc dynamic func swizzled_init(
        contentRect rect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) -> NSWindow {
        // Because we've swapped implementations, calling swizzled_init(...) actually calls the original init(...)
        let window = self.swizzled_init(contentRect: rect, styleMask: style, backing: backingType, defer: flag)
        Self.configureDefaultAppearance(for: window)
        return window
    }

    // Intercepts makeKeyAndOrderFront(_:) calls
    @objc dynamic func swizzled_makeKeyAndOrderFront(_ sender: Any?) {
        NSLog("[Swizzle] Intercepted makeKeyAndOrderFront for window: \(String(describing: self))")

        self.center()
        // Because we've swapped implementations, calling swizzled_makeKeyAndOrderFront(_:) actually calls the original
        self.swizzled_makeKeyAndOrderFront(sender)
    }

    // MARK: - Appearance configuration
    private static func configureDefaultAppearance(for window: NSWindow) {
        window.hasShadow = false
        window.isOpaque = false
        window.backgroundColor = NSColor.clear

        if #available(macOS 10.12, *) {
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
        }

        // window.alphaValue = 0.5
        NSLog("[Swizzle] Modified NSWindow: \(String(describing: window))")
    }
}
