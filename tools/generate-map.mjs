import fs from 'node:fs';

// Edit-time geometry: regenerate with node tools/generate-map.mjs.
const rgb = (r, g, b) => [r / 255, g / 255, b / 255];
const grass = rgb(145, 225, 47), orange = rgb(204, 116, 31), charcoal = rgb(63, 57, 68);
const part = (size, position, color, material = 'SmoothPlastic', extra = {}) => ({
  $className: 'Part', $properties: { Anchored: true, Size: size, Position: position,
    Color: color, Material: material, TopSurface: 'Smooth', BottomSurface: 'Smooth', ...extra },
});
const folder = () => ({ $className: 'Folder' });
const world = { $className: 'Workspace', $ignoreUnknownInstances: true };
const plots = world.RanchPlots = folder();
const scenery = world.RanchScenery = folder();
scenery.$ignoreUnknownInstances = false;
scenery.Meadow = part([420, 2, 320], [0, -0.9, 0], grass, 'Plastic', { TopSurface: 'Studs' });
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
  for (const dx of [-4.5, 4.5]) model[`Post${dx}`] = part([0.9, 5, 0.9], [x + dx, 2.5, z], charcoal, 'Plastic', { TopSurface: 'Studs' });
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
  const plot = plots[`Plot_${i}`] = { $className: 'Model', $attributes: { PlotIndex: i } };
  plot.Ground = part([54, 1, 72], [x, 0, z], grass, 'Plastic', { TopSurface: 'Studs' });
  // Preserve existing local build coordinates and saved buildings near the center.
  plot.CropSlot = part([6, 0.5, 6], [x, 0.75, z], rgb(116, 72, 40), 'Plastic', { TopSurface: 'Studs' });
  plot.SeedShop = part([3, 0.5, 3], [x - 7, 0.75, z], rgb(235, 190, 55), 'Plastic', { TopSurface: 'Studs' });
  plot.SellPad = part([3, 0.5, 3], [x + 7, 0.75, z], rgb(65, 130, 190), 'Plastic', { TopSurface: 'Studs' });
  const fence = plot.Fence = folder();
  let n = 0;
  function segment(ax, az, bx, bz) {
    const length = Math.hypot(bx - ax, bz - az), count = Math.ceil(length / 9);
    for (let j = 0; j <= count; j++) {
      const t = j / count;
      fence[`Post${n++}`] = part([0.9, 3.6, 0.9], [ax + (bx-ax)*t, 2.3, az+(bz-az)*t], charcoal, 'Plastic', { TopSurface: 'Studs' });
    }
    for (const y of [1.65, 2.9]) fence[`Rail${n++}`] = part(
      ax === bx ? [0.35, 0.45, length] : [length, 0.45, 0.35],
      [(ax+bx)/2, y, (az+bz)/2], orange, 'Plastic', { TopSurface: 'Studs' });
    for (let j = 0; j < count; j++) {
      const start = j / count, end = (j + 1) / count;
      const x1 = ax + (bx-ax)*start, z1 = az + (bz-az)*start;
      const x2 = ax + (bx-ax)*end, z2 = az + (bz-az)*end;
      const dx = x2-x1, dy = 1.3, dz = z2-z1, beamLength = Math.hypot(dx,dy,dz);
      const bxUnit = dx/beamLength, byUnit = dy/beamLength, bzUnit = dz/beamLength;
      const horizontalLength = Math.hypot(dx,dz), hx = dx/horizontalLength, hz = dz/horizontalLength;
      const sideX = hz, sideZ = -hx;
      const upX = -byUnit*hx, upY = horizontalLength/beamLength, upZ = -byUnit*hz;
      fence[`Brace${n++}`] = { $className: 'Part', $properties: {
        Anchored: true, Size: [0.28, 0.42, beamLength], Color: orange,
        Material: 'Plastic', TopSurface: 'Studs', BottomSurface: 'Smooth',
        CFrame: [(x1+x2)/2, 2.25, (z1+z2)/2,
          sideX, upX, bxUnit, 0, upY, byUnit, sideZ, upZ, bzUnit],
      } };
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
let wallId = 0;
function wallPanel(x, z, length, alongX) {
  const name = `Panel${wallId++}`;
  const model = walls[name] = { $className: 'Model' };
  const size = alongX ? [length, 34, 8] : [8, 34, length];
  const capSize = alongX ? [length, 1, 10] : [10, 1, length];
  const tone = wallId % 2 === 0 ? rgb(204, 150, 100) : rgb(212, 158, 107);
  model.Wall = part(size, [x, 17, z], tone, 'Plastic', { TopSurface: 'Studs' });
  model.GrassCap = part(capSize, [x, 34.5, z], rgb(91, 206, 38), 'Plastic', { TopSurface: 'Studs' });
}
for (let x = -192; x <= 192; x += 32) { wallPanel(x, -148, 32, true); wallPanel(x, 148, 32, true); }
for (let z = -132; z <= 132; z += 33) { wallPanel(-208, z, 33, false); wallPanel(208, z, 33, false); }

fs.mkdirSync('src/world', { recursive: true });
fs.writeFileSync('src/world/default.project.json', JSON.stringify({name: 'RanchWorld', tree: world}, null, 2) + '\n');
console.log('Generated eight LEGO-style plots, fences, paths and perimeter walls.');
