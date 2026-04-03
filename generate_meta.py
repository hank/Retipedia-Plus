#!/usr/bin/env python3
"""
Generate a .meta sidecar JSON file for a ZIM archive.
Usage: ./generate_meta.py path/to/file.zim
"""

import sys
import os
import json
from collections import Counter
from bs4 import BeautifulSoup
from libzim.reader import Archive


def detect_type(archive):
    """Detect the ZIM content type."""
    # Sample MIME types from first N entries
    mimes = Counter()
    sample = min(archive.entry_count, 300)
    for i in range(sample):
        try:
            e = archive._get_entry_by_id(i)
            if not e.is_redirect:
                mimes[e.get_item().mimetype] += 1
        except:
            pass

    total = sum(mimes.values()) or 1
    video_frac = mimes.get('video/webm', 0) / total
    pdf_frac = mimes.get('application/pdf', 0) / total

    if video_frac > 0.1:
        return 'video'
    if pdf_frac > 0.1:
        return 'pdf'

    # Check main page for MediaWiki structure
    try:
        main = archive.main_entry
        item = main.get_item()
        if 'html' in item.mimetype:
            content = bytes(item.content).decode('utf-8', errors='replace')
            soup = BeautifulSoup(content, 'html.parser')
            if soup.find('div', class_='mw-parser-output'):
                return 'wikipedia'
            has_refresh = soup.find('meta', attrs={'http-equiv': lambda v: v and v.lower() == 'refresh'})
            body_text = soup.body.get_text().strip() if soup.body else ''
            if has_refresh or not body_text:
                return 'spa'
    except:
        pass

    return 'generic'


def get_title(archive):
    """Get a human-readable title from ZIM metadata or main page."""
    # Try ZIM metadata first
    for key in ('Title', 'Name'):
        try:
            val = archive.get_metadata(key).decode('utf-8', errors='replace').strip()
            if val:
                return val
        except:
            pass

    # Fall back to main page <title>
    try:
        content = bytes(archive.main_entry.get_item().content).decode('utf-8', errors='replace')
        soup = BeautifulSoup(content, 'html.parser')
        if soup.title and soup.title.text.strip():
            return soup.title.text.strip()
    except:
        pass

    return os.path.basename(archive.filename)


def get_description(archive, zim_type):
    """Generate a description from ZIM metadata or main page content."""
    # Try ZIM metadata Description field
    try:
        val = archive.get_metadata('Description').decode('utf-8', errors='replace').strip()
        if val:
            return val
    except:
        pass

    # For wikipedia-type, grab first paragraph of main page
    if zim_type == 'wikipedia':
        try:
            content = bytes(archive.main_entry.get_item().content).decode('utf-8', errors='replace')
            soup = BeautifulSoup(content, 'html.parser')
            mw = soup.find('div', class_='mw-parser-output')
            if mw:
                for p in mw.find_all('p'):
                    text = p.get_text().strip()
                    if len(text) > 40:
                        # Truncate at sentence boundary around 150 chars
                        if len(text) > 150:
                            end = text.find('.', 100)
                            text = text[:end + 1] if end != -1 else text[:150] + '...'
                        return text
        except:
            pass

    return ''


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} path/to/file.zim", file=sys.stderr)
        sys.exit(1)

    zim_path = sys.argv[1]
    if not os.path.isfile(zim_path):
        print(f"File not found: {zim_path}", file=sys.stderr)
        sys.exit(1)

    # Meta files live in the retipedia/zims/ directory alongside the code, not with the ZIM binary.
    script_dir = os.path.dirname(os.path.abspath(__file__))
    meta_dir = os.path.join(script_dir, 'zims')
    os.makedirs(meta_dir, exist_ok=True)
    meta_path = os.path.join(meta_dir, os.path.basename(zim_path) + '.meta')

    if os.path.isfile(meta_path):
        print(f"Meta already exists: {meta_path}", file=sys.stderr)
        print("Delete it first or edit it manually.", file=sys.stderr)
        sys.exit(1)

    print(f"Opening {zim_path}...")
    archive = Archive(zim_path)

    zim_type = detect_type(archive)
    title = get_title(archive)
    description = get_description(archive, zim_type)
    entry_count = archive.article_count

    meta = {
        'title': title,
        'type': zim_type,
        'description': description or f'{entry_count} articles',
    }

    print(f"  Title:       {meta['title']}")
    print(f"  Type:        {meta['type']}")
    print(f"  Description: {meta['description']}")
    print(f"  Writing:     {meta_path}")

    with open(meta_path, 'w') as f:
        json.dump(meta, f, indent=2)
        f.write('\n')

    print("Done.")


if __name__ == '__main__':
    main()
