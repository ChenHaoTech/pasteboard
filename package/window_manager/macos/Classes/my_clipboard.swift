//
//  my_clipboard.swift
//  Pods
//
//  Created by apple on 2023/10/11.
//

import Foundation
import AppKit
import Sauce
import Carbon

class KeyboardLayout {
  static var current: KeyboardLayout { KeyboardLayout() }

  // Dvorak - QWERTY ⌘ (https://github.com/p0deje/Maccy/issues/482)
  // bépo 1.1 - Azerty ⌘ (https://github.com/p0deje/Maccy/issues/520)
  var commandSwitchesToQWERTY: Bool { localizedName.hasSuffix("⌘") }

  var localizedName: String {
    if let value = TISGetInputSourceProperty(inputSource, kTISPropertyLocalizedName) {
      return Unmanaged<CFString>.fromOpaque(value).takeUnretainedValue() as String
    } else {
      return ""
    }
  }

  private var inputSource: TISInputSource!

  init() {
    inputSource = TISCopyCurrentKeyboardLayoutInputSource().takeUnretainedValue()
  }
}


class Clipboard {
  static let shared = Clipboard()

  var changeCount: Int

  private let pasteboard = NSPasteboard.general
  private let timerInterval = 1.0

  private let dynamicTypePrefix = "dyn."
  private let microsoftSourcePrefix = "com.microsoft.ole.source."
  private let supportedTypes: Set<NSPasteboard.PasteboardType> = [
    .fileURL,
    .html,
    .png,
    .rtf,
    .string,
    .tiff
  ]
  


  

  private var sourceApp: NSRunningApplication? { NSWorkspace.shared.frontmostApplication }

  private var accessibilityAlert: NSAlert {
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = NSLocalizedString("accessibility_alert_message", comment: "")
    alert.informativeText = NSLocalizedString("accessibility_alert_comment", comment: "")
    alert.addButton(withTitle: NSLocalizedString("accessibility_alert_deny", comment: ""))
    alert.addButton(withTitle: NSLocalizedString("accessibility_alert_open", comment: ""))
    alert.icon = NSImage(named: "NSSecurity")
    return alert
  }
  private var accessibilityAllowed: Bool { AXIsProcessTrustedWithOptions(nil) }
  private let accessibilityURL = URL(
    string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
  )

  init() {
    changeCount = pasteboard.changeCount
  }

    static var pasteKeyModifiers: NSEvent.ModifierFlags {
      NSEvent.ModifierFlags([.command])
    }


  // Based on https://github.com/Clipy/Clipy/blob/develop/Clipy/Sources/Services/PasteService.swift.
  func paste() {
   
    DispatchQueue.main.async {
        let cmdFlag = CGEventFlags(rawValue: UInt64(Clipboard.pasteKeyModifiers.rawValue) | 0x000008)
      var vCode = Sauce.shared.keyCode(for: .v)

      let source = CGEventSource(stateID: .combinedSessionState)
      // Disable local keyboard events while pasting
      source?.setLocalEventsFilterDuringSuppressionState([.permitLocalMouseEvents, .permitSystemDefinedEvents],
                                                         state: .eventSuppressionStateSuppressionInterval)

      let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: vCode, keyDown: true)
      let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: vCode, keyDown: false)
      keyVDown?.flags = cmdFlag
      keyVUp?.flags = cmdFlag
      keyVDown?.post(tap: .cgAnnotatedSessionEventTap)
      keyVUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
  }

}
