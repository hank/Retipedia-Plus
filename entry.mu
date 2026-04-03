#!/usr/bin/env python3
import os
from bs4 import BeautifulSoup
import template
import settings
from libzim.reader import Archive
from formatting import wikipedia

base_dir = os.path.dirname(os.path.abspath(__file__))
zim_name = os.environ['var_zim']
archive_path = os.path.join(base_dir, 'zims', zim_name)
entry_path = os.environ['var_entry_path']

archive = Archive(archive_path)

try:
    entry = archive.get_entry_by_path(entry_path)
    entry_title = entry.title
    item = entry.get_item()
    mimetype = item.mimetype

    print(template.make_header(zim=zim_name))
    print(f">{entry_title}")

    if mimetype == 'application/pdf':
        print()
        print("`F888This entry is a PDF document and cannot be displayed in a text browser.`f")

    elif 'html' not in mimetype:
        print()
        print(f"`F888This entry has an unsupported content type ({mimetype}) and cannot be displayed.`f")

    else:
        text_content = bytes(item.content).decode('utf-8', errors='replace')
        soup = BeautifulSoup(text_content, 'html.parser')

        # Detect JS SPA / meta-refresh shell with no real body content
        body_text = soup.body.get_text().strip() if soup.body else ''
        has_refresh = soup.find('meta', attrs={'http-equiv': lambda v: v and v.lower() == 'refresh'})

        if not body_text or has_refresh:
            print()
            print("`F888This entry requires JavaScript to render and cannot be displayed in a text browser.`f")
        else:
            print(wikipedia.html_to_micron(text_content, zim_name))

except KeyError:
    print(template.make_header(zim=zim_name))
    print("Can't find entry")
