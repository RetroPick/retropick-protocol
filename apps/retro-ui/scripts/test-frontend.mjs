import {spawnSync} from 'node:child_process';
import {mkdirSync,rmSync,writeFileSync} from 'node:fs';
const sources=['src/lib/domain/math.ts','src/lib/domain/types.ts','src/lib/domain/fixtures.ts','src/lib/domain/launchpad-types.ts','src/lib/domain/launchpad-fixtures.ts','src/lib/domain/prism-fixtures.ts','src/lib/domain/instruments.ts','src/lib/domain/contract-registry.ts','src/lib/domain/launchpad-adapters.ts','src/lib/domain/launchpad-repository.ts'];
const compile=spawnSync(process.execPath,['node_modules/typescript/bin/tsc',...sources,'--target','es2022','--module','commonjs','--outDir','.test-output','--skipLibCheck'],{stdio:'inherit'});if(compile.status!==0)process.exit(compile.status??1);
mkdirSync('.test-output',{recursive:true});writeFileSync('.test-output/package.json','{"type":"commonjs"}');
const run=spawnSync(process.execPath,['--test','tests/domain.test.mjs','tests/launchpad-taxonomy.test.mjs'],{stdio:'inherit'});rmSync('.test-output',{recursive:true,force:true});process.exit(run.status??1);
