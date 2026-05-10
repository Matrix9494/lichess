\# Codex Instructions for Lichess Mobile



\## General

\- 默认使用中文回答。

\- 不要擅自改代码，除非我明确说“改”“实现”“帮我跑”。

\- 改代码前先解释相关文件和设计原因。

\- 对 lichess 正式服务器相关内容，要区分匿名功能和登录功能。

\- 不要尝试绕过生产鉴权、secret 或安全限制。



\## Project Workflow

\- 这个项目根目录是 `lichess/`。

\- 切换 branch 后，如果生成文件不匹配，可以运行：

&#x20; `dart run build\_runner build`

\- Flutter 设备优先使用 KB2005，device id 是 `18a789b9`。

\- 如果要连正式站 debug，使用：

&#x20; `--dart-define=LICHESS\_HOST=lichess.org`

&#x20; `--dart-define=LICHESS\_WS\_HOST=socket.lichess.org`



\## Code Style

\- 先读现有模式，再决定怎么改。

\- 尽量小改，不做无关重构。

\- 不要删除用户已有改动。



