#!/usr/bin/env python3
"""Inject a local SOCKS5 proxy into a Clash YAML config."""

import re
import sys

NAME = None


def split_sections(lines):
    """Split into (pre, {section: (header_idx, body_lines)}, order)."""
    sections = []
    current = None
    for i, line in enumerate(lines):
        if line and not line.startswith(' ') and not line.startswith('-') and line.rstrip().endswith(':'):
            current = {'name': line.strip()[:-1], 'header': i, 'start': i + 1, 'end': len(lines)}
            if sections:
                sections[-1]['end'] = i
            sections.append(current)
    return sections


def main():
    src, dst, port, name = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4]
    lines = open(src, encoding='utf-8', errors='replace').read().splitlines()

    sections = split_sections(lines)

    # Work on copies of section bodies
    bodies = {}
    for sec in sections:
        bodies[sec['name']] = lines[sec['start']:sec['end']]

    # 1. proxies section
    proxies = bodies.get('proxies', [])
    cleaned = []
    removing = False
    for line in proxies:
        if re.match(r'^\s*-\s*name:\s*' + re.escape(name) + r'\s*$', line):
            removing = True
            continue
        if removing:
            if line.startswith('  ') and not line.startswith('  - '):
                continue
            removing = False
        cleaned.append(line)

    cleaned += [
        f'- name: {name}',
        '  type: socks5',
        '  server: 127.0.0.1',
        f'  port: {port}',
        '  udp: true',
    ]
    bodies['proxies'] = cleaned

    # 2. first proxy group: add our proxy to its proxies list
    groups = bodies.get('proxy-groups', [])
    if groups:
        # first block boundaries
        start = 0
        end = len(groups)
        for i in range(1, len(groups)):
            if groups[i].startswith('- '):
                end = i
                break
        block = groups[start:end]

        has = any(x.strip() == 'proxies:' for x in block)
        if has:
            idx = next(i for i, x in enumerate(block) if x.strip() == 'proxies:')
            if not any(name in x for x in block):
                block[idx + 1:idx + 1] = [f'  - {name}']
        else:
            block.append('  proxies:')
            block.append(f'  - {name}')

        bodies['proxy-groups'] = block + groups[end:]

    # Rebuild file, keeping original section order and unknown content
    out = []
    known = {s['name'] for s in sections}
    for sec in sections:
        out.append(lines[sec['header']])
        out.extend(bodies.get(sec['name'], lines[sec['start']:sec['end']]))

    # Ensure proxies section exists
    if 'proxies' not in known:
        out = ['proxies:'] + bodies['proxies'] + [''] + out

    open(dst, 'w', encoding='utf-8').write('\n'.join(out) + '\n')


if __name__ == '__main__':
    main()
