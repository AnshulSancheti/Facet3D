#!/usr/bin/env python3
"""Offline APK ELF segment and zip alignment audit. Does not access devices."""
import json, os, pathlib, struct, subprocess, sys, tempfile, zipfile
apk = pathlib.Path(sys.argv[1]).resolve()
sdk = pathlib.Path(os.environ.get('ANDROID_HOME', str(pathlib.Path.home() / 'Android/Sdk')))
report = {'artifact': str(apk), 'libraries': [], 'hardware_tested': False}
with zipfile.ZipFile(apk) as archive:
    for name in archive.namelist():
        if not name.startswith('lib/') or not name.endswith('.so'):
            continue
        data = archive.read(name)
        if data[:5] != b'\x7fELF\x02':
            raise SystemExit(f'Expected 64bit ELF: {name}')
        endian = '<' if data[5] == 1 else '>'
        phoff = struct.unpack_from(endian + 'Q', data, 32)[0]
        size, count = struct.unpack_from(endian + 'HH', data, 54)
        aligns = []
        for index in range(count):
            offset = phoff + index * size
            if struct.unpack_from(endian + 'I', data, offset)[0] == 1:
                aligns.append(struct.unpack_from(endian + 'Q', data, offset + 48)[0])
        report['libraries'].append({'name': name, 'load_alignments': aligns, 'elf_16k': bool(aligns) and min(aligns) >= 16384})
zipalign = sdk / 'build-tools/36.1.0/zipalign'
result = subprocess.run([str(zipalign), '-c', '-P', '16', '4', str(apk)], capture_output=True, text=True)
report['zip_16k'] = result.returncode == 0
report['zipalign_output'] = result.stdout + result.stderr
report['passed'] = report['zip_16k'] and bool(report['libraries']) and all(lib['elf_16k'] for lib in report['libraries'])
tools_dir = sdk / 'build-tools/36.1.0'
for label, args in [('badging', [str(tools_dir / 'aapt'), 'dump', 'badging', str(apk)]), ('manifest', [str(tools_dir / 'aapt'), 'dump', 'xmltree', str(apk), 'AndroidManifest.xml']), ('signature', [str(tools_dir / 'apksigner'), 'verify', '--verbose', str(apk)])]:
    check = subprocess.run(args, capture_output=True, text=True)
    apk.with_suffix('.' + label + '.txt').write_text(check.stdout + check.stderr)
    report[label + '_verified'] = check.returncode == 0
    if label == 'signature':
        report['passed'] = report['passed'] and check.returncode == 0
report_path = apk.with_suffix('.audit.json')
report_path.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
print('Audit saved:', report_path)
sys.exit(0 if report['passed'] else 1)
