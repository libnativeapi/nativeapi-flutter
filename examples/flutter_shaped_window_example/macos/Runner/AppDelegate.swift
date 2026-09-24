// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa
import FlutterMacOS
import QuartzCore

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  var engine: FlutterEngine?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    engine = FlutterEngine(name: "project", project: nil)
    engine?.run(withEntrypoint:nil)
    let channel = FlutterMethodChannel(name: "shape_demo/resize", binaryMessenger: engine!.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "setContentSize" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
            let address = args["window"] as? NSNumber,
            let size = args["size"] as? Double,
            size.isFinite, size > 0, size <= 400,
            let window = NSApp.windows.first(where: {
              UInt(bitPattern: Unmanaged.passUnretained($0).toOpaque()) == address.uintValue
            }) else {
        result(FlutterError(code: "invalid_resize", message: "Preview window or size is invalid", details: nil))
        return
      }
      // Dart must return to its event loop before AppKit waits for a new raster
      // frame. Never perform this synchronous resize through Dart FFI.
      // The core contour is expressed in the content view's layer coordinates.
      // For an unflipped view its Y origin depends on the surface height. Resize
      // the surface and rebase that mask in one transaction, before Flutter can
      // present the resized frame. Waiting for the next Dart callback exposes a
      // frame with the old mask coordinates at the animation endpoint.
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      let view = window.contentView
      let previousHeight = view?.bounds.height ?? 0
      let mask = view?.layer?.mask as? CAShapeLayer
      let isCoreMask = mask?.name == "nativeapi.windowShape"
      if isCoreMask, let view = view, let mask = mask {
        if !view.isFlipped, let path = mask.path {
          var translation = CGAffineTransform(translationX: 0, y: size - previousHeight)
          mask.path = path.copy(using: &translation)
        }
        mask.frame = CGRect(x: view.bounds.minX, y: view.bounds.minY, width: size, height: size)
      }
      window.setContentSize(NSSize(width: size, height: size))
      CATransaction.commit()
      result(nil)
    }
  }
}
