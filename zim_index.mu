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
    # Non-MediaWiki ZIM — extract links directly from main page body
    # Resolve relative links against the main page's directory path
    main_dir = item.path.rsplit('/', 1)[0] + '/' if '/' in item.path else ''
    root_el = soup.body or soup
    links = []
    seen = set()
    for a in root_el.find_all('a', href=True):
        href = a.get('href', '').strip()
        label = a.get_text().strip()
        if not label or not href or href.startswith('http') or href.startswith('#'):
            continue
        href = unquote(href)
        if not href.startswith('/'):
            href = main_dir + href
        href = href.lstrip('/')
        if href and label and href not in seen:
            seen.add(href)
            links.append((label, href))

    if links:
        print(f">Browse ({len(links)} entries)")
        print()
        for label, href in links:
            print(f'  `F0ff`_`[{label}`:/page/{root}/entry.mu`zim={zim_name}|entry_path={href}]`_`f')
    else:
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

    # --- Parse Main Topics (Wikipedia <b>-in-<td> style) ---
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

    # --- Parse Main Topics (toccolours/mw-collapsible style) ---
    if not categories:
        for block in mw_output.find_all('div', class_='toccolours'):
            h2 = block.find('h2')
            cat_name = h2.get_text().strip() if h2 else None
            if not cat_name or cat_name in seen_cats:
                continue
            seen_cats.add(cat_name)
            content_div = block.find('div', class_='mw-collapsible-content')
            if not content_div:
                continue
            items = []
            for a in content_div.find_all('a'):
                href = a.get('href', '').strip()
                label = a.get_text().strip()
                if not label or not href or href.startswith('http'):
                    continue
                href = unquote(href).split('#')[0]
                if href and label:
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
