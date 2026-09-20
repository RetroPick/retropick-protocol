import {spawnSync} from 'node:child_process';
import {rmSync} from 'node:fs';
const compile=spawnSync(process.execPath,['node_modules/typescript/bin/tsc','lib/domain/math.ts','--target','es2022','--module','es2022','--outDir','.test-output','--skipLibCheck'],{stdio:'inherit'});if(compile.status!==0)process.exit(compile.status??1);
const run=spawnSync(process.execPath,['--test','tests/domain.test.mjs'],{stdio:'inherit'});rmSync('.test-output',{recursive:true,force:true});process.exit(run.status??1);
