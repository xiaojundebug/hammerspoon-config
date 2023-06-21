# hammerspoon-config

hammerspoon 是一个 macOS 上的自动化工具，它允许你通过 lua 脚本对系统做出操控，该仓库记录了我常用的一些脚本

## 脚本列表

- [input-method-indicator.lua](input-method-indicator.lua) - 给输入法设置一个指示器，这样应用全屏时也能一眼看到你此时的输入法是哪个了，可以取代 [ShowyEdge](https://github.com/pqrs-org/ShowyEdge/)
- [auto-switch-input-method.lua](auto-switch-input-method.lua) - 根据 App 切换对应输入法，妈妈再也不用担心我把「npm」 打成「你怕吗」了
- [wifi-mute.lua](wifi-mute.lua) - 连接到公司 wifi 后自动静音扬声器
- [defeating-paste-blocking.lua](defeating-paste-blocking.lua) - 有些网站禁止粘贴，该脚本可以模拟系统输入事件绕过限制
- [auto-quit-wechat.lua](auto-quit-wechat.lua) - 电脑屏幕关闭一段时间后自动退出微信，避免手机上收不到消息

## 怎么使用

直接把所有 lua 脚本都放到你的 hammerspoon 目录中即可
