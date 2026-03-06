# Bilibili AI Blog Toolkit 📺✨

> **无需挂载繁重无头浏览器，直接从视频流提取纯净字幕与关键帧。专为大模型/AI Agent 打造的“b站学习转博客”终极轻量知识抓取管道！**

如果你是一个喜欢在 B站 学习硬核教程（如王道考研、后端架构等）的极客，并且习惯用 AI 帮你整理学习笔记，那么这个工具链正是为你准备的。

## ⚠️ 版权与免责声明 (Disclaimer)
**本项目仅供个人学习、整理笔记以及自动化本地工作流研究使用。**
请尊重原作者的知识产权和劳动成果。切勿将通过本工具提取的受版权保护的字幕或视频截图用于任何未经授权的商业用途或公共分发。工具本身无罪，取决于你怎么使用它。

## ✨ 这是什么工作原理？

通常网页爬虫有两种：
1. **传统方法**：使用 Python + Selenium / Playwright。启动一个庞大的浏览器，还得模拟人手去解决验证码登录，并且截出来的图经常带上播放进度条、弹幕和网页 UI。
2. **本工具（降维打击）**：利用 `yt-dlp` 和 `ffmpeg` 的底层能力。
   - **免人工登录**：直接在后台调用你本机默认浏览器（支持 Chrome/Edge/Safari 等）的本地 Cookie 数据库，实现接口级身份认证。
   - **最高清纯净画面**：并不依靠“浏览器截图”，而是直接向 B站 视频流服务器（CDN）请求原片那几秒的视频片段，然后用 `ffmpeg` 抽取**单帧（1/50秒级别）**。截出来的 PPT 画面极致干净、无损。

## 📦 依赖安装

在使用本项目之前，请确保你的系统环境中安装了以下两个神器（MacOS 用户可以直接用 homebrew 安装）：

```bash
brew install yt-dlp
brew install ffmpeg
```

## 🛠️ 如何使用？

本仓库包含两个核心 Shell 脚本和一个用于文本清洗的 Python 脚本。

### 1. 抓取字幕文件 (fetch_bili_subtitle.sh)
这个脚本会自动携带你的本地浏览器 Cookie 去请求并下载指定视频的 SRT 字幕（优先下载官方/AI生成的中文 CC 字幕）。

```bash
# 用法: 
# ./scripts/fetch_bili_subtitle.sh <bilibili_url> [sub_lang] [output_dir]

# 示例: 提取王道 OS 第 6 集的字幕到 /tmp/bili_sub 目录
./scripts/fetch_bili_subtitle.sh 'https://www.bilibili.com/video/BV1zV2QBtE39/?p=6' ai-zh /tmp/bili_sub
```

### 2. 精准无损提取关键帧截图 (screenshot_bili_frame.sh)
这个脚本根据你给的时间戳，绕过防盗链机制，直接从视频原流中抽出一帧保存为图片。可以完美平替边看边手动截图。

```bash
# 用法:
# ./scripts/screenshot_bili_frame.sh <bilibili_url> <timestamp> <output_dir> [filename]

# 示例: 截取 P6 视频在 04分30秒 时的 PPT 画面
./scripts/screenshot_bili_frame.sh 'https://www.bilibili.com/video/BV1zV2QBtE39/?p=6' 04:30 ./images/ 'p6_process_state.png'
```

### 3. 字幕转文本 (srt_to_txt_and_stats.py)
大模型读带有时间戳的 SRT 有时候会容易分散注意力，这个脚本可以把 SRT 净化成纯文本段落。

```bash
python3 ./scripts/srt_to_txt_and_stats.py /tmp/bili_sub/BV1zV2QBtE39_p6.ai-zh.srt
```

## 💡 进阶：更换你的默认浏览器

默认情况下，脚本读取的是本机的 `chrome` 浏览器的 Cookie。如果你使用的是 Edge 或 Safari，只需在运行脚本前注入或修改环境变量。

可以在脚本内直接修改 `--cookies-from-browser` 参数：
- `--cookies-from-browser edge`
- `--cookies-from-browser safari`
- `--cookies-from-browser firefox`

## 🤖 配合 AI 变身“全自动博客写手”

有了纯净的文字原料和精美的插图，剩下的就是交给 AI（如 Claude, ChatGPT）了。我们为你准备了一套**开箱即用的 Prompt 提示词模板**，请见本仓库下的 `PROMPT_TEMPLATE.md`。把你净化好的文本丢进这个模板发给大模型，一篇原汁原味的高质量排版博客就会瞬间产生。
