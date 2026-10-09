"""Offline ABI export integrity gates (no RPC or signing)."""
import hashlib
import json
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
DIR=ROOT/'deployments/monad-testnet/abi'
class AbiExportTest(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.manifest=json.loads((DIR/'manifest.json').read_text())
 def test_every_deployed_contract_has_an_abi(self):
  release=json.loads((ROOT/'deployments/monad-testnet/v2.json').read_text())
  covered={c['address'].lower() for c in self.manifest['contracts']}
  for role,address in release['addresses'].items():
   if role!='owner' and isinstance(address,str) and address.startswith('0x'):self.assertIn(address.lower(),covered,role)
  self.assertNotIn(release['addresses']['owner'].lower(),covered)
 def test_integrity_and_counts(self):
  for c in self.manifest['contracts']:
   path=DIR/c['abi'];data=path.read_bytes();abi=json.loads(data)
   self.assertEqual(hashlib.sha256(data).hexdigest(),c['abiSHA256'],c['abi'])
   for kind in ['function','event','error']:self.assertEqual(sum(a['type']==kind for a in abi),c[kind+'s'],c['abi'])
 def test_per_launch_templates(self):
  for name in ['token','curve','lpLock','market','vault']:
   template=self.manifest['templates'][name]
   self.assertTrue((DIR/template['abi']).is_file())
   self.assertEqual(template['coverage'],'FULL_ARTIFACT_ABI')
 def test_no_false_circle_completeness(self):
  c=next(c for c in self.manifest['contracts'] if c['role']=='canonicalCircleUSDC')
  self.assertEqual(c['address'].lower(),'0x534b2f3a21130d7a60830c2df862319e593943a3')
  self.assertEqual(c['coverage'],'QUALIFIED_INTERFACE_ONLY')
 def test_overloads_and_dynamic_indexer_events(self):
  factory=json.loads((DIR/'RetroPickLaunchFactoryV2.json').read_text())
  self.assertGreaterEqual(sum(a.get('name')=='launchToken' for a in factory),3)
  for name,event in [('RetroPickLauncherTokenV2','Transfer'),('RetroPickBondingCurveV2','CurveBuy'),('GraduationCoordinatorV2','GraduationCompleted'),('OrderBook','Trade')]:
   self.assertTrue(any(a['type']=='event' and a['name']==event for a in json.loads((DIR/(name+'.json')).read_text())))
 def test_catalog_is_complete(self):
  catalog=json.loads((DIR/'function-event-map.json').read_text())
  self.assertEqual(set(c['abi'] for c in catalog['contracts']),set(c['abi'] for c in self.manifest['contracts']))
  for c in catalog['contracts']:
   abi=json.loads((DIR/c['abi']).read_text())
   self.assertEqual(len(c['functions']),sum(a['type']=='function' for a in abi))
   self.assertEqual(len(c['events']),sum(a['type']=='event' for a in abi))
   self.assertTrue(all(len(f['selector'])==10 for f in c['functions']))
if __name__=='__main__':unittest.main()
