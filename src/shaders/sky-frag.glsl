#version 300 es

precision highp float;

uniform mat4 u_InvViewProj;
uniform vec3 u_Eye;
uniform vec4 u_Color;
uniform float u_Time;
uniform float u_TimeScale;
uniform int u_Octaves;

in vec4 fs_NDC;

out vec4 out_Col;

vec3 random3(vec3 p);
float quinticPoly1(float t);
vec3 quinticPoly3(vec3 t);
float fractalPerlinNoise(vec3 p);
float perlinNoise(vec3 pos);
float computeSurflet(vec3 P, vec3 gridPoint);

void main()
{
    // z = 1 is the far plane
    vec4 p = u_InvViewProj * vec4(fs_NDC.x, fs_NDC.y, 1.0, 1.0);
    vec3 worldPos = p.xyz / p.w;
    vec3 dir = normalize(worldPos - u_Eye);
    vec3 perlinFactor = vec3((fractalPerlinNoise(dir.xyz) + 1.0) * 0.5);
    perlinFactor = perlinFactor * perlinFactor * perlinFactor * perlinFactor;
    vec3 backgroundColor = vec3(1.0) - u_Color.rgb;
    out_Col = vec4(backgroundColor * perlinFactor, 1.0);
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
    float freq = 10.0;
    float amp = 1.0;

    float time = u_Time * u_TimeScale * 0.25;
    vec3 offset = vec3(-time, time, -time);

    for (int i = 1; i <= u_Octaves; i++)
    {
        float noiseStep = perlinNoise(p * freq + offset);
        total += noiseStep * amp;
        freq *= 2.0;
        amp *= persistence;
    }

    return total;
}