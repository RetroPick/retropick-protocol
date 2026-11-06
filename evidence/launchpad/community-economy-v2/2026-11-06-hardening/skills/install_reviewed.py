#!/usr/bin/env python3
"""Install source-pinned documentation skills with the official CLI, never execute skill helpers."""
import ast, datetime, hashlib, io, json, os, pathlib, re, subprocess, tarfile, urllib.request
ROOT=pathlib.Path.cwd()
E=ROOT/'evidence/launchpad/community-economy-v2/2026-11-06-hardening/skills'
D=ROOT/'research/launchpad/community-economy-v2/iterations/007-v2-final-financial-security-qualification/skills'
SOURCES=[
 ('trailofbits/skills','470419e16f97e112d01fc32f4898aea1755015d9',['entry-point-analyzer','differential-review','token-integration-analyzer','code-maturity-assessor','guidelines-advisor','property-based-testing','post-patch-validation'],'CC-BY-SA-4.0'),
 ('schwepps/skills','8aa9a4e0eec8bdcbcc51dff95ce4bdbdb5edde01',['solidity-auditor'],'MIT'),
 ('hraness/skillpack','d079193ed0db9285e5cc0bb58836af5dbc72882a',['refactor-maintainer'],'MIT with PStack attribution'),
 ('vercel-labs/skills','d3701c11b1101251af14c9d148f026e1a47ebe17',['find-skills'],'MIT')]
def sha(b):return hashlib.sha256(b).hexdigest()
def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'RetroPick-reviewed-skill-install'}),timeout=45).read()
manifest={'schemaVersion':1,'sourceCommit':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'agent':'codex','cli':{'package':'skills','version':'1.7.6','telemetry':False,'npmLifecycleScripts':False},'started':datetime.datetime.now(datetime.timezone.utc).isoformat(),'sources':[],'decisions':{'pseudoyu/agent-skills':'REJECTED: inspected revision 2364eaed43518e27ff84af71c21f11bac8a41594 has no license; do not vendor','fix-review':'UNAVAILABLE at pinned Trail of Bits revision; reviewed post-patch-validation selected instead','audit-context-building':'DEFERRED: Claude Workflow routing is not a callable Codex workflow','coverage-analysis':'NOT_SELECTED: use existing Foundry instrumentation and selected property-based-testing guidance'},'status':'RUNNING'}
for repo,rev,names,license_name in SOURCES:
 data=get('https://codeload.github.com/'+repo+'/tar.gz/'+rev)
 archive=tarfile.open(fileobj=io.BytesIO(data),mode='r:gz');base=archive.getmembers()[0].name.split('/')[0]+'/'
 files={m.name.removeprefix(base):archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
 source={'repository':repo,'revision':rev,'archiveSha256':sha(data),'license':license_name,'skills':[]}
 for name in names:
  target=ROOT/'.agents/skills'/name
  if target.exists():raise SystemExit('Refuse overwrite: '+str(target))
  candidates=[p for p in files if p.endswith('/'+name+'/SKILL.md') or p==name+'/SKILL.md']
  if len(candidates)!=1:raise SystemExit('Ambiguous/missing skill: '+name)
  path=candidates[0].rsplit('/',1)[0]+'/'
  closure={p:sha(b) for p,b in files.items() if p.startswith(path)}
  scripts=[]
  for p,b in files.items():
   if not p.startswith(path):continue
   text=b.decode(errors='replace')
   if p.endswith('.py'):
    tree=ast.parse(text)
    scripts.append({'path':p,'sha256':sha(b),'imports':sorted({n.names[0].name if isinstance(n,ast.Import) else str(n.module) for n in ast.walk(tree) if isinstance(n,(ast.Import,ast.ImportFrom))}),'subprocess': 'subprocess.' in text,'networkImports':bool(re.search(r'^(?:import|from) (?:requests|urllib|socket|httpx)',text,re.M)),'shellTrue':bool(re.search(r'shell\s*=\s*True',text))})
   if re.search(r'(?:curl|wget)[^\n]*\|\s*(?:sh|bash)',text):raise SystemExit('Reject remote shell pipe in '+p)
  source['skills'].append({'name':name,'upstreamPath':path.rstrip('/'),'upstreamFiles':closure,'scripts':scripts,'scriptExecution':'NOT_RUN','review':'Source and instructions reviewed; local subprocess/worktree behavior in post-patch helper requires a separately authorized pinned validation plan; no helper executed.'})
 command=['npx','--yes','--package=skills@1.7.6','skills','add','https://github.com/'+repo+'/tree/'+rev,'--skill',*names,'--agent','codex','--copy','--yes','--json']
 env=os.environ.copy();env.update(DISABLE_TELEMETRY='1',DO_NOT_TRACK='1',npm_config_ignore_scripts='true',NO_COLOR='1')
 result=subprocess.run(command,cwd=ROOT,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180)
 log=E/(repo.split('/')[0]+'-install.log');log.write_text(result.stdout)
 source.update(command=command,exitCode=result.returncode,log=str(log.relative_to(ROOT)),logSha256=sha(log.read_bytes()))
 for skill in source['skills']:
  target=ROOT/'.agents/skills'/skill['name']
  skill['installed']=result.returncode==0 and (target/'SKILL.md').is_file()
  if skill['installed']:
   for p,digest in skill['upstreamFiles'].items():
    installed=target/p.removeprefix(skill['upstreamPath']+'/')
    if not installed.is_file() or sha(installed.read_bytes())!=digest:raise SystemExit('Installed content mismatch: '+str(installed))
   notices={'UPSTREAM_LICENSE':files['LICENSE']}
   if repo=='hraness/skillpack':
    notices['UPSTREAM_PROVENANCE.md']=files['plugins/hraness-engineering/PROVENANCE.md']
   for p,b in notices.items():(target/p).write_bytes(b)
   skill['installedFiles']={str(p.relative_to(target)):sha(p.read_bytes()) for p in sorted(target.rglob('*')) if p.is_file()}
 manifest['sources'].append(source)
 (D/'MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
 if result.returncode:raise SystemExit('CLI install failed: '+repo)
 print('Installed and content-verified',repo,rev,flush=True)
manifest.update(status='PASS',finished=datetime.datetime.now(datetime.timezone.utc).isoformat())
(D/'MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n')
