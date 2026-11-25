"""Rebuild the desktop option index from an installed DST scripts.zip (Python 3)."""
import json
import re
import sys
import zipfile
from pathlib import Path

archive = zipfile.ZipFile(sys.argv[1])
def read(name):
    return archive.read('scripts/' + name).decode('utf-8-sig')

lua = re.sub(r'--[^\n]*', '', read('map/customize.lua'))
po = {key: (json.loads(en), json.loads(ru) or json.loads(en))
      for key, en, ru in re.findall(r'msgctxt "([^"\n]+)"\s+msgid ("[^\n]*")\s+msgstr ("[^\n]*")', read('languages/russian.po'))}
def label(key, fallback):
    return po.get(key, (fallback.replace('_', ' ').capitalize(),) * 2)

lists = {}
for name, body in re.findall(r'(\w+)\s*=\s*\{\s*\n((?:\s*\{\s*text[^\n]+\n)+)\s*\}', lua):
    if name in lists and name != 'size_descriptions':
        continue
    choices = {}
    for text, value in re.findall(r'\{\s*text\s*=\s*(.*?),\s*data\s*=\s*"([^"]+)"', body):
        keys = re.findall(r'STRINGS\.[A-Z0-9_.]+', text)
        tokens = [label(k, value) for k in keys]
        choices[value] = [' '.join(parts) for parts in zip(*tokens)] if tokens else [value,value]
    lists[name] = choices
lists['ocean_worldgen_frequency_descriptions'] = {'ocean_'+k:v for k,v in lists['worldgen_frequency_descriptions'].items()}

for name, fn, source in [('task_set','AddTaskSet','scripts/map/tasksets/'),('start_location','AddStartLocation','scripts/map/startlocations.lua')]:
    for loc in ['forest','cave']:
        choices = {}
        for entry in archive.namelist():
            if not entry.startswith(source) or not entry.endswith('.lua'):
                continue
            for key, body in re.findall(fn+r'\("([^"]+)",\s*\{(.*?)(?=\s*\}\s*\))',archive.read(entry).decode('utf-8'),re.S):
                where = re.search(r'location\s*=\s*"(\w+)"', body)
                if (where[1] if where else 'forest') != loc or 'hideinfrontend = true' in body:
                    continue
                title = re.search(r'name\s*=\s*(STRINGS\.[A-Z0-9_.]+)',body)
                choices[key]=label(title[1] if title else '',key)
        if name=='task_set':
            filename='scripts/map/tasksets/'+('forest' if loc=='forest' else 'caves')+'.lua'
            choices={k:label('',k) for k in re.findall(r'AddTaskSet\("([^"]+)"',archive.read(filename).decode())}
        lists[name+'_'+loc]=choices

rows=[]
sync=set()
for phase in ('WORLDGEN', 'WORLDSETTINGS'):
    section=lua.split('local '+phase+'_GROUP = {',1)[1].split('local '+phase+'_MISC',1)[0]
    for group,body in re.findall(r'^\s*\["(\w+)"\]\s*=\s*\{\s*\n(.*?)(?=^\s*\}\s*,?\s*\n\s*\}\s*[,}])', section,re.M|re.S):
        meta, items = re.split(r'\bitems\s*=\s*\{',body,maxsplit=1)
        default_desc=re.search(r'\bdesc\s*=\s*(\w+)',meta)[1]
        for key,line in re.findall(r'^\s*\["(\w+)"\]\s*=\s*\{([^\n]+)',items,re.M):
            if re.search(r'master_sync\s*=\s*true',line): sync.add(key)
            scope=re.search(r'\bworld\s*=\s*\{([^}]+)',line)
            worlds=re.findall(r'"(\w+)"',scope[1]) if scope else ['forest','cave']
            if re.search(r'master_controlled\s*=\s*true',line):
                worlds=[w for w in worlds if w=='forest']
            desc=re.search(r'\bdesc\s*=\s*([\w.]+)',line)
            choice=desc[1] if desc else default_desc
            for world in worlds:
                source=key+'_'+world if key in ('task_set','start_location') else choice
                assert lists.get(source), (key, source, world)
                icon=re.search(r'\bimage\s*=\s*"([^"]+)"',line)[1]
                rows.append([key, *label('STRINGS.UI.CUSTOMIZATIONSCREEN.'+key.upper(),key),phase,group,world,source,icon])
    expected = set(re.findall(r'^\s*\["(\w+)"\]\s*=\s*\{\s*value\s*=',section,re.M))
    assert expected == {r[0] for r in rows if r[3]==phase}, expected-{r[0] for r in rows}
out=Path(__file__).resolve().parents[1]/'lib/domain/world_catalog.dart'
with out.open('w',encoding='utf-8',newline='\n') as f:
    f.write('// Generated interoperability metadata. Regenerate with tool/generate_world_catalog.py.\n')
    f.write('const syncedWorldKeys = <String>{'+','.join(json.dumps(k) for k in sorted(sync))+'};\n')
    for key,data in [('worldChoices',{k:lists[k] for k in sorted({r[6] for r in rows})}),('worldRows', rows)]:
        literal=json.dumps(data,ensure_ascii=False).replace('$',r'\$')
        f.write('const '+key+' = '+literal+';\n')
print('Settings by shard:', {w:sum(r[5]==w for r in rows) for w in ('forest','cave')})
