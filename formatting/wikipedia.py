import os
from bs4 import BeautifulSoup
import re
import sys
from urllib.parse import unquote
import settings


# Formatting for Wikipedia archives in .zim format provided by the Kiwix project

def format_link(a_tag, zim_name):
    # Use href if available otherwise, use the link's text
    href = a_tag.get('href', a_tag.text).strip()
    text = a_tag.text.strip()
    # Decode URL encoding and strip fragment identifiers
    href = unquote(href).split('#')[0]
    # If href is empty (was an anchor-only link like #cite_ref-1) render as plain text
    if not href:
        return text if text else "-"
    # Format as micron link with blue text
    if text:
        return f'`F00f`_`[{text}`:/page/{settings.root_folder}/entry.mu`zim={zim_name}|entry_path={href}]`_`f'
    else:
        return "-"

def clean_html(soup):
    # References and external links for some articles can be quite long and will be on their own seperate page isolated from the main article content.
    reference_section_attributes = [
        "sidebar-list",
        "reflist",
        "mw-references-wrap",
        "references",
        "mw-reference-columns",
        "navbox",
        "infobox",
        "sidebar",
        "hatnote"
    ]

    links_to_related_articles = soup.find(attrs={"aria-labelledby": "Links_to_related_articles"})

    if links_to_related_articles:
        links_to_related_articles.decompose()

    external_link_section_attributes = [
        "external",
    ]

    for external_link_classes in external_link_section_attributes:
        for element in soup.find_all(class_=external_link_classes):
            element.decompose()

    for reference_classes in reference_section_attributes:
        for element in soup.find_all(class_=reference_classes):
            element.decompose()

    # Remove script and style elements
    for script_or_style in soup(["script", "style"]):
        script_or_style.decompose()

    # Remove inline citation references
    for citation in soup.find_all("sup", class_="reference"):
        citation.decompose()


def html_to_micron(html_content, zim_name):
    soup = BeautifulSoup(html_content, 'html.parser')
    clean_html(soup)

    micron_document = ''

    # Scope to mw-parser-output if present to avoid page chrome (title, nav, etc.)
    root = soup.find('div', class_='mw-parser-output') or soup.body

    # Process each element
    for element in root.find_all(True):  # True gets all tags
        if element.name in ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']:
            level = int(element.name[1])
            header_mark = '>' * level
            for a in element.find_all('a'):
                a.replace_with(format_link(a, zim_name))
            micron_document += f"{header_mark}{element.get_text(strip=True)}\n\n"
        elif element.name == 'p':
            paragraph_text = ''
            for content in element.contents:
                if content.name == 'a':
                    paragraph_text += format_link(content, zim_name)
                else:
                    paragraph_text += str(content)
            cleaned_paragraph = re.sub('<[^<]+?>', '', paragraph_text)
            micron_document += cleaned_paragraph.strip() + '\n\n'
        elif element.name == 'li':
            item_text = ''
            for content in element.contents:
                if content.name == 'a':
                    item_text += format_link(content, zim_name)
                else:
                    item_text += str(content)
            cleaned_item = re.sub('<[^<]+?>', '', item_text).strip()
            if cleaned_item:
                micron_document += f'• {cleaned_item}\n'
        # handle direct links outside paragraphs, headers, or inline containers
        elif element.name == 'a' and element.parent and element.parent.name not in ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'li', 'b', 'i', 'em', 'strong', 'span', 'u']:
            micron_document += format_link(element, zim_name) + '\n\n'

    return micron_document
