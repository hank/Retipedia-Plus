#!/usr/bin/env python3
import os
import json
import template
import settings
from formatting.epub import get_spine

print(template.header)

base_dir = os.path.dirname(os.path.abspath(__file__))
meta_dir = os.path.join(base_dir, 'zims')
root = settings.root_folder

zim_files = sorted(f for f in os.listdir(settings.zims_dir) if f.endswith('.zim'))

if not zim_files:
    print("No ZIM archives found.")
else:
    print(">Available Archives")
    print()
    for zim_file in zim_files:
        meta_path = os.path.join(meta_dir, zim_file + '.meta')
        if os.path.exists(meta_path):
            with open(meta_path) as f:
                meta = json.load(f)
            title = meta.get('title', zim_file)
            description = meta.get('description', '')
        else:
            title = zim_file.replace('_', ' ').replace('.zim', '')
            description = ''

        zim_type = meta.get('type', 'generic') if os.path.exists(meta_path) else 'generic'
        if zim_type == 'wikipedia':
            link_url = f':/page/{root}/entry.mu`zim={zim_file}|entry_path=Main_Page'
        else:
            link_url = f':/page/{root}/zim_index.mu`zim={zim_file}'
        print(f'  `F0ff`_`[{title}`{link_url}]`_`f')
        if description:
            print(f'  `F777{description}`f')
        print()

# --- Books (EPUBs) ---
epub_files = sorted(f for f in os.listdir(settings.epubs_dir) if f.endswith('.epub'))
if epub_files:
    print(">Books")
    print()
    for epub_file in epub_files:
        try:
            metadata, spine = get_spine(os.path.join(settings.epubs_dir, epub_file))
            title = metadata['title']
            author = metadata['author']
        except Exception:
            title = epub_file.replace('_', ' ').replace('.epub', '')
            author = ''
        print(f'  `F0ff`_`[{title}`:/page/{root}/epub_index.mu`epub={epub_file}]`_`f')
        if author:
            print(f'  `F777{author}`f')
        print()
