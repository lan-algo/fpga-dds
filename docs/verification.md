# 本地验证记录

本次验证使用 pyslang 12.1.0 与 Icarus Verilog 12.0 devel（g2693dd32b）。Icarus为临时目录中的便携工具，没有修改系统安装或PATH。

| 检查 | 状态 | 范围 |
| --- | --- | --- |
| 源列表、模块唯一性、ROM及相对链接 | passed | 15个RTL文件、18个模块、256个ROM样本 |
| slang静态检查 | passed | RTL与原课程Testbench：0 errors / 0 warnings；无警告屏蔽 |
| Icarus带断言回归 | passed | 当前COE版10/10（含256地址ROM读出）；滤波、窗口边界、完整周期、占空比、显示、按键/扫频、DDS及顶层启动 |
| 修复前对照 | reproduced | 同套9组测试对修复前快照运行：8失败、1通过 |
| Python脚本语法与文件检查 | passed | 本地辅助脚本、图片来源、相对链接、脱敏检查 |
| 原课程长波形Testbench重新运行 | not_run | 已在静态编译中检查；本次动态验证使用新断言回归，不将原图视为重跑结果 |
| Vivado建项/综合/布局布线 | not_run | 无可用Vivado；无法报告资源或时序收敛 |
| 整理修复版重新上板 | not_run | 无连接的EGO1实验硬件 |

## 同套测试前后对照

| 用例 | 修复前 | 修复后 |
| --- | --- | --- |
| `tb_adc_select` | failed | passed |
| `tb_controls` | failed | passed |
| `tb_dds` | passed | passed |
| `tb_display` | failed | passed |
| `tb_duty` | failed | passed |
| `tb_gate` | failed | passed |
| `tb_iir` | failed | passed |
| `tb_period` | failed | passed |
| `tb_top` | failed | passed |

完整回执：[修复前](regression-before.json)、[修复后](regression-after.json)。源码版本与测试范围见 [warnings-and-fixes.md](warnings-and-fixes.md)。

## 复核命令

```bash
python -m pip install -r requirements-dev.txt
python scripts/check_project.py
python scripts/run_regression.py
```

第三条需Icarus的iverilog/vvp在PATH上；也可使用 `--tool-dir` 指定二者所在目录。生成回执在 `build/`，该目录被gitignore排除。仿真按周期缩比测试算术和状态逻辑，不代表物理参考时钟或ADC/DAC精度。

历史综合日志异常结束，不能证明成功。本次没有改写历史证据，也没有上传任何文件到远端。

## 补充COE后的最新验证

- 原COE与压缩包同名波形表逐字节一致，256点，radix=10，范围1..255。
- 新MEM与COE逐项一致；解析器通过深度、范围、缺失分号、进制2/10/16和往返转换检查。
- 新增 `tb_rom_table`，验证全部256地址的采样值、同步读出和非时钟边沿保持。
- 10/10动态回归通过，见 [COE版回执](regression-coe.json)。此前9组前后对照仍保留，属于更早的采样表版本。
- RTL静态检查继续为0错误、0警告。仍未执行Vivado综合实现或实机复测。

## 本地提交前复核

2026-11-09 05:19:42（America/Los_Angeles，按实际UTC时钟换算）：重新执行静态检查、COE解析测试、10组断言回归及Python语法检查，全部通过；source-map中的当前源文件SHA256均匹配。检查覆盖范围和未验证的硬件部分不变。

本次提交仅固化本地项目，不配置远端或推送。GitHub公开发布、开源许可证以及硬件验证留待后续明确处理。
