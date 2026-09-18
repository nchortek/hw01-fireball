#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.
precision highp float;

uniform float u_Time;

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(500, 500, 300, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

const vec3 tailDir = vec3(1.0, 0.0, 0.0);
const vec3 zAxis = vec3(0.0, 0.0, 1.0);
const vec3 yAxis = vec3(0.0, 1.0, 0.0);

const float epsilon = 0.0001;

vec3 random3(vec3 p);
float quinticPoly1(float t);
vec3 quinticPoly3(vec3 t);
float perlinNoise(vec3 p);
float computeSurflet(vec3 P, vec3 gridPoint);
float worleyNoise3(vec3 p);
float fractalWorleyNoise(vec3 p, float mask);
float sinusoidalWarp(vec3 p, float mask, float slowCosTime);
vec3 computeDisplacedPoint(vec3 p, vec3 nor, float fastSinTime, float fastCosTime, float slowCosTime);
vec3 computeDisplacedNormal(vec3 p, vec3 displacedP, vec3 nor, float fastSinTime, float fastCosTime, float slowCosTime);
vec3 computeUnitSphereNormal(vec3 p);

void main()
{
    mat3 invTranspose = mat3(u_ModelInvTr);
    vec3 nor = normalize(invTranspose * vec3(vs_Nor));          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    float fastSinTime = (sin(u_Time * .002) + 1.0) / 2.0;
    float fastCosTime = (cos(u_Time * .002) + 1.0) / 2.0;
    float slowCosTime = (cos(u_Time * .001) + 1.0) / 2.0;

    vec3 displacedP = computeDisplacedPoint(modelposition.xyz, nor, fastSinTime, fastCosTime, slowCosTime);
    vec3 newNor = computeDisplacedNormal(modelposition.xyz, displacedP, nor, fastSinTime, fastCosTime, slowCosTime);
    fs_Nor = vec4(newNor, 0.0);

    vec4 newPos = vec4(displacedP, 1.0);

    fs_LightVec = lightPos - newPos;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * newPos;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices

    fs_Pos = newPos;
}

vec3 random3(vec3 p)
{
    return fract(
        sin(vec3(
            dot(p, vec3(127.1, 311.7, 213.3)),
            dot(p, vec3(269.5, 183.3, 123.9)),
            dot(p, vec3(57.3, 277.9, 339.7)))
            * 43758.5453));
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

float perlinNoise(vec3 p)
{
    float surfletSum = 0.0;

    // Iterate over the eight integer corners surrounding pos
    for (int dx = 0; dx <= 1; dx++)
    {
        for (int dy = 0; dy <= 1; dy++)
        {
            for (int dz = 0; dz <= 1; dz++)
            {
                surfletSum += computeSurflet(p, floor(p) + vec3(dx, dy, dz));
            }
        }
    }

    return surfletSum;
}

float worleyNoise3(vec3 p)
{
    vec3 pInt = floor(p);
    vec3 pFract = fract(p);

    // Minimum distance initialized to max.
    float minDist = sqrt(3.0);
    for (int y = -1; y <= 1; y++)
    {
        for (int x = -1; x <= 1; x++)
        {
            for (int z = -1; z <= 1; z++)
            {
                // Direction in which neighbor cell lies
                vec3 neighbor = vec3(float(x), float(y), float(z));

                // Get the Voronoi centerpoint for the neighboring cell
                vec3 point = random3(pInt + neighbor);

                // Distance between fragment coord and neighbor’s Voronoi point
                vec3 diff = neighbor + point - pFract;
                float dist = length(diff);

                minDist = min(minDist, dist);
            }
        }
    }

    return minDist;
}

float fractalWorleyNoise(vec3 p, float mask)
{
    float total = 0.0;
    float persistence = 0.5;
    int octaves = 4;
    float freq = 10.0;
    float amp = 0.5;

    for (int i = 1; i <= octaves; i++)
    {
        float noiseStep = worleyNoise3(p * freq);
        total += noiseStep * amp;
        freq *= 2.0;
        amp *= persistence;
    }

    return total * mix(0.3, 1.0, smoothstep(-0.3, 0.5, mask));
}

float sinusoidalWarp(vec3 p, float mask, float slowCosTime)
{
    float freq1 = 60.0;
    float freq2 = 45.0;
    float sinAmp = 5.0;
    float perlinAmp = 8.0;
    float perlinFactor = perlinAmp * perlinNoise(p + slowCosTime);
    float offset = sinAmp * (sin(freq1 * p.y + perlinFactor) + sin(freq2 * p.z + perlinFactor) + 2.0) * 0.25;
    return smoothstep(-0.3, 1.0, mask) * offset;
}

vec3 computeDisplacedPoint(vec3 p, vec3 nor, float fastSinTime, float fastCosTime, float slowCosTime)
{
    float mask = dot(nor, tailDir);
    vec3 jitteredP = p + vec3(fastSinTime, fastCosTime, fastSinTime);
    float sinFactor = sinusoidalWarp(p, mask, slowCosTime);
    vec3 sinDisplacement = sinFactor * tailDir;
    float worleyFactor = fractalWorleyNoise(jitteredP, mask);
    vec3 worleyDisplacement = worleyFactor * nor;
    return p + sinDisplacement - worleyDisplacement;
}

vec3 computeDisplacedNormal(vec3 p, vec3 displacedP, vec3 nor, float fastSinTime, float fastCosTime, float slowCosTime)
{
    vec3 tangent;

    if (abs(dot(nor, zAxis)) > 0.9)
    {
        tangent = normalize(cross(yAxis, nor));
    }
    else
    {
        tangent = normalize(cross(zAxis, nor));
    }

    vec3 bitangent = cross(nor, tangent);

    vec3 pTan = p + epsilon * tangent;
    vec3 pBitan = p + epsilon * bitangent;

    vec3 displacedT = computeDisplacedPoint(pTan, computeUnitSphereNormal(pTan), fastSinTime, fastCosTime, slowCosTime);
    vec3 displacedB = computeDisplacedPoint(pBitan, computeUnitSphereNormal(pBitan), fastSinTime, fastCosTime, slowCosTime);
    return normalize(cross(displacedT - displacedP, displacedB - displacedP));
}

vec3 computeUnitSphereNormal(vec3 p)
{
    return normalize(p);
}