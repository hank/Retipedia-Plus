#!/usr/bin/env python3
import os
import sys
import template
import settings
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from formatting.sword import get_book

root = settings.root_folder
osis_name = os.environ['var_book']

testament, book = get_book(osis_name)
if book is None:
    print(template.make_header())
    print("Book not found.")
    raise SystemExit(1)

print(template.make_header())
print(f">`!{book.name}`!")
print()
print(f'  `F777`_`[◀ All Books`:/page/{root}/bible_index.mu]`_`f')
print()
print(f">Chapters")
print()

for ch in range(1, book.num_chapters + 1):
    print(f'  `F0ff`_`[Chapter {ch}`:/page/{root}/bible_chapter.mu`book={osis_name}|ch={ch}]`_`f')
