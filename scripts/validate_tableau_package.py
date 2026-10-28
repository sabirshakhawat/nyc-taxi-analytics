"""Check package wiring and embedded data; this does not replace Tableau visual QA."""
import csv
import io
from pathlib import Path
import xml.etree.ElementTree as E
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]


def main():
    folder = ROOT / 'tableau'
    with ZipFile(folder / 'NYC Taxi Demand.twbx') as package:
        assert package.testzip() is None
        xml = package.read('NYC Taxi Demand.twb')
        assert xml == (folder / 'NYC Taxi Demand.twb').read_bytes()
        assert b'/Users/' not in xml and b'tableau-temp' not in xml
        root = E.fromstring(xml)
        sources = {d.get('name'): d for d in root.findall('datasources/datasource')}
        assert len(sources) == 6
        for source in sources.values():
            extract = source.find('extract')
            assert {'count', 'units', 'object-id', 'enabled'} <= extract.attrib.keys()
            hyper = extract.find('connection').get('dbname')
            assert package.read(hyper) == (folder / hyper).read_bytes()
            connection = source.find('connection')
            names = {n.get('name') for n in connection.findall('named-connections/named-connection')}
            assert connection.find('relation').get('connection') in names
            text = connection.find('named-connections/named-connection/connection')
            path = text.get('directory') + '/' + text.get('filename')
            rows = list(csv.reader(io.StringIO(package.read(path).decode())))
            fields = [c.get('name') for c in connection.findall('relation/columns/column')]
            assert rows[0] == fields
            assert all(len(row) == len(fields) for row in rows[1:])
        sheets = {s.get('name') for s in root.findall('worksheets/worksheet')}
        assert len(sheets) == 6
        for ref in root.findall('worksheets/worksheet/table/view/datasources/datasource'):
            assert ref.get('name') in sources
        assert len(root.findall('dashboards/dashboard')) == 3
        for zone in root.findall('dashboards/dashboard/zones//zone[@name]'):
            assert zone.get('name') in sheets
        for window in root.findall('windows/window'):
            tags = [child.tag for child in window]
            expected = ['viewpoints', 'active', 'device-preview', 'simple-id'] if window.get('class') == 'dashboard' else ['cards', 'viewpoint', 'simple-id']
            assert tags == expected, (window.get('name'), tags)
    print('PASS: ZIP, six datasets, relative paths, extract attributes, six sheets, three dashboards, window structure')


if __name__ == '__main__':
    main()
