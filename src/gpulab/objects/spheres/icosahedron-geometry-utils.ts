// Add this to your sphere-utils.ts or create a new icosahedron-utils.ts

interface IcosahedronBuffers {
  sphereVertexBuffer: GPUBuffer;
  sphereIndexBuffer: GPUBuffer;
  sphereWireframeIndexBuffer: GPUBuffer;
  indexCount: number;
  wireframeIndexCount: number;
}

// Generate icosahedron geometry with subdivision support
function generateIcosahedron(radius: number = 1, subdivisions: number = 2) {
  // Golden ratio
  const t = (1.0 + Math.sqrt(5.0)) / 2.0;

  // Create 12 vertices of a icosahedron
  let vertices: number[] = [];
  let indices: number[] = [];

  // Initial vertices (normalized)
  const positions = [
    [-1, t, 0],
    [1, t, 0],
    [-1, -t, 0],
    [1, -t, 0],
    [0, -1, t],
    [0, 1, t],
    [0, -1, -t],
    [0, 1, -t],
    [t, 0, -1],
    [t, 0, 1],
    [-t, 0, -1],
    [-t, 0, 1],
  ];

  // Add initial vertices
  positions.forEach((pos) => {
    // Normalize
    const length = Math.sqrt(
      pos[0] * pos[0] + pos[1] * pos[1] + pos[2] * pos[2]
    );
    const nx = pos[0] / length;
    const ny = pos[1] / length;
    const nz = pos[2] / length;

    // Position = normal * radius for a perfect sphere
    vertices.push(
      nx * radius,
      ny * radius,
      nz * radius, // position
      nx,
      ny,
      nz // normal
    );
  });

  // Create 20 triangular faces
  let triangles = [
    // 5 faces around point 0
    [0, 11, 5],
    [0, 5, 1],
    [0, 1, 7],
    [0, 7, 10],
    [0, 10, 11],
    // 5 adjacent faces
    [1, 5, 9],
    [5, 11, 4],
    [11, 10, 2],
    [10, 7, 6],
    [7, 1, 8],
    // 5 faces around point 3
    [3, 9, 4],
    [3, 4, 2],
    [3, 2, 6],
    [3, 6, 8],
    [3, 8, 9],
    // 5 adjacent faces
    [4, 9, 5],
    [2, 4, 11],
    [6, 2, 10],
    [8, 6, 7],
    [9, 8, 1],
  ];

  // Apply subdivisions
  for (let i = 0; i < subdivisions; i++) {
    const newTriangles: number[][] = [];
    const midPointCache = new Map<string, number>();

    function getMidPoint(i1: number, i2: number): number {
      const key = i1 < i2 ? `${i1}-${i2}` : `${i2}-${i1}`;

      if (midPointCache.has(key)) {
        return midPointCache.get(key)!;
      }

      // Get vertices (6 floats each: pos + normal)
      const v1 = [vertices[i1 * 6], vertices[i1 * 6 + 1], vertices[i1 * 6 + 2]];
      const v2 = [vertices[i2 * 6], vertices[i2 * 6 + 1], vertices[i2 * 6 + 2]];

      // Calculate midpoint
      const mid = [
        (v1[0] + v2[0]) / 2,
        (v1[1] + v2[1]) / 2,
        (v1[2] + v2[2]) / 2,
      ];

      // Normalize to sphere surface
      const length = Math.sqrt(
        mid[0] * mid[0] + mid[1] * mid[1] + mid[2] * mid[2]
      );
      const nx = mid[0] / length;
      const ny = mid[1] / length;
      const nz = mid[2] / length;

      // Add vertex
      const newIndex = vertices.length / 6;
      vertices.push(
        nx * radius,
        ny * radius,
        nz * radius, // position
        nx,
        ny,
        nz // normal
      );

      midPointCache.set(key, newIndex);
      return newIndex;
    }

    // Subdivide each triangle into 4 triangles
    triangles.forEach((tri) => {
      const v1 = tri[0];
      const v2 = tri[1];
      const v3 = tri[2];

      const a = getMidPoint(v1, v2);
      const b = getMidPoint(v2, v3);
      const c = getMidPoint(v3, v1);

      newTriangles.push([v1, a, c]);
      newTriangles.push([v2, b, a]);
      newTriangles.push([v3, c, b]);
      newTriangles.push([a, b, c]);
    });

    triangles = newTriangles;
  }

  // Convert triangles to indices
  const wireframeIndices: number[] = [];
  triangles.forEach((tri) => {
    const a = tri[0];
    const b = tri[1];
    const c = tri[2];

    indices.push(a, b, c);
    wireframeIndices.push(a, b, b, c, c, a);
  });

  return {
    vertices: new Float32Array(vertices),
    indices: new Uint16Array(indices),
    wireframeIndices: new Uint16Array(wireframeIndices),
  };
}

export function createIcosahedronGeometry(
  device: GPUDevice,
  radius: number = 1,
  subdivisions: number = 2
): IcosahedronBuffers {
  const { vertices, indices, wireframeIndices } = generateIcosahedron(
    radius,
    subdivisions
  );

  const vertexBuffer = device.createBuffer({
    label: "Icosahedron Vertices",
    size: vertices.byteLength,
    usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
  });

  const indexBuffer = device.createBuffer({
    label: "Icosahedron Indices",
    size: indices.byteLength,
    usage: GPUBufferUsage.INDEX | GPUBufferUsage.COPY_DST,
  });

  const wireframeIndexBuffer = device.createBuffer({
    label: "Icosahedron Wireframe Indices",
    size: wireframeIndices.byteLength,
    usage: GPUBufferUsage.INDEX | GPUBufferUsage.COPY_DST,
  });

  device.queue.writeBuffer(vertexBuffer, 0, vertices);
  device.queue.writeBuffer(indexBuffer, 0, indices);
  device.queue.writeBuffer(wireframeIndexBuffer, 0, wireframeIndices);

  return {
    sphereVertexBuffer: vertexBuffer,
    sphereIndexBuffer: indexBuffer,
    sphereWireframeIndexBuffer: wireframeIndexBuffer,
    indexCount: indices.length,
    wireframeIndexCount: wireframeIndices.length,
  };
}
