# flutter_pasteboard

A clipboard manager for desktop written in Flutter.

| macOS | Windows | Linux |
| :---: | :---: | :---: |
| ✅ | ✅ | ❌ |

`Attention: Windows not test yet.`

## Screenshots

<img src="./screenshot.png" width="220" >

## Setup

1. Install [Flutter](https://flutter.dev/docs/get-started/install)
2. git clone this repository
3. flutter pub get
4. flutter run

## related

1. [clipboard_watcher](https://github.com/leanflutter/clipboard_watcher)
2. [window_manager](https://github.com/leanflutter/window_manager)
3. [screen_retriever](https://github.com/leanflutter/screen_retriever)
4. [keypress_simulator](https://github.com/leanflutter/keypress_simulator)
5. [hotkey_manager](https://github.com/leanflutter/hotkey_manager)
6. [pasteboard](https://github.com/MixinNetwork/flutter-plugins/tree/main/packages/pasteboard)

## License

MIT License

Copyright (c) 2023 这一点都不环保



## TODO
**feature**
- [] command+option+p : pin windo 置顶窗口  setAlwaysOnTop
- [] widnow can resize able
- [] window can move able
- [] search text auto focus
  - [https://github.com/leanflutter](https://github.com/leanflutter/window_manager)
- [] fix why restart cannnot bind keyboard
- [] why flutter: │ ⛔ DatabaseException(Error Domain=FMDatabase Code=2067 "UNIQUE constraint failed: pasteboard_item.sha256" UserInfo={NSLocalizedDescription=UNIQUE constraint failed: pasteboard_item.sha256}) sql 'INSERT INTO pasteboard_item (id, type, text, image, sha256, create_time, path) VALUES (NULL, ?, ?, NULL, ?, ?, NULL)' args [0, data, 3a6eb0790f39ac87c94f3856b2dd2c5d110e6811602261a9a9..., 1691768093461]
- [] 窗口位置算的不太准


- [] Linux support
- [] Windows test
- [] Linux test
