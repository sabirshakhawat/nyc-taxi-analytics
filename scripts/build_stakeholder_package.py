"""Build portable Tableau dashboards and verified presentation evidence.

First run: --source /path/to/the/user-saved.twbx
Later runs default to the checked-in TWB. Original input is never overwritten.
"""
import argparse
import copy
import csv
import json
import os
from pathlib import Path
import uuid
import xml.etree.ElementTree as E
from zipfile import ZipFile, ZIP_DEFLATED

import duckdb
from tableauhyperapi import HyperProcess, Connection, Telemetry, CreateMode, TableDefinition, TableName, SqlType, Inserter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'tableau'
USER_NS = 'http://www.tableausoftware.com/xml/user'
E.register_namespace('user', USER_NS)


def sub(parent, tag, text=None, **attrs):
    node = E.SubElement(parent, tag, attrs)
    if text is not None: node.text = str(text)
    return node


def dataset(connection, query):
    result = connection.execute(query)
    names = [c[0] for c in result.description]
    rows = result.fetchall()
    return names, rows


def source_xml(name, view, fields, rows, old=None):
    ds = E.Element('datasource', caption=view.replace('_', ' ').title(), inline='true', name=name, version='18.1')
    leaf = 'textscan.' + uuid.uuid5(uuid.NAMESPACE_URL, view).hex
    obj = view + '.csv_' + uuid.uuid5(uuid.NAMESPACE_DNS, view).hex.upper()
    conn = sub(ds, 'connection', **{'class':'federated'})
    named = sub(sub(conn, 'named-connections'), 'named-connection', caption=view, name=leaf)
    sub(named, 'connection', **{'class':'textscan','directory':'Data','filename':view+'.csv','password':'','server':''})
    rel = sub(conn,'relation',connection=leaf,name=view+'.csv',table='['+view+'#csv]',type='table')
    cols = sub(rel,'columns',**{'character-set':'UTF-8','header':'yes','locale':'en_US','separator':','})
    metadata = sub(conn,'metadata-records')
    previous = {c.get('name'):c for c in old.findall('column')} if old is not None else {}
    types=[]
    for i, field in enumerate(fields):
        values = [row[i] for row in rows if row[i] is not None]
        sample = values[0] if values else ''
        import datetime
        kind = 'date' if isinstance(sample,datetime.date) else 'integer' if isinstance(sample,int) else 'real' if isinstance(sample,float) else 'string'
        types.append(kind)
        sub(cols,'column',datatype=kind,name=field,ordinal=str(i))
        rec=sub(metadata,'metadata-record',**{'class':'column'})
        for key,value in {'remote-name':field,'remote-type':{'integer':20,'real':5,'string':129,'date':133}[kind], 'local-name':'['+field+']','parent-name':'['+view+'.csv]','remote-alias':field,'ordinal':i,'local-type':kind,'aggregation':'Year' if kind=='date' else 'Count' if kind=='string' else 'Sum','contains-null':'true','object-id':'['+obj+']'}.items():sub(rec,key,value)
    sub(ds,'aliases',enabled='yes')
    for field,kind in zip(fields,types):
        col=previous.get('['+field+']')
        if col is not None: ds.append(copy.deepcopy(col))
        else:sub(ds,'column',caption=field.replace('_',' ').title(),datatype=kind,name='['+field+']',role='dimension' if kind in ('date','string') else 'measure',type='nominal' if kind=='string' else 'ordinal' if kind=='date' else 'quantitative')
    extract=sub(ds,'extract',enabled='true',count='-1',units='records',**{'object-id':'','user-specific':'false'})
    ec=sub(extract,'connection',**{'class':'hyper','dbname':'Data/Extracts/'+view+'.hyper','schema':'Extract','tablename':'Extract','access_mode':'readonly'})
    sub(ec,'relation',name='Extract',table='[Extract].[Extract]',type='table')
    em=copy.deepcopy(metadata)
    for rec in em:
        rec.find('parent-name').text='[Extract]'
    ec.append(em)
    graph=sub(ds,'object-graph'); ob=sub(sub(graph,'objects'),'object',caption=view+'.csv',id=obj)
    sub(ob,'properties',context='').append(copy.deepcopy(rel))
    sub(sub(ob,'properties',context='extract'),'relation',name='Extract',table='[Extract].[Extract]',type='table')
    return ds,types


def table_sheet(name, source, fields):
    w=E.Element('worksheet',name=name);t=sub(w,'table');v=sub(t,'view')
    sub(sub(v,'datasources'),'datasource',name=source)
    dep=sub(v,'datasource-dependencies',datasource=source)
    for f in fields:
        sub(dep,'column',caption=f.replace('_',' '),datatype='string',name='['+f+']',role='dimension',type='nominal')
        sub(dep,'column-instance',column='['+f+']',derivation='None',name='[none:'+f+':nk]',pivot='key',type='nominal')
    sub(v,'aggregation',value='true');sub(t,'style')
    pane=sub(sub(t,'panes'),'pane',**{'selection-relaxation-option':'selection-relaxation-allow'})
    sub(sub(pane,'view'),'breakdown',value='auto');sub(pane,'mark',**{'class':'Text'})
    sub(sub(pane,'encodings'),'text',column='['+source+'].[none:Label:nk]')
    sub(t,'rows','('+' * '.join('['+source+'].[none:'+f+':nk]' for f in fields if f!='Label')+')')
    sub(t,'cols');sub(w,'simple-id',uuid='{'+str(uuid.uuid4()).upper()+'}')
    return w


def dashboard(parent,name,charts,texts):
    d=sub(parent,'dashboard',name=name,**{'lock-updates':'true'});sub(d,'style')
    sub(d,'size',maxheight='1000',minheight='1000',maxwidth='1500',minwidth='1500',**{'sizing-mode':'fixed'})
    zones=sub(d,'zones');base=sub(zones,'zone',id='0',x='0',y='0',w='100000',h='100000',**{'type-v2':'layout-basic'})
    i=0
    for text,x,y,w,h,size,bold in texts:
        i+=1;z=sub(base,'zone',id=str(i),x=str(x),y=str(y),w=str(w),h=str(h),**{'type-v2':'text','forceUpdate':'true'})
        sub(sub(z,'formatted-text'),'run',text,fontsize=str(size),bold=str(bold).lower(),fontcolor='#18384b')
    for sheet,x,y,w,h in charts:
        i+=1;z=sub(base,'zone',id=str(i),name=sheet,x=str(x),y=str(y),w=str(w),h=str(h))
        sub(z,'layout-cache',**{'type-h':'scalable','type-w':'scalable'})
    sub(d,'simple-id',uuid='{'+str(uuid.uuid4()).upper()+'}')
    return d


def main():
    (ROOT / '.build').mkdir(exist_ok=True)
    parser=argparse.ArgumentParser();parser.add_argument('--source',type=Path,default=OUT/'NYC Taxi Demand.twb');args=parser.parse_args()
    os.chdir(ROOT)
    if args.source.suffix=='.twbx':
        with ZipFile(args.source) as z:r=E.fromstring(z.read(next(n for n in z.namelist() if n.endswith('.twb'))))
    else:r=E.parse(args.source).getroot()
    for directory in [OUT/'Data/Extracts',ROOT/'presentation',ROOT/'docs']:directory.mkdir(parents=True,exist_ok=True)
    c=duckdb.connect(':memory:')
    for folder in ['02_staging','03_models','05_analysis']:
        for file in sorted((ROOT/'sql'/folder).glob('*.sql')):c.execute(file.read_text())
    checks=[]
    for file in sorted((ROOT/'sql/04_quality').glob('*.sql')):
        result=c.execute(file.read_text()); names=[x[0] for x in result.description]
        for row in result.fetchall():
            assert 'PASS' in row and 'FAIL' not in row,(file.name,row)
            checks.append({'file':file.name,**dict(zip(names,row))})
    summary=dict(zip(['eligible_trips','recorded_payments','avg_payment','avg_minutes','missing_passenger_count'],c.execute('SELECT COUNT(*),SUM(total_amount),AVG(total_amount),AVG(trip_duration_minutes),COUNT(*) FILTER (WHERE passenger_count IS NULL) FROM enriched_yellow_trips').fetchone()))
    summary['january_source_trips']=c.execute('SELECT COUNT(*) FROM stg_yellow_trips').fetchone()[0]
    summary['top15_share_pct']=c.execute('SELECT 100.0*SUM(total_trip_count)/? FROM (SELECT total_trip_count FROM zone_performance ORDER BY total_trip_count DESC LIMIT 15)',[summary['eligible_trips']]).fetchone()[0]
    evidence={'summary':summary,'quality_checks':checks,'source':'NYC TLC January 2026 yellow taxi trips','reporting_period':'2026-01-01 through 2026-01-31'}
    sets={}
    for view,order in [('daily_demand_revenue','pickup_date'),('hourly_demand','pickup_hour'),('zone_performance','total_trip_count DESC'),('zone_hourly_performance','pickup_zone,pickup_hour_of_the_day'),('priority_windows','zone_rank'),('airport_comparison','pickup_segment')]:
        fields,rows=dataset(c,'SELECT * FROM '+view+' ORDER BY '+order);sets[view]=(fields,rows)
        evidence[view]=[dict(zip(fields,row)) for row in rows]
    priority=evidence['priority_windows'];airport=evidence['airport_comparison']
    sets['priority_table']=(['Priority_zone','Peak_hour','Pickups_per_day_in_peak_hour','Monthly_trip_share','Label'],[(f"{p['zone_rank']}. {p['pickup_zone']}",f"{p['peak_hour']:02}:00",f"{p['avg_peak_hour_trips_per_calendar_day']:,.1f}",f"{p['monthly_trip_share_pct']:.2f}%",'') for p in priority])
    sets['airport_table']=(['Pickup_area','January_trips','Payment_per_trip_USD','Minutes_per_trip','Label'],[(p['pickup_segment'],f"{p['total_trips']:,}",f"${p['avg_recorded_payment_usd']:,.2f}",f"{p['avg_trip_minutes']:.1f}",'') for p in airport])
    (ROOT/'docs/analysis_evidence.json').write_text(json.dumps(evidence,default=str,indent=2)+'\n')
    used={d.get('name') for d in r.findall('worksheets/worksheet/table/view/datasources/datasource')}
    sources=r.find('datasources'); mappings={}
    for d in list(sources):
        if d.get('name') not in used:sources.remove(d);continue
        caption=d.get('caption','').lower().replace(' ', '_')
        view='daily_demand_revenue' if 'daily_demand' in caption else 'zone_hourly_performance' if 'zone_hourly' in caption else 'hourly_demand' if 'hourly_demand' in caption else 'zone_performance'
        mappings[d.get('name')]=(view,d)
    for view in ['priority_table','airport_table']:mappings['federated.'+view]=(view,None)
    sources.clear()
    with HyperProcess(Telemetry.DO_NOT_SEND_USAGE_DATA_TO_TABLEAU,parameters={'default_database_version':'2','log_dir':str(ROOT/'.build')}) as hyper:
        for name,(view,old) in mappings.items():
            fields,rows=sets[view];ds,types=source_xml(name,view,fields,rows,old);sources.append(ds)
            with (OUT/'Data'/f'{view}.csv').open('w',newline='') as stream:
                writer=csv.writer(stream);writer.writerow(fields);writer.writerows(rows)
            target=OUT/'Data/Extracts'/f'{view}.hyper'
            with Connection(hyper.endpoint,str(target),CreateMode.CREATE_AND_REPLACE) as hc:
                hc.catalog.create_schema('Extract')
                types_map={'integer':SqlType.big_int(),'real':SqlType.double(),'string':SqlType.text(),'date':SqlType.date()}
                table=TableDefinition(TableName('Extract','Extract'),[TableDefinition.Column(f,types_map[t]) for f,t in zip(fields,types)])
                hc.catalog.create_table(table)
                with Inserter(hc,table) as insert:insert.add_rows(rows);insert.execute()
                assert hc.execute_scalar_query('SELECT COUNT(*) FROM "Extract"."Extract"')==len(rows)
    worksheets=r.find('worksheets')
    for w in list(worksheets):
        if w.get('name') in ['Priority pickup windows','Airport trip comparison']:worksheets.remove(w)
    for view,name in [('priority_table','Priority pickup windows'),('airport_table','Airport trip comparison')]:worksheets.append(table_sheet(name,'federated.'+view,sets[view][0]))
    for col in r.iter('column'):
        if col.get('name')=='[pickup_hour]':col.set('role','dimension');col.set('type','ordinal')
        if col.get('name')=='[avg_passenger_amount]':col.set('caption','Average Reported Passengers per Trip')
    for k in list(r.attrib):
        if 'Fingerprint' in k:del r.attrib[k]
    for parent in r.iter():
        for ch in list(parent):
            if 'Fingerprint' in ch.tag:parent.remove(ch)
    for tag in ['dashboards','windows','thumbnails']:
        for ch in r.findall(tag):r.remove(ch)
    db=sub(r,'dashboards')
    title=lambda t:[(t,1800,1000,96000,6500,25,True)]
    dashboard(db,'01 Demand overview',[
        ('Daily Taxi Demand - January 2026',1500,19000,48000,32000),
        ('Avg Daily Trips by Pickup Hour - January 2026',50500,19000,48000,32000),
        ('Top 15 Pickup Zones by Trip - January 2026',1500,53000,41000,38000),
        ('Hourly Pickup Demand by Selected Zone - January 2026',43500,53000,55000,38000)],
        title('NYC yellow taxi demand: January 2026')+[
        (f"{summary['eligible_trips']:,} eligible trips     ${summary['recorded_payments']/1e6:.2f}M recorded payments     {summary['top15_share_pct']:.1f}% in the top 15 zones",1800,9000,96000,6500,18,True),
        ('Heatmap: darker means more pickups. Its averages include active days only. Recorded pickups do not measure unmet demand.',1800,93000,96000,5000,11,False)])
    dashboard(db,'02 Coverage and airport decisions',[
        ('Priority pickup windows',1800,18000,96000,24000),('Airport trip comparison',1800,54000,96000,18000)],title('Where should the fleet test different coverage?')+[
        ('Top five zones by monthly trips. Peak-hour averages below include all 31 calendar days.',1800,10500,96000,5000,14,False),
        ('Test shift overlaps near these peak windows. Check nearby supply and repositioning costs before moving drivers.',1800,43000,96000,6000,14,False),
        ('Airport payments and trip time',1800,49000,96000,4500,18,True),
        ('Higher airport payments come with longer trips. These figures omit waiting, empty return travel and operating costs.',1800,74000,96000,6500,14,False),
        ('Decision: approve a limited pilot using existing vehicles, subject to dispatch and driver availability. Validate January patterns against recent months first.',1800,84000,96000,10000,16,True)])
    dashboard(db,'03 Pilot and measurement',[],title('A four-week pilot with a measurable business outcome')+[
        ('Goal: improve net earnings per driver working hour without worsening service coverage.',2000,13000,95000,9000,22,True),
        ('Pilot design\nOperations selects comparable zone and shift groups. One group tests revised shift overlaps; the comparison group keeps its current schedule. Check weekday mix, weather and events.',2000,26000,95000,18000,17,False),
        ('Measurement\nPrimary: net earnings divided by all working hours. Supporting: trips per working hour and empty miles. Safeguard: passenger waiting time and coverage in comparison zones.',2000,47000,95000,18000,17,False),
        ('Decision gate\nAgree an economically meaningful improvement threshold and minimum sample before launch. Expand only when the pilot clears that threshold and service safeguards hold.',2000,68000,95000,16000,17,False),
        ('Data needed: driver shifts, dispatch activity, waiting time, fuel and other costs. TLC trip records alone cannot demonstrate profit uplift. Source: NYC TLC, January 2026.',2000,89000,95000,8000,12,False)])
    windows=sub(r,'windows',**{'source-height':'30'})
    for sheet in worksheets:
        w=sub(windows,'window',**{'class':'worksheet','name':sheet.get('name')});cards=sub(w,'cards');edge=sub(cards,'edge',name='top')
        for typ in ['columns','rows','title']:sub(sub(edge,'strip',size='31'),'card',type=typ)
        sub(sub(w,'viewpoint'),'zoom',type='entire-view');sub(w,'simple-id',uuid='{'+str(uuid.uuid4()).upper()+'}')
    for i,d in enumerate(db):
        attrs={'class':'dashboard','name':d.get('name')}
        if i==0:attrs['maximized']='true'
        w=sub(windows,'window',**attrs);v=sub(w,'viewpoints')
        for z in d.findall('.//zone[@name]'):sub(sub(v,'viewpoint',name=z.get('name')),'zoom',type='entire-view')
        sub(w,'active',id='-1');sub(w,'device-preview');sub(w,'simple-id',uuid='{'+str(uuid.uuid4()).upper()+'}')
    tree=E.ElementTree(r);E.indent(tree,space='  ')
    target=OUT/'NYC Taxi Demand.twb';tree.write(target,encoding='utf-8',xml_declaration=True)
    assert '/Users/' not in target.read_text()
    with ZipFile(target.with_suffix('.twbx'),'w',ZIP_DEFLATED) as z:
        z.write(target,target.name)
        for name,(view,_) in mappings.items():
            for file in [OUT/'Data'/f'{view}.csv',OUT/'Data/Extracts'/f'{view}.hyper']:z.write(file,str(file.relative_to(OUT)))
    with ZipFile(target.with_suffix('.twbx')) as z:assert z.testzip() is None
    print(json.dumps({'checks_passed':len(checks),'summary':summary,'priority_windows':priority,'airport_comparison':airport},default=str,indent=2))


if __name__=='__main__':main()
