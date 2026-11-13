"""检查可展示工程的文件完整性及静态展开；不冒充仿真/综合。"""
from pathlib import Path
from collections import Counter
import os
import re
import sys

root = Path(__file__).resolve().parents[1]
os.chdir(root)
rtl = [Path(line) for line in Path("rtl/files.f").read_text(encoding="utf-8").splitlines() if line.strip()]
assert set(rtl) == set(Path("rtl").glob("*.v")), "源文件列表遗漏或包含陈旧条目"
modules = []
for path in rtl:
    text = path.read_text(encoding="utf-8")
    assert chr(0xfffd) not in text, f"编码损坏: {path}"
    code = re.sub(r"/\*.*?\*/|//[^\n]*", "", text, flags=re.S)
    modules.extend(re.findall(r"\bmodule\s+(\w+)", code))
counts = Counter(modules)
assert all(count == 1 for count in counts.values()), counts
values = [int(line, 16) for line in Path("data/sin_wave_256x8.mem").read_text().splitlines()]
sys.path.insert(0, str(root / "scripts"))
from build_rom import parse_coe
expected = parse_coe(Path("data/sin_wave_256x8.coe").read_text(encoding="utf-8-sig"))
assert values == expected, "ROM 数据与原始 COE 不一致"
for path in [Path("README.md"), *Path("docs").glob("*.md")]:
    for target in re.findall(r"!?\[[^\]]*\]\(([^)]+)\)", path.read_text(encoding="utf-8")):
        if "://" not in target and not target.startswith("#"):
            assert (path.parent / target.split("#")[0]).exists(), f"断链: {path}: {target}"
for path in [*rtl, *Path("sim").glob("*.v"), Path("README.md"), *Path("docs").glob("*.md"), Path("docs/source-map.json")]:
    text = path.read_text(encoding="utf-8")
    assert not re.search(r"(?<!\d)1[3-9]\d{9}(?!\d)", text), f"疑似手机号: {path}"
    assert not re.search(r"[A-Za-z]:[/\\](?:Users|Agent|数字)", text), f"私人绝对路径: {path}"
try:
    import pyslang
    from pyslang import SourceManager, DiagnosticEngine
    from pyslang.syntax import SyntaxTree
    from pyslang.ast import Compilation
except ImportError:
    raise SystemExit("not_run: 请先执行 python -m pip install -r requirements-dev.txt")
sm = SourceManager()
compilation = Compilation()
for path in [*rtl, Path("sim/tb_DDS_10MHz.v")]:
    compilation.addSyntaxTree(SyntaxTree.fromFile(str(path), sm))
diagnostics = compilation.getAllDiagnostics()
errors = sum(item.isError() for item in diagnostics)
report = DiagnosticEngine.reportAll(sm, diagnostics)
Path("build").mkdir(exist_ok=True)
Path("build/static-diagnostics.txt").write_text(report, encoding="utf-8")
print(f"pyslang {pyslang.__version__}: {len(rtl)} RTL files, {len(counts)} unique modules; {errors} errors, {len(diagnostics)-errors} warnings")
print("PASS: source list, ROM samples, relative links, and text privacy checks")
print("Diagnostics written to build/static-diagnostics.txt")
if len(diagnostics):
    print(report)
    raise SystemExit(1)
print("PASS: parsing/type checking/elaboration only; not a simulation or synthesis result")
