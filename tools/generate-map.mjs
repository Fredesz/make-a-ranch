import fs from 'node:fs';

// Edit-time geometry: regenerate with node tools/generate-map.mjs.
const rgb = (r, g, b) => [r / 255, g / 255, b / 255];
const grass = rgb(151, 231, 42), grassAccent = rgb(137, 218, 37);
const orange = rgb(204, 116, 31), charcoal = rgb(26, 42, 65), white = rgb(239, 244, 246);
const part = (size, position, color, material = 'SmoothPlastic', extra = {}) => ({
  $className: 'Part', $properties: { Anchored: true, Size: size, Position: position,
    Color: color, Material: material, TopSurface: 'Smooth', BottomSurface: 'Smooth', ...extra },
});
const folder = () => ({ $className: 'Folder' });
function checker(parent, name, width, depth, x, z, y, tileSize) {
  const tiles = parent[name] = folder();
  const cols = Math.ceil(width / tileSize), rows = Math.ceil(depth / tileSize);
  const tileWidth = width / cols, tileDepth = depth / rows;
  for (let col = 0; col < cols; col++) for (let row = 0; row < rows; row++) {
    if ((col + row) % 2 === 0) continue;
    tiles[`Tile_${col}_${row}`] = part(
      [tileWidth, 0.04, tileDepth],
      [x - width/2 + (col + 0.5)*tileWidth, y, z - depth/2 + (row + 0.5)*tileDepth],
      grassAccent, 'Plastic',
      {TopSurface: 'Studs', CanCollide: false, CanTouch: false, CanQuery: false, CastShadow: false},
    );
  }
}
const world = { $className: 'Workspace', $ignoreUnknownInstances: true };
const plots = world.RanchPlots = folder();
plots.$ignoreUnknownInstances = false;
const scenery = world.RanchScenery = folder();
scenery.$ignoreUnknownInstances = false;
scenery.Meadow = part([420, 2, 320], [0, -0.9, 0], grass, 'Plastic', { TopSurface: 'Studs' });
checker(scenery, 'MeadowPattern', 420, 320, 0, 0, 0.12, 16);
scenery.MainPath = part([280, 0.12, 12], [0, 0.16, 0], rgb(225, 180, 114), 'Plastic', { TopSurface: 'Studs' });
scenery.Plaza = part([24, 0.16, 24], [0, 0.2, 0], rgb(235, 199, 146), 'Plastic', { TopSurface: 'Studs' });
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
  // Supports stop at the board's underside so they never cross the lettering.
  for (const dx of [-4.5, 4.5]) model[`Post${dx}`] = part([0.9, 3.2, 0.9], [x + dx, 1.6, z], charcoal, 'Plastic', { TopSurface: 'Studs' });
  const board = model.Board = part([13, 4, 0.8], [x, 5.2, z], orange, 'Plastic', { TopSurface: 'Studs' });
  for (const face of ['Front', 'Back']) board[face] = {
    $className: 'SurfaceGui', $properties: { Face: face, CanvasSize: [650, 200],
      AlwaysOnTop: false, LightInfluence: 0, MaxDistance: 130 },
    OwnerText: { $className: 'TextLabel', $properties: {
      Size: { UDim2: [[1, 0], [1, 0]] }, BackgroundTransparency: 1, Font: 'GothamBold',
      Text: `Parcela ${index}\nDisponible`, TextSize: 44, TextWrapped: true,
      TextColor3: rgb(38, 36, 45),
    } },
  };
}

for (let i = 1; i <= 8; i++) {
  const x = ((i - 1) % 4 - 1.5) * 64;
  const z = i <= 4 ? -58 : 58, front = i <= 4 ? 1 : -1;
  const plot = plots[`Plot_${i}`] = { $className: 'Model', $ignoreUnknownInstances: false, $attributes: { PlotIndex: i } };
  plot.Ground = part([54, 1, 72], [x, 0, z], grass, 'Plastic', { TopSurface: 'Studs' });
  checker(plot, 'GroundPattern', 54, 72, x, z, 0.52, 9);
  // Preserve existing local build coordinates and saved buildings near the center.
  plot.CropSlot = part([6, 0.5, 6], [x, 0.75, z], rgb(116, 72, 40), 'Plastic', { TopSurface: 'Studs' });
  plot.SeedShop = part([3, 0.5, 3], [x - 7, 0.75, z], rgb(235, 190, 55), 'Plastic', { TopSurface: 'Studs' });
  plot.SellPad = part([3, 0.5, 3], [x + 7, 0.75, z], rgb(65, 130, 190), 'Plastic', { TopSurface: 'Studs' });
  const fence = plot.Fence = folder();
  fence.$ignoreUnknownInstances = false;
  let n = 0;
  function segment(ax, az, bx, bz) {
    const length = Math.hypot(bx - ax, bz - az), count = Math.ceil(length / 9);
    for (let j = 0; j <= count; j++) {
      const t = j / count;
      fence[`Post${n++}`] = part([0.9, 3.6, 0.9], [ax + (bx-ax)*t, 2.3, az+(bz-az)*t], charcoal, 'Plastic', { TopSurface: 'Studs' });
    }
    for (const y of [1.65, 2.9]) fence[`Rail${n++}`] = part(
      ax === bx ? [0.35, 0.45, length] : [length, 0.45, 0.35],
      [(ax+bx)/2, y, (az+bz)/2], white, 'Plastic', { TopSurface: 'Studs' });
    for (let j = 0; j < count; j++) {
      const start = j / count, end = (j + 1) / count;
      const x1 = ax + (bx-ax)*start, z1 = az + (bz-az)*start;
      const x2 = ax + (bx-ax)*end, z2 = az + (bz-az)*end;
      const dx = x2-x1, dz = z2-z1, horizontalLength = Math.hypot(dx,dz);
      const hx = dx/horizontalLength, hz = dz/horizontalLength;
      for (const rise of [1.3, -1.3]) {
        const beamLength = Math.hypot(horizontalLength,rise);
        const bxUnit = dx/beamLength, byUnit = rise/beamLength, bzUnit = dz/beamLength;
        const sideX = hz, sideZ = -hx;
        const upX = -byUnit*hx, upY = horizontalLength/beamLength, upZ = -byUnit*hz;
        fence[`Brace${n++}`] = { $className: 'Part', $properties: {
          Anchored: true, Size: [0.4, 0.5, beamLength], Color: white,
          Material: 'Plastic', TopSurface: 'Studs', BottomSurface: 'Smooth',
          CFrame: [(x1+x2)/2, 2.25, (z1+z2)/2,
            sideX, upX, bxUnit, 0, upY, byUnit, sideZ, upZ, bzUnit],
        } };
      }
    }
  }
  segment(x-28, z-37, x-28, z+37);
  segment(x+28, z-37, x+28, z+37);
  segment(x-28, z-front*37, x+28, z-front*37);
  segment(x-28, z+front*37, x-6, z+front*37);
  segment(x+6, z+front*37, x+28, z+front*37);
  sign(plot, x-17, z+front*38, i);
  scenery[`Entrance${i}`] = part([10, 0.15, 16], [x, 0.18, front === 1 ? -14 : 14], rgb(225, 180, 114), 'Plastic', { TopSurface: 'Studs' });
}

// Block-built perimeter, outside the plots with at least 25 studs of clearance.
const walls = scenery.PerimeterWalls = folder();
walls.$ignoreUnknownInstances = false;
let wallId = 0;
function wallPanel(x, z, length, alongX) {
  const name = `Panel${wallId++}`;
  const model = walls[name] = { $className: 'Model', $ignoreUnknownInstances: false };
  const capSize = alongX ? [length, 1, 10] : [10, 1, length];
  // Alternating full-depth blocks keep the checker visible from inside and outside.
  for (let col = 0; col < 4; col++) for (let row = 0; row < 4; row++) {
    const offset = (col - 1.5) * length/4;
    const position = alongX ? [x + offset, (row + 0.5)*8.5, z] : [x, (row + 0.5)*8.5, z + offset];
    const size = alongX ? [length/4, 8.5, 8] : [8, 8.5, length/4];
    const tone = (col + row) % 2 === 0 ? rgb(221, 159, 94) : rgb(196, 135, 76);
    model[`Block_${col}_${row}`] = part(size, position, tone, 'Plastic', {
      FrontSurface: 'Studs', BackSurface: 'Studs', LeftSurface: 'Studs', RightSurface: 'Studs',
    });
  }
  model.GrassCap = part(capSize, [x, 34.5, z], rgb(91, 206, 38), 'Plastic', { TopSurface: 'Studs' });
}
for (let x = -192; x <= 192; x += 32) { wallPanel(x, -148, 32, true); wallPanel(x, 148, 32, true); }
for (let z = -132; z <= 132; z += 33) { wallPanel(-208, z, 33, false); wallPanel(208, z, 33, false); }

fs.mkdirSync('src/world', { recursive: true });
fs.writeFileSync('src/world/default.project.json', JSON.stringify({name: 'RanchWorld', tree: world}, null, 2) + '\n');
console.log('Generated eight LEGO-style plots, fences, paths and perimeter walls.');
