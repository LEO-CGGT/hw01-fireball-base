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
uniform vec2 u_CanvasSize; 
uniform float u_Madness;


// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise_gen2_1( vec2 p) {
    return fract(sin(dot(p.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float noise_gen3_1(vec3 p)
{
    return fract(sin((dot(p, vec3(127.1, 311.7, 191.999)))) * 43758.5453);
}

vec2 noise_gen2_2(vec2 p)
{
    return fract(sin(vec2(dot(p, vec2(127.1f, 311.7f)),
                     dot(p, vec2(269.5f,183.3f))))
                     * 43758.5453f);
}
float interpNoise2D (vec2 noise) {
    int intX = int(floor(noise.x));
    float fractX = fract(noise.x);
    int intY = int(floor(noise.y));
    float fractY = fract(noise.y);
    float v1 = noise_gen2_1(vec2(intX, intY));
    float v2 = noise_gen2_1(vec2(intX + 1, intY));
    float v3 = noise_gen2_1(vec2(intX, intY + 1));
    float v4 = noise_gen2_1(vec2(intX + 1, intY + 1));
    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    return mix(i1, i2, fractY);
}
float interpNoise3D(vec3 noise)
{
    int intX = int(floor(noise.x));
    float fractX = fract(noise.x);
    int intY = int(floor(noise.y));
    float fractY = fract(noise.y);
    int intZ = int(floor(noise.z));
    float fractZ = fract(noise.z);

    float v1 = noise_gen3_1(vec3(intX, intY, intZ));
    float v2 = noise_gen3_1(vec3(intX + 1, intY, intZ));
    float v3 = noise_gen3_1(vec3(intX, intY + 1, intZ));
    float v4 = noise_gen3_1(vec3(intX + 1, intY + 1, intZ));
    float v5 = noise_gen3_1(vec3(intX, intY, intZ + 1));
    float v6 = noise_gen3_1(vec3(intX+1, intY, intZ + 1));
    float v7 = noise_gen3_1(vec3(intX, intY + 1, intZ + 1));
    float v8 = noise_gen3_1(vec3(intX+1, intY+1, intZ + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    float i3 = mix(v5, v6, fractX);
    float i4 = mix(v7, v8, fractX);

    float ii1 = mix(i1, i2, fractY);
    float ii2 = mix(i3, i4, fractY);

    return mix(ii1, ii2, fractZ);
}
float WorleyNoise(vec2 p) 
{
    vec2 pInt = floor(p);
    vec2 pFract = fract(p);
    float minDist = 1.0; // Minimum distance initialized to max.
            for(int y = -1; y <= 1; ++y) 
        {
            for(int x = -1; x <= 1; ++x) 
            {
                vec2 neighbor = vec2(float(x), float(y)); // Direction in which neighbor cell lies
                vec2 point = noise_gen2_2(pInt + neighbor); // Get the Voronoi centerpoint for the neighboring cell
                
                point = 0.5 + 0.5*sin(u_Time / 1000.0 + 6.2831*point);
                
                vec2 diff = neighbor + point - pFract; // Distance between fragment coord and neighbor’s Voronoi point
                float dist = length(diff);
                minDist = min(minDist, dist);
            }
        }
    return minDist;
}

float fbm (vec2 noise) {
    float total = 0.0;
    float persistence = 0.5;
        float amp = 0.5f;
    int octaves = 8;
    float freq = 2.0f;
    for (int i = 0; i < octaves; ++i) {
        total += interpNoise2D(noise * freq) * amp;
        freq *= 2.0f;
        amp *= persistence;
    }
    return total;
}
float fbm3D(vec3 noise)
{
    float total = 0.0f;
    float persistence = 0.5f;
    int octaves = 8;
    float freq = 2.0f;
    float amp = 0.5f;
    
    for (int i=1; i<=octaves; i++)
    {
        total += interpNoise3D(noise * freq) * amp;
        freq *= 2.0f;
        amp *= persistence;
    }
    return total;
}
float fbmWorley(vec2 p, float freq) {
    float sum = 0.0;
    float persistence = 0.5;
    for(int i = 0; i < 4; ++i) {
        sum += persistence * WorleyNoise(p * freq);
        persistence *= 0.5;
        freq *= 2.0;
    }
    return sum;
}
float sinSmooth(float x)
{
    return sin(x * 3.14159 * 0.5);
}
float bias(float b, float t)
{
    return pow(t, log(b) / log(0.5f));
}

void main()
{
    vec2 uv = gl_FragCoord.xy/u_CanvasSize.xy * 3.0;
    float time = u_Time / 2000.0;

    vec3 darkGreen = vec3(20.0,64.0,63.0) / 255.0;
    vec3 xiketic = vec3(5.0, 5.0, 25.0) / 255.0;
    vec3 darkRed = vec3(212.0, 101.0, 41.0) / 255.0;

    vec3 orange = vec3(235.0, 122.0, 25.0) / 255.0; 


    float fbm_worley = fbmWorley(1.0 * uv, 1.0);
    float c = sinSmooth(fbm_worley);

    for (int i=0; i<1;i++)
    {
         c = fbm3D(vec3(uv + c, time + WorleyNoise(uv)));
    }

    vec3 col1 = mix(darkGreen, orange, bias(0.04, u_Madness)); 
    vec3 col2 = mix(xiketic, darkRed, bias(0.04, u_Madness)); 


    vec3 color = mix(col1, xiketic, c);
    out_Col = vec4(color,1.);
}
