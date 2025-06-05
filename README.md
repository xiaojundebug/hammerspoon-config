# hammerspoon-config

hammerspoon 是一个 macOS 上的自动化工具，它允许你通过 lua 脚本对系统做出操控，该仓库记录了我常用的一些脚本

## 脚本列表

- [auto_switch_input_method.lua](./modules/auto_switch_input_method.lua) - 根据 App 自动切换输入法，再也不用担心把「npm」打成「你配吗」
- [input_method_indicator.lua](./modules/input_method_indicator.lua) - 给输入法设置一个指示器，这样应用全屏时也能一眼看到你此时的输入法是哪个了，可以一定程度上代替 [ShowyEdge](https://github.com/pqrs-org/ShowyEdge/)
- [caffeine.lua](./modules/caffeine.lua) - 防止屏幕进入睡眠
- [wifi_mute.lua](./modules/wifi_mute.lua) - 连接到公司 Wi-Fi 后自动静音
- [defeating_paste_blocking.lua](./modules/defeating_paste_blocking.lua) - 有些网站禁止粘贴，该脚本可以模拟系统输入事件绕过限制
- [ring.lua](./modules/ring.lua) - 环形 App 启动器
- [magspeed_smooth_scrolling_fix.lua](./modules/magspeed_smooth_scrolling_fix.lua) - 罗技无极滚轮鼠标回滚问题优化
- [arrow_keys_remapping.lua](./modules/arrow_keys_remapping.lua) - 将 W / A / S / D 映射为方向键，右手无需频繁移动到右下角按方向键

## 怎么使用

把仓库中所有内容都放到你的 `~/.hammerspoon` 目录中即可

> _你可能使用的和我不是同一种输入法，所以需要修改一下 `auto_switch_input_method` 与 `input_method_indicator` 的配置，你可以通过 `defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources | grep "Input Mode"` 来查看当前输入法 Source ID_
