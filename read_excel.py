#!/usr/bin/env python3
"""Extract exercise library data from pre-extracted xlsx XML files."""
import xml.etree.ElementTree as ET
import re, sys

ns = {'s': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}

# === Load shared strings ===
ss_tree = ET.parse('/tmp/xlsx_extract/xl/sharedStrings.xml')
ss_root = ss_tree.getroot()
shared_strings = []
for si in ss_root.findall('s:si', ns):
    # Could be plain <t> or rich text <r><t>...</t></r>
    texts = []
    for t in si.iter('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}t'):
        if t.text:
            texts.append(t.text)
    shared_strings.append(''.join(texts))

print(f'Loaded {len(shared_strings)} shared strings')

# === Read sheet4 (Exercise Library 1.0) ===
sheet_tree = ET.parse('/tmp/xlsx_extract/xl/worksheets/sheet4.xml')
sheet_root = sheet_tree.getroot()

def col_letter_to_index(col_str):
    result = 0
    for c in col_str:
        result = result * 26 + (ord(c) - ord('A') + 1)
    return result - 1

rows_data = []
for row in sheet_root.findall('.//s:sheetData/s:row', ns):
    row_num = int(row.attrib.get('r', 0))
    cells = {}
    for cell in row.findall('s:c', ns):
        ref = cell.attrib.get('r', '')
        cell_type = cell.attrib.get('t', '')
        val_elem = cell.find('s:v', ns)
        val = val_elem.text if val_elem is not None else None
        
        if cell_type == 's' and val is not None:
            val = shared_strings[int(val)]
        
        col_match = re.match(r'([A-Z]+)', ref)
        col = col_match.group(1) if col_match else ''
        cells[col] = val
    
    rows_data.append((row_num, cells))

for row_num, cells in rows_data:
    print(f'Row {row_num}: {dict(sorted(cells.items()))}')
