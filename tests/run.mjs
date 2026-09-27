import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

// Run the real module sources with a small Roblox test double, not in Studio.
const files = [
  ['PlotConfig', 'src/shared/Config/PlotConfig.luau'],
  ['PlayerDataService', 'src/server/PlayerDataService.luau'],
  ['PlotService', 'src/server/Services/PlotService.luau'],
  ['CropConfig', 'src/shared/Config/CropConfig.luau'],
  ['VariantConfig', 'src/shared/Config/VariantConfig.luau'],
  ['VariantRng', 'src/server/Services/VariantRng.luau'],
  ['InventoryService', 'src/server/Services/InventoryService.luau'],
  ['SellService', 'src/server/Services/SellService.luau'],
  ['CropService', 'src/server/Services/CropService.luau'],
];
let source = fs.readFileSync('tests/roblox-mock.luau', 'utf8');
for (const [name, file] of files) {
  const body = fs.readFileSync(file, 'utf8').replace(/^local .* = require\(.*\)\r?\n/gm, '');
  source += `\nlocal ${name} = (function()\n${body}\nend)()\n`;
}
source += fs.readFileSync('tests/session.spec.luau', 'utf8');
source += fs.readFileSync('tests/crop.spec.luau', 'utf8');
fs.mkdirSync('.cache/tests', { recursive: true });
const bundle = '.cache/tests/session.luau';
fs.writeFileSync(bundle, source);
const executable = process.env.LUAU_BIN || path.resolve('.cache/luau/luau.exe');
const result = spawnSync(executable, [bundle], { stdio: 'inherit' });
if (result.error) console.error(result.error.message);
process.exit(result.status ?? 1);
