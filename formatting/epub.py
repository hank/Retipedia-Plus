"""Shared utilities for reading EPUB files."""

import zipfile
import os
from pathlib import Path
from bs4 import BeautifulSoup


def _opf_dir_and_soup(epub):
    """Return (opf_dir, opf_soup) from an open ZipFile."""
    container = BeautifulSoup(epub.read('META-INF/container.xml'), 'lxml-xml')
    opf_path = container.find('rootfile')['full-path']
    opf_dir = str(Path(opf_path).parent)
    if opf_dir == '.':
        opf_dir = ''
    opf = BeautifulSoup(epub.read(opf_path), 'lxml-xml')
    return opf_dir, opf


def get_spine(epub_path):
    """Return (metadata, spine) where spine is a list of dicts:
      {'idx': int, 'path': str (zip path), 'href': str (basename), 'title': str}
    """
    with zipfile.ZipFile(epub_path) as epub:
        opf_dir, opf = _opf_dir_and_soup(epub)

        # Metadata
        metadata = {
            'title': opf.find('dc:title').get_text(strip=True) if opf.find('dc:title') else os.path.basename(epub_path),
            'author': opf.find('dc:creator').get_text(strip=True) if opf.find('dc:creator') else '',
        }

        # Manifest: id -> (href, mimetype)
        manifest = {}
        for item in opf.find_all('item'):
            manifest[item.get('id')] = (item.get('href', ''), item.get('media-type', ''))

        # Spine order
        spine_ids = [ref.get('idref') for ref in opf.find('spine').find_all('itemref')]

        # NCX titles
        toc_titles = {}
        ncx_id = opf.find('spine').get('toc')
        if ncx_id and ncx_id in manifest:
            ncx_href, _ = manifest[ncx_id]
            ncx_full = (opf_dir + '/' + ncx_href).lstrip('/') if opf_dir else ncx_href
            try:
                ncx = BeautifulSoup(epub.read(ncx_full), 'lxml-xml')
                for navpoint in ncx.find_all('navPoint'):
                    src = navpoint.find('content').get('src', '').split('#')[0]
                    label = navpoint.find('navLabel')
                    if label:
                        toc_titles[src] = label.get_text(strip=True)
                        toc_titles[os.path.basename(src)] = label.get_text(strip=True)
            except Exception:
                pass

        # Build spine list
        spine = []
        for idx, item_id in enumerate(spine_ids):
            if item_id not in manifest:
                continue
            href, mime = manifest[item_id]
            if 'html' not in mime:
                continue
            zip_path = (opf_dir + '/' + href).lstrip('/') if opf_dir else href
            basename = os.path.basename(href)
            title = toc_titles.get(href) or toc_titles.get(basename) or f'Chapter {idx + 1}'
            spine.append({
                'idx': len(spine),
                'zip_path': zip_path,
                'href': basename,
                'title': title,
            })

    return metadata, spine


def get_chapter_html(epub_path, zip_path):
    """Return raw HTML bytes for a chapter at zip_path."""
    with zipfile.ZipFile(epub_path) as epub:
        return epub.read(zip_path).decode('utf-8', errors='replace')
