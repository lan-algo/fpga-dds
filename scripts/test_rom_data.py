"""COE转换的边界检查，不需要额外测试框架。"""
from pathlib import Path
from build_rom import parse_coe, render_mem

root = Path(__file__).resolve().parents[1]
text = (root/'data/sin_wave_256x8.coe').read_text(encoding='utf-8-sig')
values = parse_coe(text)
assert len(values) == 256 and min(values) == 1 and max(values) == 255
assert [values[i] for i in (0, 64, 128, 192, 255)] == [128, 255, 128, 1, 125]
assert [int(line,16) for line in render_mem(values).splitlines()] == values

def example(items, radix=10):
    return f"MEMORY_INITIALIZATION_RADIX={radix};\nMEMORY_INITIALIZATION_VECTOR=" + ','.join(map(str,items)) + ';'

for invalid in (example(values[:-1]), example([256]+values[1:]), example([-1]+values[1:]), example(values,8), text.rstrip(';\n\r ')):
    try:
        parse_coe(invalid)
    except ValueError:
        pass
    else:
        raise AssertionError('Invalid COE accepted')
assert parse_coe(example([f'{v:x}' for v in values],16)) == values
assert parse_coe(example([f'{v:b}' for v in values],2)) == values
print('PASS: original table, anchors, round trip, bases 2/10/16, malformed/depth/range rejection')
