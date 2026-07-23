# LyricsBar

[中文](#中文说明) | [English](#english)

## 中文说明

在 macOS 刘海右侧以原生菜单栏项目、小号单行文字显示 Apple Music 当前歌曲的同步歌词。程序从 Music 读取歌曲和播放进度，并使用 LRCLIB 匹配同步歌词。

## 功能

- 原生 macOS 菜单栏显示，自动位于刘海右侧
- 歌词宽度随内容变化，空间不足时自动省略
- 根据 Apple Music 播放进度切换当前歌词
- 精确匹配失败时自动清理版本后缀并按歌手、歌名和时长选择最接近的歌词
- 内置字体设置窗口，可实时修改字体样式、字号、粗细和颜色
- 软件界面自动跟随 macOS 系统语言显示中文或英文
- 无第三方编译依赖
- 点击菜单栏歌词即可退出

## 使用

1. 双击 `dist/LyricsBar.app`。
2. 第一次运行时允许 LyricsBar 控制“音乐”（系统设置 → 隐私与安全性 → 自动化）。
3. 播放歌曲。菜单栏会显示当前歌词；点击歌词可调整字体或退出。

如果 macOS 阻止打开，请在 Finder 中右键应用并选择“打开”。

## 重新编译

```sh
./build.sh
```

需要联网来匹配歌词。并非 Apple Music 曲库内的歌词都可由公开接口取得；找不到时会显示歌名和歌手。

## 系统要求

- Apple Silicon 或 Intel Mac（Universal 2）
- macOS 12 或更高版本
- Apple Music

## 隐私

LyricsBar 只读取当前歌曲名称、歌手、专辑、时长和播放位置，并将歌曲信息发送给 LRCLIB 用于匹配歌词。项目不收集或保存个人信息。

---

## English

LyricsBar displays time-synced Apple Music lyrics as a compact, native menu-bar item on the right side of the MacBook notch. It reads the current track and playback position from Music and finds synchronized lyrics through LRCLIB.

### Features

- Native macOS menu-bar integration
- Updates the current line using Apple Music playback position
- Falls back to fuzzy matching by cleaned title, artist, and duration
- Built-in settings for font style, size, weight, and color
- Interface automatically follows the macOS system language in Chinese or English
- Universal 2 build for Apple Silicon and Intel Macs
- No third-party build dependencies

### Installation

1. Download and unzip `LyricsBar-macOS-Universal.zip`.
2. Right-click `LyricsBar.app` and choose **Open**.
3. Allow LyricsBar to control Music when macOS asks.
4. Start playing a song in Apple Music.

Click the lyric in the menu bar to open font settings or quit the app. An internet connection is required to find lyrics. Some Apple Music tracks may not have synchronized lyrics in the public LRCLIB database; LyricsBar displays the track title and artist when no match is available.

### Build from source

```sh
./build.sh
```

### Requirements

- Apple Silicon or Intel Mac (Universal 2)
- macOS 12 or later
- Apple Music

### Privacy

LyricsBar reads only the current track title, artist, album, duration, and playback position. Track metadata is sent to LRCLIB solely to find lyrics. LyricsBar does not collect or retain personal information.
# LyricsBar

[中文](#中文说明) | [English](#english)

## 中文说明

在 macOS 刘海右侧以原生菜单栏项目、小号单行文字显示 Apple Music 当前歌曲的同步歌词。程序从 Music 读取歌曲和播放进度，并使用 LRCLIB 匹配同步歌词。

## 功能

- 原生 macOS 菜单栏显示，自动位于刘海右侧
- 歌词宽度随内容变化，空间不足时自动省略
- 根据 Apple Music 播放进度切换当前歌词
- 精确匹配失败时自动清理版本后缀并按歌手、歌名和时长选择最接近的歌词
- 内置字体设置窗口，可实时修改字体样式、字号、粗细和颜色
- 无第三方编译依赖
- 点击菜单栏歌词即可退出

## 使用

1. 双击 `dist/LyricsBar.app`。
2. 第一次运行时允许 LyricsBar 控制“音乐”（系统设置 → 隐私与安全性 → 自动化）。
3. 播放歌曲。菜单栏会显示当前歌词；点击歌词可调整字体或退出。

如果 macOS 阻止打开，请在 Finder 中右键应用并选择“打开”。

## 重新编译

```sh
./build.sh
```

需要联网来匹配歌词。并非 Apple Music 曲库内的歌词都可由公开接口取得；找不到时会显示歌名和歌手。

## 系统要求

- Apple Silicon 或 Intel Mac（Universal 2）
- macOS 12 或更高版本
- Apple Music

## 隐私

LyricsBar 只读取当前歌曲名称、歌手、专辑、时长和播放位置，并将歌曲信息发送给 LRCLIB 用于匹配歌词。项目不收集或保存个人信息。

---

## English

LyricsBar displays time-synced Apple Music lyrics as a compact, native menu-bar item on the right side of the MacBook notch. It reads the current track and playback position from Music and finds synchronized lyrics through LRCLIB.

### Features

- Native macOS menu-bar integration
- Updates the current line using Apple Music playback position
- Falls back to fuzzy matching by cleaned title, artist, and duration
- Built-in settings for font style, size, weight, and color
- Universal 2 build for Apple Silicon and Intel Macs
- No third-party build dependencies

### Installation

1. Download and unzip `LyricsBar-macOS-Universal.zip`.
2. Right-click `LyricsBar.app` and choose **Open**.
3. Allow LyricsBar to control Music when macOS asks.
4. Start playing a song in Apple Music.

Click the lyric in the menu bar to open font settings or quit the app. An internet connection is required to find lyrics. Some Apple Music tracks may not have synchronized lyrics in the public LRCLIB database; LyricsBar displays the track title and artist when no match is available.

### Build from source

```sh
./build.sh
```

### Requirements

- Apple Silicon or Intel Mac (Universal 2)
- macOS 12 or later
- Apple Music

### Privacy

LyricsBar reads only the current track title, artist, album, duration, and playback position. Track metadata is sent to LRCLIB solely to find lyrics. LyricsBar does not collect or retain personal information.
