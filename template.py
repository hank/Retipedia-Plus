#!/bin/python3
import os
import settings
from libzim.reader import Archive
from libzim.search import Query, Searcher
from libzim.suggestion import SuggestionSearcher

ascii_art = """`c
`F09f █▀█ █▀▀ ▀█▀ █ █▀▄ █▀▀ █▀▄ █ ▄▀▄
`F0cf █▀▄ █▀   █  █ █▀▀ █▀  █ █ █ █▀█
`F09f ▀ ▀ ▀▀▀  ▀  ▀ ▀   ▀▀▀ ▀▀▀ ▀ ▀ ▀
`f"""


search_icon = "🔍"


def make_header(zim=None):
    if zim:
        search_bar = f'`B111 {search_icon} `b  `B555`<search_query` >`b   `F0ff`!`[Search`:/page/{settings.root_folder}/results.mu`*|zim={zim}]`!`b `f'
    else:
        search_bar = ""

    return f"""
`c
`Faaa{settings.node_title}`f |  \
`F09f`_`[Info`:/page/{settings.root_folder}/info.mu]`_`f \

`a
--  `b

{search_bar}

-¯
"""


header = make_header()

if settings.ascii_art_enabled:
    print(ascii_art)
