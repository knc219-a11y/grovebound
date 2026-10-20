#!/usr/bin/env python3
"""Run the Godot checks and record review evidence without touching a player save."""
import argparse
import json
from pathlib import Path
import subprocess
import time
from contextlib import contextmanager

@contextmanager
def workspace_saves(root, enabled):
    """Redirect test-only fixtures for hosts where user:// is not writable."""
    originals = {}
    try:
        if enabled:
            (root/'.qa-data').mkdir(exist_ok=True)
            for path in (root/'tools').glob('test_*.gd'):
                content = path.read_text(encoding='utf-8')
                if 'user://' in content:
                    originals[path] = content
                    path.write_text(content.replace('user://', 'res://.qa-data/'), encoding='utf-8')
        yield
    finally:
        for path, content in originals.items():
            path.write_text(content, encoding='utf-8')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--out', default='docs/audit-2026-10-20-tests.json')
    parser.add_argument('--workspace-saves', action='store_true', help='Temporarily redirect test-only user:// fixtures into .qa-data; never edits production save paths')
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    godot = str(Path(args.godot).resolve())
    checks = [(p.name, ['--script', str(p)]) for p in sorted((root/'tools').glob('test_*.gd'))]
    checks.append(('main --self-test', ['--', '--self-test']))
    results = []
    with workspace_saves(root, args.workspace_saves):
        for name, tail in checks:
            start = time.monotonic()
            try:
                run = subprocess.run([godot, '--headless', '--path', str(root), '--log-file', str(root/'.godot/audit.log'), *tail], cwd=root,
                                     capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=25)
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
