#!/usr/bin/env python3
import os
import sys
import template
import settings
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from formatting.epub import get_spine, get_chapter_html
from formatting.wikipedia import html_to_micron

epub_name = os.environ['var_epub']
epub_path = os.path.join(settings.epubs_dir, epub_name)
idx = int(os.environ.get('var_idx', 0))
root = settings.root_folder

try:
    metadata, spine = get_spine(epub_path)
except Exception as e:
    print(template.make_header())
    print(f"Error reading epub: {e}")
    raise SystemExit(1)

if idx < 0 or idx >= len(spine):
    print(template.make_header())
    print("Chapter not found.")
    raise SystemExit(1)

chapter = spine[idx]
prev_chapter = spine[idx - 1] if idx > 0 else None
next_chapter = spine[idx + 1] if idx < len(spine) - 1 else None

print(template.make_header())
print(f">`!{metadata['title']}`!")
print(f"`F777{chapter['title']}`f")
print()

# --- Navigation (top) ---
nav_parts = []
nav_parts.append(f'`F0ff`_`[◀ Contents`:/page/{root}/epub_index.mu`epub={epub_name}]`_`f')
if prev_chapter:
    nav_parts.append(f'`F0ff`_`[◀ {prev_chapter["title"]}`:/page/{root}/epub_entry.mu`epub={epub_name}|idx={prev_chapter["idx"]}]`_`f')
if next_chapter:
    nav_parts.append(f'`F0ff`_`[{next_chapter["title"]} ▶`:/page/{root}/epub_entry.mu`epub={epub_name}|idx={next_chapter["idx"]}]`_`f')
print('  '.join(nav_parts))
print()
print('-')
print()

# --- Chapter content ---
try:
    html = get_chapter_html(epub_path, chapter['zip_path'])
    print(html_to_micron(html, '', chapter['zip_path']))
except Exception as e:
    print(f"`F888Error rendering chapter: {e}`f")

# --- Navigation (bottom) ---
print()
print('-')
print()
print('  '.join(nav_parts))
