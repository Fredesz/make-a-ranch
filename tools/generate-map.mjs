import fs from 'node:fs';

// Edit-time geometry: regenerate with node tools/generate-map.mjs.
const rgb = (r, g, b) => [r / 255, g / 255, b / 255];
const grass = rgb(130, 174, 87), wood = rgb(155, 105, 61);
const part = (size, position, color, material = 'SmoothPlastic', extra = {}) => ({
  $className: 'Part', $properties: { Anchored: true, Size: size, Position: position,
    Color: color, Material: material, TopSurface: 'Smooth', BottomSurface: 'Smooth', ...extra },
});
const folder = () => ({ $className: 'Folder' });
const world = { $className: 'Workspace', $ignoreUnknownInstances: true };
const plots = world.RanchPlots = folder();
const scenery = world.RanchScenery = folder();
scenery.Meadow = part([352, 2, 272], [0, -0.9, 0], grass, 'Grass');
scenery.MainPath = part([280, 0.12, 12], [0, 0.16, 0], rgb(210, 185, 137), 'Sand');
scenery.Plaza = part([24, 0.16, 24], [0, 0.2, 0], rgb(219, 199, 160), 'Sand');
world.RanchSpawn = { $className: 'SpawnLocation', $properties: {
  Anchored: true, Size: [8, 1, 8], Position: [0, 0.65, 0], Neutral: true,
  Duration: 0, Transparency: 1, CanCollide: false,
} };
// Keep the original template spawn, but use only the new central spawn.
world.SpawnLocation = { $className: 'SpawnLocation', $properties: {
  Enabled: false, Transparency: 1, CanCollide: false,
}, Decal: { $className: 'Decal', $properties: { Transparency: 1 } } };

function sign(parent, x, z, index) {
  const model = parent.OwnerSign = { $className: 'Model' };
  for (const dx of [-4.5, 4.5]) model[`Post${dx}`] = part([0.7, 5, 0.7], [x + dx, 2.5, z], wood, 'Wood');
  const board = model.Board = part([13, 4, 0.6], [x, 5.2, z], rgb(188, 153, 70), 'Wood');
  for (const face of ['Front', 'Back']) board[face] = {
    $className: 'SurfaceGui', $properties: { Face: face, CanvasSize: [650, 200],
      AlwaysOnTop: false, LightInfluence: 0, MaxDistance: 130 },
    OwnerText: { $className: 'TextLabel', $properties: {
      Size: { UDim2: [[1, 0], [1, 0]] }, BackgroundTransparency: 1, Font: 'GothamBold',
      Text: `Parcela ${index}\nDisponible`, TextSize: 44, TextWrapped: true,
      TextColor3: rgb(41, 52, 48),
    } },
  };
}

for (let i = 1; i <= 8; i++) {
  const x = ((i - 1) % 4 - 1.5) * 64;
  const z = i <= 4 ? -58 : 58, front = i <= 4 ? 1 : -1;
  const plot = plots[`Plot_${i}`] = { $className: 'Model', $attributes: { PlotIndex: i } };
  plot.Ground = part([54, 1, 72], [x, 0, z], rgb(145, 185, 99), 'Grass');
  // Preserve existing local build coordinates and saved buildings near the center.
  plot.CropSlot = part([6, 0.5, 6], [x, 0.75, z], rgb(100, 65, 40), 'Ground');
  plot.SeedShop = part([3, 0.5, 3], [x - 7, 0.75, z], rgb(235, 190, 55));
  plot.SellPad = part([3, 0.5, 3], [x + 7, 0.75, z], rgb(65, 130, 190));
  const fence = plot.Fence = folder();
  let n = 0;
  function segment(ax, az, bx, bz) {
    const length = Math.hypot(bx - ax, bz - az), count = Math.ceil(length / 9);
    for (let j = 0; j <= count; j++) {
      const t = j / count;
      fence[`Post${n++}`] = part([0.65, 3.6, 0.65], [ax + (bx-ax)*t, 2.3, az+(bz-az)*t], wood, 'Wood');
    }
    for (const y of [1.65, 2.9]) fence[`Rail${n++}`] = part(
      ax === bx ? [0.35, 0.45, length] : [length, 0.45, 0.35],
      [(ax+bx)/2, y, (az+bz)/2], wood, 'Wood');
  }
  segment(x-28, z-37, x-28, z+37);
  segment(x+28, z-37, x+28, z+37);
  segment(x-28, z-front*37, x+28, z-front*37);
  segment(x-28, z+front*37, x-6, z+front*37);
  segment(x+6, z+front*37, x+28, z+front*37);
  sign(plot, x-17, z+front*38, i);
  scenery[`Entrance${i}`] = part([10, 0.15, 16], [x, 0.18, front === 1 ? -14 : 14], rgb(210, 185, 137), 'Sand');
}

// Four corner wedges form each faceted mountain, with a smaller snow summit.
const mountains = scenery.Mountains = folder();
function pyramid(parent, name, x, z, width, height, baseY, color) {
  const model = parent[name] = { $className: 'Model' };
  for (let k = 0; k < 4; k++) {
    const a = k * Math.PI / 2, c = Math.round(Math.cos(a)), s = Math.round(Math.sin(a));
    const dx = -width/4, dz = width/4;
    model[`Facet${k}`] = { $className: 'CornerWedgePart', $properties: {
      Anchored: true, Size: [width/2, height, width/2], Material: 'SmoothPlastic', Color: color,
      CFrame: [x+c*dx+s*dz, baseY+height/2, z-s*dx+c*dz, c,0,s, 0,1,0, -s,0,c],
    } };
  }
}
let mountainId = 0;
function mountain(x, z) {
  const i = mountainId++, h = 32 + (i * 7 % 19), w = 40 + (i % 3)*5;
  pyramid(mountains, `Mountain${i}`, x, z, w, h, -0.2,
    [rgb(70, 132, 112), rgb(88, 155, 123), rgb(103, 173, 132)][i % 3]);
  pyramid(mountains, `Snow${i}`, x, z, w * 0.25, h * 0.25, h * 0.75 - 0.15, rgb(222, 234, 237));
}
for (let x = -160; x <= 160; x += 32) { mountain(x, -119); mountain(x, 119); }
for (let z = -87; z <= 87; z += 29) { mountain(-160, z); mountain(160, z); }

fs.mkdirSync('src/world', { recursive: true });
fs.writeFileSync('src/world/default.project.json', JSON.stringify({name: 'RanchWorld', tree: world}, null, 2) + '\n');
console.log('Generated eight 54 x 72 plots and the shared ranch scenery.');
