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

uniform float u_Height;
uniform vec2 u_CanvasSize; 
uniform float u_Time;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in float fs_Theta;
in vec4 fs_Pos;

in float fs_H;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float PI = 3.14159265359;

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

vec3 fade(vec3 t){
	return ((6.0*t - 15.0)*t + 10.0)*t*t*t;
}
float noise_gen1(vec3 p)
{
    return fract(sin((dot(p, vec3(127.1, 311.7, 191.999)))) * 43758.5453);
}

float noise_gen2_1( vec2 p) {
    return fract(sin(dot(p.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
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

    float v1 = noise_gen1(vec3(intX, intY, intZ));
    float v2 = noise_gen1(vec3(intX + 1, intY, intZ));
    float v3 = noise_gen1(vec3(intX, intY + 1, intZ));
    float v4 = noise_gen1(vec3(intX + 1, intY + 1, intZ));
    float v5 = noise_gen1(vec3(intX, intY, intZ + 1));
    float v6 = noise_gen1(vec3(intX+1, intY, intZ + 1));
    float v7 = noise_gen1(vec3(intX, intY + 1, intZ + 1));
    float v8 = noise_gen1(vec3(intX+1, intY+1, intZ + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    float i3 = mix(v5, v6, fractX);
    float i4 = mix(v7, v8, fractX);

    float ii1 = mix(i1, i2, fractY);
    float ii2 = mix(i3, i4, fractY);

    return mix(ii1, ii2, fractZ);
}
float fbm2D(vec2 noise)
{
    float total = 0.0f;
    float persistence = 0.5f;
    int octaves = 8;
    float freq = 2.0f;
    float amp = 0.5f;
    
    for (int i=1; i<=octaves; i++)
    {
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

float bias(float t, float b) {
    return (t / ((((1.0/b) - 2.0)*(1.0 - t))+1.0));
}

float gain(float g, float t)
{
    if(t<0.5)
    return bias(1.0-g, 2.0*t) /2.0;
    else
    return 1.0-bias(1.0-g, 2.0-2.0*t) / 2.0;
}
float sinSmooth(float x)
{
    return sin(x * 3.14159 * 0.5);
}


void main()
{

    vec2 uv = (gl_FragCoord.xy)/u_CanvasSize.xy;

    vec2 p = -.5 + gl_FragCoord.xy / u_CanvasSize.xy;
	p.x *= u_CanvasSize.x/u_CanvasSize.y;
	
	float color = 3.0 - (3.*length(2.*p));
	
	vec3 coord = vec3(atan(p.x,p.y)/6.2832+.5, length(p)*.4, .5);
	vec3 xiketic = vec3(5.0, 5.0, 25.0) / 255.0;
    vec3 black = vec3(0.0);
    vec3 yellowWhite = vec3(252.0,246.0, 144.0) / 255.0;
    vec3 white = vec3(1.0);

	//out_Col = vec4( color, pow(max(color,0.),2.)*0.4, pow(max(color,0.),3.)*0.15 , 1.0);
    //out_Col = vec4(xiketic, 1.0);
    //out_Col = vec4(mix(xiketic,white,length(fs_Pos.xy) + 0.05 * fbm2D(vec2(fs_Pos.x, fs_Pos.y))),1.0);
    //if (length(fs_Pos.xy) > (0.1 + 0.1 * fbm2D(vec2(length(fs_Pos.xy), u_Time / 1000.0))))
//     if (length(fs_Pos.xy) > (0.2 + 0.08 * fbm3D(vec3(fs_Pos.xy,  u_Time / 1000.0))))
// //    out_Col = vec4(white.rgb,1.0);
// {
//         //out_Col = vec4(mix(white,yellowWhite,bias(0.5, length(fs_Pos.xy))),1.0);
//       //  out_Col = mix(out_Col, vec4(black.rgb, 1.0), sin(fs_Theta * 10.0 * PI));
//         out_Col = mix(vec4(black, 1.0), vec4(yellowWhite.rgb, 1.0), fbm2D(vec2(fs_Theta, u_Time / 1000.0)) + sin(fs_Theta * 5.0 *PI + fbm2D(vec2(fs_Theta, u_Time / 1000.0))));

//         //out_Col = mix(out_Col, vec4(black.rgb, 1.0), cos(length(fs_Pos.xy / fs_Pos.z)));

// }

    // else
     //out_Col =  vec4(black.rgb, 1.0);
//if (length(fs_Pos.xy) < (0.17 + 0.08 * fbm3D(vec3(fs_Pos.xy,  u_Time / 1000.0))))
     out_Col =  vec4(black.rgb, 1.0);
    //else
     //out_Col =  vec4(black.rgb, 1.0);

     //out_Col =  vec4(black.rgb, mix(0.8, 1.0, length(fs_Pos.xy)));
 //   out_Col = vec4(mix(black,yellowWhite,bias(0.9, length(fs_Pos.xy))),1.0);

}   
