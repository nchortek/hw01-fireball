#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

vec3 random3(vec3 p);
float quinticPoly1(float t);
vec3 quinticPoly3(vec3 t);
float fractalPerlinNoise(vec3 p);
float perlinNoise(vec3 pos);
float computeSurflet(vec3 P, vec3 gridPoint);

void main()
{
    // Material base color (before shading)
    float zeroToOnePerlin = (fractalPerlinNoise(fs_Pos.xyz) + 1.0) / 2.0;
    vec4 diffuseColor = vec4(mix(u_Color.rgb, vec3(1, 0.5, 1), zeroToOnePerlin), u_Color.a);

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    // diffuseTerm = clamp(diffuseTerm, 0, 1);

    float ambientTerm = 0.2;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.

    // Compute final shaded color
    out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}

vec3 random3(vec3 p)
{
    return fract(
        sin(vec3(dot(p, vec3(127.1, 311.7, 233.9)), dot(p, vec3(269.5, 183.3, 379.7)), dot(p, vec3(519.7, 47.1, 173.5))))
        * 43758.5453);
}

float quinticPoly1(float t)
{
    float t3 = t * t * t;
    float t4 = t3 * t;
    float t5 = t4 * t;

    return 1.0 - 6.0 * t5 + 15.0 * t4 - 10.0 * t3;
}

vec3 quinticPoly3(vec3 t)
{
    return vec3(quinticPoly1(t.x), quinticPoly1(t.y), quinticPoly1(t.z));
}

float computeSurflet(vec3 P, vec3 gridPoint)
{
    // Compute falloff function by converting linear distance to a polynomial
    vec3 dist = abs(P - gridPoint);
    vec3 t = quinticPoly3(dist);

    // Get the random vector for the grid point
    vec3 gradient = 2.0 * random3(gridPoint) - vec3(1.0);

    // Get the vector from the grid point to P
    vec3 diff = P - gridPoint;

    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);

    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * t.x * t.y * t.z;
}

float perlinNoise(vec3 pos)
{
    float surfletSum = 0.0;

    // Iterate over the eight integer corners surrounding pos
    for (int dx = 0; dx <= 1; dx++)
    {
        for (int dy = 0; dy <= 1; dy++)
        {
            for (int dz = 0; dz <= 1; dz++)
            {
                surfletSum += computeSurflet(pos, floor(pos) + vec3(dx, dy, dz));
            }
        }
    }

    return surfletSum;
}

float fractalPerlinNoise(vec3 p)
{
    float total = 0.0;
    float persistence = 0.5;
    int octaves = 4;
    float freq = 2.0;
    float amp = 10.0;

    for (int i = 1; i <= octaves; i++)
    {
        float noiseStep = perlinNoise(p * freq);
        total += noiseStep * amp;
        freq *= 2.0;
        amp *= persistence;
    }

    return total;
}