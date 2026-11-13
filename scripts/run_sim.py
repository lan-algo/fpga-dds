"""从任意工作目录运行原课程 Testbench；需要 Icarus Verilog。"""
from pathlib import Path
import shutil
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
iverilog, vvp = shutil.which("iverilog"), shutil.which("vvp")
if not iverilog or not vvp:
    raise SystemExit("not_run: 请先安装 Icarus Verilog，并将 iverilog/vvp 加入 PATH。")
build = root / "build"
build.mkdir(exist_ok=True)
shutil.copy2(root / "data/sin_wave_256x8.mem", build / "sin_wave_256x8.mem")
rtl = [str(root / line.strip()) for line in (root / "rtl/files.f").read_text().splitlines() if line.strip()]
subprocess.run([iverilog, "-g2012", "-s", "top", "-o", str(build / "top.vvp"), *rtl], cwd=build, check=True)
subprocess.run([iverilog, "-g2012", "-s", "tb_DDS_10MHz", "-o", str(build / "dds.vvp"), *rtl, str(root / "sim/tb_DDS_10MHz.v")], cwd=build, check=True)
with (build / "simulation.log").open("w", encoding="utf-8") as output:
    subprocess.run([vvp, str(build / "dds.vvp")], cwd=build, check=True, stdout=output, stderr=subprocess.STDOUT)
print("Testbench 执行结束；检查 build/tb_DDS_10MHz.vcd 和 simulation.log。原激励不含自动正确性断言。")
