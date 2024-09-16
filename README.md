# hammerspoon-config

hammerspoon 是一个 macOS 上的自动化工具，它允许你通过 lua 脚本对系统做出操控，该仓库记录了我常用的一些脚本

## 脚本列表

- [input-method-indicator.lua](./scripts/input-method-indicator.lua) - 给输入法设置一个指示器，这样应用全屏时也能一眼看到你此时的输入法是哪个了，可以取代 [ShowyEdge](https://github.com/pqrs-org/ShowyEdge/)
- [auto-switch-input-method.lua](./scripts/auto-switch-input-method.lua) - 根据 App 切换对应输入法，再也不用担心把「npm」打成「你配吗」
- [ring.lua](./scripts/ring.lua) - 环形 app 启动器
- [caffeinated.lua](./scripts/caffeinated.lua) - 防止屏幕进入休眠
- [wifi-mute.lua](./scripts/wifi-mute.lua) - 连接到公司 wifi 后自动静音扬声器
- [defeating-paste-blocking.lua](./scripts/defeating-paste-blocking.lua) - 有些网站禁止粘贴，该脚本可以模拟系统输入事件绕过限制
- [magspeed-smooth-scrolling-fix.lua](./scripts/magspeed-smooth-scrolling-fix.lua) - 罗技无极滚轮鼠标回滚问题尝试性优化

## 怎么使用

直接把所有 lua 脚本都放到你的 hammerspoon 目录中即可，其中 `bookmarks.lua`、`hidden-compartment.lua` 是我的个人隐私脚本，所以你需要将它从 `init.lua` 中去掉，否则将报错

> _你可能使用的和我不是同一种输入法，所以需要修改一下 `auto-switch-input-method` 与 `input-method-indicator` 的配置，你可以通过 `defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources | grep "Input Mode"` 来查看当前输入法 Source ID_