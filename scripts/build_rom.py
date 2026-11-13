"""从原始256×8 COE生成readmemh数据；--check只检查，不写文件。"""
from pathlib import Path
import argparse
import re

ROOT = Path(__file__).resolve().parents[1]

def parse_coe(text):
    match = re.fullmatch(r"\s*memory_initialization_radix\s*=\s*(\d+)\s*;\s*memory_initialization_vector\s*=\s*(.*?)\s*;\s*", text, re.I | re.S)
    if not match:
        raise ValueError("COE需要radix与vector字段，均以分号结束")
    radix = int(match[1])
    if radix not in (2, 10, 16):
        raise ValueError("仅支持COE基数2、10、16")
    tokens = [token.strip() for token in match[2].split(',')]
    if len(tokens) != 256 or any(not token for token in tokens):
        raise ValueError("本项目ROM必须恰好包含256个采样值")
    values = [int(token, radix) for token in tokens]
    if any(value < 0 or value > 255 for value in values):
        raise ValueError("8位ROM采样值必须在0..255之间")
    return values

def render_mem(values):
    return ''.join(f"{value:02x}\n" for value in values)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    values = parse_coe((ROOT/'data/sin_wave_256x8.coe').read_text(encoding='utf-8-sig'))
    target = ROOT/'data/sin_wave_256x8.mem'
    expected = render_mem(values)
    if args.check:
        if not target.exists() or target.read_text(encoding='ascii') != expected:
            raise SystemExit('FAIL: MEM与COE不一致；执行 python scripts/build_rom.py 重新生成')
        print('PASS: 256个8位采样值，COE与MEM逐项一致')
    else:
        target.write_text(expected, encoding='ascii', newline='\n')
        print('Generated data/sin_wave_256x8.mem from original COE')

if __name__ == '__main__':
    main()
