#!/usr/bin/env python3
import os
import template
import settings
from libzim.reader import Archive
from libzim.search import Searcher, Query
from libzim.suggestion import SuggestionSearcher

base_dir = os.path.dirname(os.path.abspath(__file__))
zim_name = os.environ['var_zim']
archive_path = os.path.join(settings.zims_dir, zim_name)
zim = Archive(archive_path)

results_per_page = 15
current_page = int(os.getenv('var_page_number', 1))

print(template.make_header(zim=zim_name))

search_query = os.environ.get("field_search_query", "")
if search_query == "":
    search_query = os.environ.get("var_search_query", "")

print(f">Searching For: {search_query}")

suggestion_searcher = SuggestionSearcher(zim)
suggestion = suggestion_searcher.suggest(search_query)
suggestion_count = suggestion.getEstimatedMatches()
total_pages = (suggestion_count + results_per_page - 1) // results_per_page

print(f">>>Page {current_page} | {suggestion_count} matches for {search_query}:")

start_index = (current_page - 1) * results_per_page
suggestions = list(suggestion.getResults(start_index, results_per_page))

for idx, entry_path in enumerate(suggestions, start=1):
    entry_title = zim.get_entry_by_path(entry_path).title
    print(f"{start_index + idx}. `!`[{entry_title}`:/page/{settings.root_folder}/entry.mu`zim={zim_name}|entry_path={entry_path}]`!")

if current_page > 1:
    print(f'`F00f`_`[Previous Page`:/page/{settings.root_folder}/results.mu`zim={zim_name}|search_query={search_query}|page_number={current_page - 1}]`_`f')
if current_page < total_pages:
    print(f'`F00f`_`[Next Page`:/page/{settings.root_folder}/results.mu`zim={zim_name}|search_query={search_query}|page_number={current_page + 1}]`_`f')
