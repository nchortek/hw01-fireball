#version 300 es

in vec4 vs_Pos;
in vec4 vs_Nor;

out vec4 fs_NDC;

void main()
{
    gl_Position = vs_Pos;
    fs_NDC = vs_Pos;
}
