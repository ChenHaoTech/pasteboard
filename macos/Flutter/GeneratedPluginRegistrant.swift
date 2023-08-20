//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import clipboard_watcher
import desktop_multi_window
import hotkey_manager
import keypress_simulator
import pasteboard
import path_provider_foundation
import screen_retriever
import sqflite
import window_manager

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  ClipboardWatcherPlugin.register(with: registry.registrar(forPlugin: "ClipboardWatcherPlugin"))
  FlutterMultiWindowPlugin.register(with: registry.registrar(forPlugin: "FlutterMultiWindowPlugin"))
  HotkeyManagerPlugin.register(with: registry.registrar(forPlugin: "HotkeyManagerPlugin"))
  KeypressSimulatorPlugin.register(with: registry.registrar(forPlugin: "KeypressSimulatorPlugin"))
  PasteboardPlugin.register(with: registry.registrar(forPlugin: "PasteboardPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  ScreenRetrieverPlugin.register(with: registry.registrar(forPlugin: "ScreenRetrieverPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  WindowManagerPlugin.register(with: registry.registrar(forPlugin: "WindowManagerPlugin"))
}
