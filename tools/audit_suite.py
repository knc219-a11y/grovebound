#!/usr/bin/env python3
"""Run the Godot checks and record review evidence without touching a player save."""
import argparse
import json
from pathlib import Path
import subprocess
import time

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--out', default='docs/audit-2026-10-20-tests.json')
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    godot = str(Path(args.godot).resolve())
    checks = [(p.name, ['--script', str(p)]) for p in sorted((root/'tools').glob('test_*.gd'))]
    checks.append(('main --self-test', ['--', '--self-test']))
    results = []
    for name, tail in checks:
        start = time.monotonic()
        try:
            run = subprocess.run([godot, '--headless', '--path', str(root), *tail], cwd=root,
                                 capture_output=True, text=True, timeout=25)
            log = run.stdout + run.stderr
            # The older cutout check reports metrics and uses its exit status for assertions.
            marker = 'PASS' in log or (name == 'test_boar_cutout.gd' and 'CUTOUT CHECK:' in log)
            passed = run.returncode == 0 and marker and not any(
                value in log for value in ['SCRIPT ERROR:', 'Parse Error:', 'FAIL ', 'ERROR:'])
            item = {'test': name, 'pass': passed, 'exit': run.returncode,
                    'seconds': round(time.monotonic()-start, 2),
                    'summary': [line for line in log.splitlines()
                                if any(value in line for value in ['PASS', 'CHECK:', 'ERROR', 'FAIL '])],
                    'warnings': [line for line in log.splitlines() if line.startswith('WARNING:')]}
        except subprocess.TimeoutExpired:
            item = {'test': name, 'pass': False, 'timeout': True}
        results.append(item)
        print(('PASS ' if item['pass'] else 'FAIL ') + name, flush=True)
    (root/args.out).write_text(json.dumps(results, ensure_ascii=False, indent=2)+'\n')
    print(f"TOTAL {sum(item['pass'] for item in results)}/{len(results)}")
    raise SystemExit(0 if all(item['pass'] for item in results) else 1)

if __name__ == '__main__':
    main()
