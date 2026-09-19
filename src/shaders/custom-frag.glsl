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
uniform float u_Time;
uniform float u_TimeScale;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in float fs_Displacement;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float bias(float t, float b);
vec3 reinhard(vec3 hdrColor);

void main()
{
    // Material base color (before shading)
    float mappedDisplacement = smoothstep(-2.0, 2.5, fs_Displacement);
    vec4 diffuseColor = vec4(mix(vec3(0.08, 0.14, 0.20), u_Color.rgb, bias(mappedDisplacement, 0.8)), 1.0);

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

    float ambientTerm = 0.25;

    float lightIntensity = clamp(diffuseTerm + ambientTerm, 0.0, 1.0);

    // Compute final shaded color
    float fastSinTime = 1.0 + 3.0 * bias((sin(u_Time * u_TimeScale) + 1.0) / 2.0, 0.2);
    float fireIntensity = mix(480.0, 12.0 * fastSinTime, bias(mappedDisplacement, 0.4));
    vec3 hdrColor = diffuseColor.rgb * fireIntensity * lightIntensity;
    out_Col = vec4(reinhard(hdrColor), diffuseColor.a);
}

float bias(float t, float b)
{
    return (t / ((((1.0 / b) - 2.0) * (1.0 - t)) + 1.0));
}

vec3 reinhard(vec3 hdrColor)
{
    const float whitePoint = 20.0;
    return hdrColor * (1.0 + hdrColor / (whitePoint * whitePoint)) / (1.0 + hdrColor);
}