#!/usr/bin/env python3
"""Export ABI-only JSON and provenance; never serialize keys or broadcast data.

Requires existing exact-release Foundry artifacts and the pinned official Kuru SDK.
Does not compile or alter frozen Solidity. All paths are relative in the output.
"""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE_SHA = 'f0363249f4b74e58dde37d1241742ca5a92bcfe3'
KURU_SHA = '636509c2eafd63479d3f399703354e0d09f51e18'
KURU_CONTRACT_SHA = '2060bb2736080c175d80d568bfdb6226bb5abd04'
OWN = {
 'quoteRegistry':'RetroPickQuoteAssetRegistryV2', 'feeEscrow':'RetroPickFeeEscrowV2',
 'hookDeployer':'RetroPickHookDeployerV2','hook':'RetroPickMemeHookV2',
 'buybackVault':'RetroPickBuybackVaultV2','locker':'RetroPickLaunchLockerV2',
 'kuruEnvironment':'KuruEnvironmentV2','coordinator':'GraduationCoordinatorV2',
 'kuruExecutor':'KuruGraduationExecutorV2','v4Executor':'UniswapV4GraduationExecutorV2',
 'factory':'RetroPickLaunchFactoryV2','launchDeployer':'RetroPickLaunchDeployerV2',
 'kuruDonationLock':'ExecutorDonationLockV2','v4DonationLock':'ExecutorDonationLockV2',
 'v4Guard':'RetroPickGraduationGuardV2',
}
UPSTREAM = {
 'wrappedNative':('WETH','deployment-v4/out/WETH.sol/WETH.json'),
 'permit2':('Permit2','lib/v4-deployment-periphery/lib/permit2/out/Permit2.sol/Permit2.json'),
 'poolManager':('PoolManager','deployment-v4/out/PoolManager.sol/PoolManager.json'),
 'positionDescriptor':('PositionDescriptor','deployment-v4/out/PositionDescriptor.sol/PositionDescriptor.json'),
 'positionManager':('PositionManager','deployment-v4/out/PositionManager.sol/PositionManager.json'),
}

def git(path,*args):
 return subprocess.check_output(['git','-C',str(path),*args], text=True).strip()

def write(path,value):
 path.parent.mkdir(parents=True,exist_ok=True)
 path.write_text(json.dumps(value,indent=2)+'\n')

def export(source,kuru,kuru_contracts):
 # Ensure the deployed commit actually exists, not just a user-provided SHA label.
 assert git(source,'rev-parse',SOURCE_SHA)==SOURCE_SHA
 assert git(kuru,'rev-parse','HEAD')==KURU_SHA, 'Check out the qualified Kuru SDK pin first'
 assert git(kuru_contracts,'rev-parse','HEAD')==KURU_CONTRACT_SHA, 'Check out the qualified Kuru contracts pin first'
 deployment=json.loads((ROOT/'deployments/monad-testnet/v2.json').read_text())
 assert deployment['gitSHA']==SOURCE_SHA
 target=ROOT/'deployments/monad-testnet/abi'
 manifest={'schemaVersion':1,'chainId':10143,'deploymentBlock':deployment['deploymentBlock'],
  'deployedSourceSHA':SOURCE_SHA,'sourceManifest':'../v2.json',
  'kuruSDKSourceSHA':KURU_SHA,'kuruContractsSourceSHA':KURU_CONTRACT_SHA,
  'contracts':[],'templates':{},'excluded':[{'role':'owner','address':deployment['addresses']['owner'],'reason':'EOA; no contract ABI'},{'role':'nativeMON','address':'0x0000000000000000000000000000000000000000','reason':'Native asset; no ERC20 contract ABI'}],
  'limitations':['Canonical Circle USDC is an external proxy. Only the qualified ERC20 interface is exported; its full implementation ABI has not been independently established.','Kuru ABIs are compiled from the pinned qualified official contract source, including overloads missing from the SDK. Dependency commits are recorded. This is not a verified deployed-bytecode match; runtime identity validation remains required.']}
 files={}
 def artifact(name,path,origin):
  doc=json.loads(path.read_text()); abi=doc['abi']; assert isinstance(abi,list) and abi
  metadata=doc.get('metadata',{})
  if isinstance(metadata,str): metadata=json.loads(metadata)
  # Match local RetroPick source blobs against the deployed source commit.
  for key in metadata.get('sources',{}):
   if key.startswith('src/v2/'):
    deployed=subprocess.check_output(['git','-C',str(source),'show',SOURCE_SHA+':contracts/'+key])
    assert deployed==(source/'contracts'/key).read_bytes(), f'Source drift: {key}'
  # Also cross-check ABI against the compiler metadata when available.
  if metadata.get('output',{}).get('abi') is not None:
   normalize = lambda items: sorted(json.dumps({**x, 'inputs':x.get('inputs',[]), **({'outputs':x.get('outputs',[])} if x['type']=='function' else {})},sort_keys=True) for x in items)
   assert normalize(metadata['output']['abi'])==normalize(abi), f'Metadata ABI mismatch: {name}'
  raw=(json.dumps(abi,indent=2)+'\n').encode()
  previous=files.get(name)
  assert previous is None or previous['abiSHA256']==hashlib.sha256(raw).hexdigest(), f'Conflicting ABI: {name}'
  info={'contractName':name,'abi':name+'.json','coverage':'FULL_ARTIFACT_ABI',
   'origin':origin,'artifactSHA256':hashlib.sha256(path.read_bytes()).hexdigest(),
   'abiSHA256':hashlib.sha256(raw).hexdigest(),
   'functions':sum(x['type']=='function' for x in abi),'events':sum(x['type']=='event' for x in abi),'errors':sum(x['type']=='error' for x in abi)}
  if metadata.get('compiler'): info['compiler']=metadata['compiler']['version']
  if metadata.get('settings'): info['compilerSettings']=metadata['settings']
  files[name]=info
  write(target/(name+'.json'),abi)
  return info
 def local(name):
  paths=list((source/'contracts/out').glob('*/'+name+'.json'))
  assert len(paths)==1, f'Expected exact artifact for {name}: {paths}'
  return artifact(name,paths[0],{'kind':'DEPLOYED_RELEASE_FOUNDRY','path':str(paths[0].relative_to(source)),'gitSHA':SOURCE_SHA})
 def add(role,address,info):
  manifest['contracts'].append({'role':role,'address':address,**info})
 for role,name in OWN.items(): add(role,deployment['addresses'][role],local(name))
 for role,(name,relative) in UPSTREAM.items():
  add(role,deployment['addresses'][role],artifact(name,source/'contracts'/relative,{'kind':'DEPLOYMENT_DEPENDENCY_FOUNDRY','path':'contracts/'+relative,'deploymentSourceSHA':SOURCE_SHA}))
 for role,name in [('token','RetroPickLauncherTokenV2'),('curve','RetroPickBondingCurveV2'),('lpLock','KuruLiquidityLockV2')]:
  info=local(name); add('demo.'+role,deployment['monLaunch'][role],info)
  manifest['templates'][role]={'abi':info['abi'],'discovery':'TokenLaunched' if role!='lpLock' else 'GraduationCompleted + Coordinator.receipt','coverage':info['coverage']}
 for role,name,address in [('kuruRouter','Router',deployment['kuruEnvironment']['router']),('kuruMarginAccount','MarginAccount',deployment['kuruEnvironment']['marginAccount']),('demo.market','OrderBook',deployment['monLaunch']['market']),('demo.vault','KuruAMMVault',deployment['monLaunch']['vault']),('kuruOrderBookImplementation','OrderBook',deployment['kuruEnvironment']['orderBookImplementation']),('kuruVaultImplementation','KuruAMMVault',deployment['kuruEnvironment']['vaultImplementation']),('kuruRouterImplementation','Router',deployment['kuruEnvironment']['proxyImplementations'][deployment['kuruEnvironment']['router']]),('kuruMarginImplementation','MarginAccount',deployment['kuruEnvironment']['proxyImplementations'][deployment['kuruEnvironment']['marginAccount']])]:
  info=artifact(name,kuru_contracts/'abi-out'/(name+'.sol')/(name+'.json'),{'kind':'QUALIFIED_KURU_SOURCE_COMPILE','url':'https://github.com/Kuru-Labs/Kuru-contracts-dex-public/blob/'+KURU_CONTRACT_SHA+'/contracts/'+name+'.sol','gitSHA':KURU_CONTRACT_SHA,'openzeppelinSHA':git(kuru_contracts/'lib/openzeppelin-contracts','rev-parse','HEAD'),'soladySHA':git(kuru_contracts/'lib/solady','rev-parse','HEAD'),'bytecodeMatch':'NOT_ESTABLISHED'});add(role,address,info)
 for role,name in [('market','OrderBook'),('vault','KuruAMMVault')]:
  manifest['templates'][role]={'abi':name+'.json','discovery':'GraduationCompleted + Coordinator.receipt','coverage':'FULL_ARTIFACT_ABI'}
 erc20paths=list((source/'contracts/out').glob('*/IERC20Metadata.json'))
 assert erc20paths
 doc=json.loads(erc20paths[0].read_text()); basic=json.loads(next((source/'contracts/out').glob('*/IERC20.json')).read_text())['abi']; interface=basic+[a for a in doc['abi'] if a not in basic]
 write(target/'ERC20MetadataInterface.json',interface)
 add('canonicalCircleUSDC','0x534b2f3A21130d7a60830c2Df862319e593943A3',{'contractName':'ERC20MetadataInterface','abi':'ERC20MetadataInterface.json','coverage':'QUALIFIED_INTERFACE_ONLY','origin':{'kind':'ERC20_INTERFACE','note':'Not the complete Circle proxy/implementation ABI'},'abiSHA256':hashlib.sha256((target/'ERC20MetadataInterface.json').read_bytes()).hexdigest(),'functions':sum(a['type']=='function' for a in interface),'events':sum(a['type']=='event' for a in interface),'errors':sum(a['type']=='error' for a in interface)})
 covered={c['address'].lower() for c in manifest['contracts']}
 for role,address in deployment['addresses'].items():
  if isinstance(address,str) and address.startswith('0x') and role!='owner': assert address.lower() in covered, f'Unmapped deployed contract: {role}'
 manifest['summary']={'contractAddresses':len(covered),'fullABIAddresses':len({c['address'].lower() for c in manifest['contracts'] if c['coverage']=='FULL_ARTIFACT_ABI'}),'abiFiles':len(files)+1,'functionsInUniqueFullABIs':sum(c['functions'] for c in files.values()),'eventsInUniqueFullABIs':sum(c['events'] for c in files.values())}
 write(target/'manifest.json',manifest)
 # Full const exports preserve viem's tuple inference, including overloaded methods.
 exports={'factoryAbi':'RetroPickLaunchFactoryV2','coordinatorAbi':'GraduationCoordinatorV2','curveAbi':'RetroPickBondingCurveV2','tokenAbi':'RetroPickLauncherTokenV2','registryAbi':'RetroPickQuoteAssetRegistryV2','lockAbi':'KuruLiquidityLockV2','kuruAbi':'OrderBook','marginAbi':'MarginAccount','routerAbi':'Router','kuruVaultAbi':'KuruAMMVault','kuruEnvironmentAbi':'KuruEnvironmentV2'}
 header='// GENERATED by scripts/launchpad/export_deployed_abis.py. Full ABI JSON lives in deployments/monad-testnet/abi/.\n// Exact deployed RetroPick source: '+SOURCE_SHA+'. Kuru SDK: '+KURU_SHA+'.\n'
 modules=ROOT/'packages/launchpad-sdk/src/abis'
 modules.mkdir(parents=True,exist_ok=True)
 for symbol,name in exports.items():
  (modules/(symbol+'.ts')).write_text(header+'export const '+symbol+' = '+json.dumps(json.loads((target/(name+'.json')).read_text()),separators=(',',':'))+' as const;\n')
 (ROOT/'packages/launchpad-sdk/src/abi.ts').write_text(header+'\n'.join("export { "+symbol+" } from './abis/"+symbol+".ts';" for symbol in exports)+'\n')
 print(json.dumps(manifest['summary']))

if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--deployed-worktree',required=True,type=Path)
 parser.add_argument('--kuru-sdk',required=True,type=Path)
 parser.add_argument('--kuru-contracts',required=True,type=Path)
 args=parser.parse_args();export(args.deployed_worktree.resolve(),args.kuru_sdk.resolve(),args.kuru_contracts.resolve())
