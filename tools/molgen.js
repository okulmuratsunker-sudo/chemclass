// Reusable geometry helpers for skeletal/ring molecule SVG diagrams.
// Vertex/bond coordinates are computed (not eyeballed) so rings stay regular
// and substituent bonds/labels always point straight out from the ring.
'use strict';

function deg2rad(d) { return (d * Math.PI) / 180; }
function round(n) { return Math.round(n * 100) / 100; }

// Regular n-gon vertices, vertex 0 at top (angle 0), clockwise.
// Returns [{x,y,angle}, ...]
function ringVertices(n, cx, cy, r, startDeg = 0) {
  const pts = [];
  for (let i = 0; i < n; i++) {
    const angle = startDeg + (i * 360) / n;
    const a = deg2rad(angle);
    pts.push({ x: round(cx + r * Math.sin(a)), y: round(cy - r * Math.cos(a)), angle });
  }
  return pts;
}

function ringPolygonPoints(verts) {
  return verts.map((v) => `${v.x},${v.y}`).join(' ');
}

// A short zigzag chain starting at `from` (point or {x,y}), trending in
// direction dirDeg, alternating ±halfAngle around that direction.
// Returns array of points INCLUDING the start point (length n+1).
function chain(from, dirDeg, n, bondLen, halfAngle = 28) {
  const pts = [{ x: from.x, y: from.y }];
  let cur = pts[0];
  for (let i = 0; i < n; i++) {
    const angle = dirDeg + (i % 2 === 0 ? -halfAngle : halfAngle);
    const a = deg2rad(angle);
    const nxt = { x: round(cur.x + bondLen * Math.sin(a)), y: round(cur.y - bondLen * Math.cos(a)) };
    pts.push(nxt);
    cur = nxt;
  }
  return pts;
}

// Two endpoints forking out from `point`, symmetric around dirDeg.
function fork(point, dirDeg, spreadDeg, bondLen) {
  const a1 = dirDeg - spreadDeg / 2;
  const a2 = dirDeg + spreadDeg / 2;
  const mk = (deg) => {
    const a = deg2rad(deg);
    return { x: round(point.x + bondLen * Math.sin(a)), y: round(point.y - bondLen * Math.cos(a)) };
  };
  return [mk(a1), mk(a2)];
}

// Single bond endpoint straight out from `point` at angle dirDeg.
function bondEnd(point, dirDeg, bondLen) {
  const a = deg2rad(dirDeg);
  return { x: round(point.x + bondLen * Math.sin(a)), y: round(point.y - bondLen * Math.cos(a)) };
}

// Text-anchor / dx / dy hints for a label sitting at the end of a bond
// that points outward at angle dirDeg (0 = up, 90 = right, ...).
function labelAnchor(dirDeg) {
  const a = ((dirDeg % 360) + 360) % 360;
  if (a < 22.5 || a >= 337.5) return { anchor: 'middle', dx: 0, dy: -5 };
  if (a < 67.5) return { anchor: 'start', dx: 2, dy: -1 };
  if (a < 112.5) return { anchor: 'start', dx: 3, dy: 4 };
  if (a < 157.5) return { anchor: 'start', dx: 2, dy: 9 };
  if (a < 202.5) return { anchor: 'middle', dx: 0, dy: 11 };
  if (a < 247.5) return { anchor: 'end', dx: -2, dy: 9 };
  if (a < 292.5) return { anchor: 'end', dx: -3, dy: 4 };
  return { anchor: 'end', dx: -2, dy: -1 };
}

// Bounding box (with padding) over a list of {x,y} points -> viewBox string.
function viewBoxFor(points, pad = 14) {
  const xs = points.map((p) => p.x);
  const ys = points.map((p) => p.y);
  const minX = Math.min(...xs) - pad;
  const minY = Math.min(...ys) - pad;
  const w = Math.max(...xs) - Math.min(...xs) + pad * 2;
  const h = Math.max(...ys) - Math.min(...ys) + pad * 2;
  return `${round(minX)} ${round(minY)} ${round(w)} ${round(h)}`;
}

module.exports = { ringVertices, ringPolygonPoints, chain, fork, bondEnd, labelAnchor, viewBoxFor, deg2rad, round };
