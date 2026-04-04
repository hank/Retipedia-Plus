#!/usr/bin/env python3
import os
import sys
import template
import settings
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from formatting.epub import get_spine

epub_name = os.environ['var_epub']
epub_path = os.path.join(settings.epubs_dir, epub_name)
root = settings.root_folder

try:
    metadata, spine = get_spine(epub_path)
except Exception as e:
    print(template.make_header())
    print(f"Error reading epub: {e}")
    raise SystemExit(1)

print(template.make_header())
print(f">`!{metadata['title']}`!")
if metadata['author']:
    print(f"`F777{metadata['author']}`f")
print()
print(f">Table of Contents")
print()

for chapter in spine:
    print(f'  `F0ff`_`[{chapter["title"]}`:/page/{root}/epub_entry.mu`epub={epub_name}|idx={chapter["idx"]}]`_`f')
