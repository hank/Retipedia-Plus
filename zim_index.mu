#!/usr/bin/env python3
import os
import json
from urllib.parse import unquote
from bs4 import BeautifulSoup
import template
import settings
from libzim.reader import Archive

base_dir = os.path.dirname(os.path.abspath(__file__))
zim_name = os.environ['var_zim']
archive_path = os.path.join(settings.zims_dir, zim_name)
root = settings.root_folder

archive = Archive(archive_path)
main_entry = archive.main_entry
item = main_entry.get_item()
content = bytes(item.content).decode('utf-8', errors='replace')
soup = BeautifulSoup(content, 'html.parser')
zim_title = soup.title.text.strip() if soup.title else zim_name
mw_output = soup.find('div', class_='mw-parser-output')

print(template.make_header(zim=zim_name))
print(f">`!{zim_title}`!")
print()

if mw_output is None:
    # Non-MediaWiki ZIM — no structured index to parse, search is the way in
    print("`F888This archive does not have a structured index.")
    print("Use the search bar above to find content.`f")
else:
    # --- Parse Featured Articles ---
    featured = []
    current_section = None
    for tag in mw_output.find_all(['table', 'ul']):
        font = tag.find('font', size='+1')
        if font:
            current_section = font.get_text().strip()
        elif tag.name == 'ul' and current_section == 'Featured Articles':
            for li in tag.find_all('li'):
                a = li.find('a')
                if a:
                    href = unquote(a.get('href', '')).split('#')[0]
                    title = a.get_text().strip()
                    if href and title:
                        featured.append((title, href))
            break

    # --- Parse Main Topics ---
    categories = []
    seen_cats = set()
    for b_tag in mw_output.find_all('b'):
        if b_tag.parent and b_tag.parent.name == 'td':
            parent_td = b_tag.parent
            ul = parent_td.find('ul')
            if ul:
                cat_name = b_tag.get_text().strip().rstrip(':')
                if cat_name in seen_cats:
                    continue
                seen_cats.add(cat_name)
                items = []
                for li in ul.find_all('li'):
                    a = li.find('a')
                    label = a.get_text().strip() if a else li.get_text().strip()
                    href = unquote(a.get('href', '')).split('#')[0] if a else None
                    if label:
                        items.append((label, href))
                if items:
                    categories.append((cat_name, items))

    # --- Render ---
    if featured:
        print(">Featured Articles")
        print()
        for title, href in featured:
            print(f'  `F09f`_`[{title}`:/page/{root}/entry.mu`zim={zim_name}|entry_path={href}]`_`f')
        print()

    if categories:
        print(">Main Topics")
        print()
        for cat_name, items in categories:
            print(f">>`!{cat_name}`!")
            for label, href in items:
                if href:
                    print(f'  `F0ff`_`[{label}`:/page/{root}/entry.mu`zim={zim_name}|entry_path={href}]`_`f')
                else:
                    print(f'  `F777{label}`f')
            print()
