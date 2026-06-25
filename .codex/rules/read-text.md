## 中文读取编码

读取中文文本、Markdown 或可能输出中文内容的命令时，第一次就显式使用 UTF-8，避免先乱码再重读。PowerShell 先设置 `[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new()`；读取文件配合 `Get-Content -Encoding UTF8` 或其他明确编码的方式。

## 读取编码不等于写回编码

显式使用 UTF-8 是**读取命令的要求**，不得据此改变目标文件本身的编码、换行或格式。修改文件时必须先判断并保留原文件编码与换行风格；只有用户明确要求转换编码或格式时，才允许改写文件编码。

特别注意 `.bat`、`.cmd` 等 Windows 脚本：不要因为读取时使用 UTF-8，就擅自加入 `chcp 65001` 或把文件改成 UTF-8。中文 Windows 下批处理经常使用 ANSI/GBK，控制台代码页必须与文件实际编码匹配，否则中文会乱码或脚本行为异常。
