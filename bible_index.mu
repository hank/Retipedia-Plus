#!/usr/bin/env python3
import os
import sys
import template
import settings
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from formatting.sword import get_books

root = settings.root_folder

books = get_books()

print(template.make_header())
print(">`!Legacy Standard Bible`!")
print()

for testament, label in [('ot', 'Old Testament'), ('nt', 'New Testament')]:
    print(f">>{label}")
    print()
    for book in books[testament]:
        print(f'  `F0ff`_`[{book.name}`:/page/{root}/bible_book.mu`book={book.osis_name}]`_`f')
    print()
