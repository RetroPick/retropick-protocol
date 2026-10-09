import {spawnSync} from 'node:child_process';
import {mkdirSync,rmSync,writeFileSync} from 'node:fs';
const sources=['lib/live/math.ts','lib/live/book.ts','lib/domain/math.ts','lib/domain/types.ts','lib/domain/fixtures.ts','lib/domain/launchpad-types.ts','lib/domain/launchpad-fixtures.ts','lib/domain/prism-fixtures.ts','lib/domain/instruments.ts','lib/domain/contract-registry.ts','lib/domain/launchpad-adapters.ts','lib/domain/launchpad-repository.ts'];
const compile=spawnSync(process.execPath,['node_modules/typescript/bin/tsc',...sources,'--target','es2022','--module','commonjs','--outDir','.test-output','--skipLibCheck'],{stdio:'inherit'});if(compile.status!==0)process.exit(compile.status??1);
mkdirSync('.test-output',{recursive:true});writeFileSync('.test-output/package.json','{"type":"commonjs"}');
const run=spawnSync(process.execPath,['--test','tests/live-math.test.mjs','tests/domain.test.mjs','tests/launchpad-taxonomy.test.mjs'],{stdio:'inherit'});rmSync('.test-output',{recursive:true,force:true});process.exit(run.status??1);
