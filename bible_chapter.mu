#!/usr/bin/env python3
import os
import sys
import template
import settings
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from formatting.sword import get_book, get_chapter

root = settings.root_folder
osis_name = os.environ['var_book']
ch = int(os.environ.get('var_ch', 1))

testament, book = get_book(osis_name)
if book is None:
    print(template.make_header())
    print("Book not found.")
    raise SystemExit(1)

prev_ch = ch - 1 if ch > 1 else None
next_ch = ch + 1 if ch < book.num_chapters else None

print(template.make_header())
print(f">`!{book.name} {ch}`!")
print()

# --- Navigation (top) ---
nav = []
nav.append(f'`F777`_`[{book.name}`:/page/{root}/bible_book.mu`book={osis_name}]`_`f')
if prev_ch:
    nav.append(f'`F0ff`_`[◀ Ch.{prev_ch}`:/page/{root}/bible_chapter.mu`book={osis_name}|ch={prev_ch}]`_`f')
if next_ch:
    nav.append(f'`F0ff`_`[Ch.{next_ch} ▶`:/page/{root}/bible_chapter.mu`book={osis_name}|ch={next_ch}]`_`f')
print('  '.join(nav))
print()
print('-')
print()

# --- Verses ---
verses = get_chapter(osis_name, ch)
for verse_num, text in verses:
    print(f'`F777{verse_num}`f  {text}')
    print()

# --- Navigation (bottom) ---
print('-')
print()
print('  '.join(nav))
