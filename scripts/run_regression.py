"""运行带断言的RTL回归；--rtl-dir可用于比较修复前快照。"""
import argparse, json, shutil, subprocess
from pathlib import Path
p=argparse.ArgumentParser()
p.add_argument("--tool-dir",type=Path)
p.add_argument("--rtl-dir",type=Path)
p.add_argument("--report",default="regression.json")
a=p.parse_args()
root=Path(__file__).resolve().parents[1]
rtl=(a.rtl_dir or root/"rtl").resolve()
build=root/"build";build.mkdir(exist_ok=True)
def tool(name):
    candidate=(a.tool_dir/(name+".exe")) if a.tool_dir else None
    found=str(candidate) if candidate and candidate.is_file() else shutil.which(name)
    if not found:raise SystemExit("not_run: missing "+name+"; install Icarus or pass --tool-dir")
    return found
iv,vvp=tool("iverilog"),tool("vvp")
shutil.copy2(root/"data/sin_wave_256x8.mem",build/"sin_wave_256x8.mem")
results=[]
for tb in sorted((root/"sim/regression").glob("tb_*.sv")):
    command=[iv,"-g2012","-s",tb.stem,"-o",str(build/(tb.stem+".vvp")),*[str(f) for f in sorted(rtl.glob("*.v"))],str(tb)]
    compiled=subprocess.run(command,cwd=build,capture_output=True,text=True,encoding="utf-8",errors="replace",timeout=30)
    result={"case":tb.stem,"compile_returncode":compiled.returncode}
    if compiled.returncode:
        result.update(status="compile_failed",output=compiled.stdout+compiled.stderr)
    else:
        try:
            ran=subprocess.run([vvp,str(build/(tb.stem+".vvp"))],cwd=build,capture_output=True,text=True,encoding="utf-8",errors="replace",timeout=30)
            result.update(status="passed" if ran.returncode==0 and "PASS " in ran.stdout else "failed",returncode=ran.returncode,output=ran.stdout+ran.stderr)
        except subprocess.TimeoutExpired:
            result.update(status="timeout",output="Simulation exceeded 30 seconds")
    # Store reproducible diagnostics without user-specific machine paths.
    result["output"]=result["output"].replace(str(root),"<project>").replace(str(rtl),"<rtl>")
    print(result["case"]+": "+result["status"]+" | "+result["output"].splitlines()[0])
    results.append(result)
(build/a.report).write_text(json.dumps(results,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
raise SystemExit(0 if all(r["status"]=="passed" for r in results) else 1)
