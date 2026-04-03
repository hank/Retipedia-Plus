#!/usr/bin/env python3
import os
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
    text_content = bytes(item.content).decode('utf-8')

    print(template.make_header(zim=zim_name))
    print(f">{entry_title}")
    print(wikipedia.html_to_micron(text_content, zim_name))

except KeyError:
    print(template.make_header(zim=zim_name))
    print("Can't find entry")
