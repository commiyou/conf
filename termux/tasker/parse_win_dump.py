#!/data/data/com.termux/files/usr/bin/python
import os
import xml.etree.ElementTree as ET

os.system('uiautomator dump')
tree = ET.parse('/sdcard/window_dump.xml')
root = tree.getroot()

elements = []
for node in root.iter():
    if node.tag == 'node':
        element = {}
        element['id'] = node.attrib.get('resource-id')
        element['clickable'] = node.attrib.get('clickable')
        element['bounds'] = node.attrib.get('bounds')
        element['text'] = node.attrib.get('text')
        element['desc'] = node.attrib.get('content-desc')
        if element['clickable'] == 'false':
            continue
        if not element['id'] and not element['text'] and not element['desc']:
            continue

        elements.append(element)

#print(elements)
print('==:=='.join(str(element).replace(',', "&") for element in elements))


