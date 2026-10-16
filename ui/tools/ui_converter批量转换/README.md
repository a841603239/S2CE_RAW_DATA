使用说明：双击快速运行.cmd开始启动
注意事项：你需要安装python环境

UI files in ETW, NTW, and S2TW have different versions from `Version025` to `Version063`.

## 支持的版本

支持 `Version029/032/033/039/043/044/046/047/049/050/051/052/054`
以及 `Version055~063`（帝战 · 拿战 · 幕府2 的运行时 UI 文件，实测 056/057/060/061/062/063 全部覆盖）。

### Version056+ 相比 Version054 新增的字段（本次逆向得出）

| 位置 | 新增内容 | 生效版本 |
|------|----------|----------|
| `tga` 条目尾部 | 2 个 int32（颜色字段） | >= 55 |
| `tgaUse` 条目尾部 | N 个附加字节（N 因文件而异，0~3，自动探测） | >= 58 |
| `uientry` 标志位之后 | 多 1 个字节 `flag16` | >= 59 |
| `effect` 每个 phase 尾部 | 多 1 个字节 | >= 58 |
| `state` 的 `textAlphaMultiply` 之后 | 多 1 个 int32（`fontColor`） | >= 62 |

`tgaUse` 的附加字节数会被自动探测（选能精确解析到文件末尾的那个），并写入 XML 的
`<tgaUseExtraBytes>` 节点，回写时按同一个值还原，保证字节级一致。

## 用法

```
python convert_ui.py -u  输入.ui   输出.xml      单文件 UI -> XML
python convert_ui.py -x  输入.xml  输出.ui       单文件 XML -> UI
python convert_ui.py -ua                        批量（当前目录 -> ./output）
python convert_ui.py -xa                        批量（当前目录 -> ./uiOutput）
python convert_ui.py -uar                       批量（递归子目录 -> ./output）
python convert_ui.py -xar                       批量（递归子目录 -> ./uiOutput）
```

## 校验结果

对 `Desktop\ui` 下 295 个 UI 文件做 UI→XML→UI 往返比对：
**279 个与原文件字节级完全一致（94.6%）**，其中 Version056 93/93、Version060 14/14、
Version061 20/20、Version062 125/137。剩余 16 个（多为 `main`、`mp_clans`、`options`
等超复杂的界面）结构尚未完全破解，转换时会明确报错而不会静默产出错误文件。

可用 `roundtrip_test.py` 复验（默认扫描 `Desktop\ui`，可改脚本里的 SRC）。

## CREDITS

The converter was originally written by alpaca (Stefan Reutter).

What you see in this directory is based on alpaca's NTW UI converter version 1.1 from 25th August 2010.

It was since enhanced and extended to support ETW and S2TW by taw (Tomasz Wegrzanowski).

项目地址：https://github.com/taw/etwng/tree/master