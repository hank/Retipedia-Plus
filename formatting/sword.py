"""Shared utilities for reading SWORD Bible modules via pysword."""

import os
from pysword.modules import SwordModules

SWORD_PATH = '/opt/ftp/sword'
MODULE_NAME = 'LSB'

_bible = None
_struct = None
_books = None  # {'ot': [...], 'nt': [...]}


def _load():
    global _bible, _struct, _books
    if _bible is None:
        modules = SwordModules(SWORD_PATH)
        modules.parse_modules()
        _bible = modules.get_bible_from_module(MODULE_NAME)
        _struct = _bible.get_structure()
        _books = _struct.get_books()


def get_books():
    """Return {'ot': [book, ...], 'nt': [book, ...]}"""
    _load()
    return _books


def get_book(osis_name):
    """Return (testament, book_obj) for a given osis_name like 'Gen'."""
    _load()
    for testament, blist in _books.items():
        for book in blist:
            if book.osis_name == osis_name:
                return testament, book
    return None, None


def get_chapter(osis_name, chapter_num):
    """Return list of (verse_num, text) for a chapter."""
    _load()
    testament, book = get_book(osis_name)
    if book is None:
        return []

    num_verses = book.chapter_lengths[chapter_num - 1]
    verses = []
    for v in range(1, num_verses + 1):
        text = _bible.get(books=[osis_name], chapters=[chapter_num], verses=[v], clean=True).strip()
        verses.append((v, text))
    return verses
