import {execFileSync} from 'node:child_process';
import {existsSync,mkdirSync,readFileSync,realpathSync,renameSync,symlinkSync} from 'node:fs';
import {dirname,join,resolve} from 'node:path';
// Linked development plugins must share the host SDK instance. The CLI's
// built-in peer linker handles user installs, but skips linked plugins in 6.2.1.
const cliPath=process.argv[2]??execFileSync('which',['mm'],{encoding:'utf8'}).trim();
let hostRoot=dirname(realpathSync(cliPath));
while(true){
  const file=join(hostRoot,'package.json');
  if(existsSync(file)){
    const pkg=JSON.parse(readFileSync(file,'utf8'));
    if(pkg.name==='@metamask/agent-wallet'){
      if(pkg.version!=='6.2.1')throw new Error(`This distribution is verified with host 6.2.1, observed ${pkg.version}`);
      break;
    }
  }
  const parent=dirname(hostRoot);
  if(parent===hostRoot)throw new Error('Installed MetaMask CLI package root not found');
  hostRoot=parent;
}
const target=resolve('node_modules/@metamask/agent-wallet');
if(existsSync(target)&&realpathSync(target)===hostRoot){console.log(`Host SDK peer already shared: ${hostRoot}`);process.exit(0);}
if(existsSync(target))renameSync(target,`${target}-peer-backup-${Date.now()}`);
mkdirSync(dirname(target),{recursive:true});
symlinkSync(hostRoot,target,'dir');
console.log(`Linked development SDK peer to installed host: ${hostRoot}`);
