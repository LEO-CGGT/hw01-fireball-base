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
uniform int u_Frenzy;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

in vec4 fs_Pos;

in float fs_H;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

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


void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

        float ambientTerm = 0.2;
        //vec4 view_vec = fs_CameraPos- fs_Pos;   // the view vector
        //vec4 H = (normalize(view_vec) + normalize(fs_LightVec)) / 2.0;  // compute the H vector

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        vec3 white = vec3(252.0,246.0, 144.0);
        vec3 yellow = vec3(244.0, 211.0, 51.0);
        vec3 orange1 = vec3(212.0, 101.0, 41.0);
        vec3 orange2 = vec3(235.0, 122.0, 25.0);
        vec3 red = vec3(188.0, 61.0, 39.0);
        vec3 red2 = vec3(255.0, 0.0, 0.0);
        vec3 darkRed = vec3(200.0, 0.0, 0.0);

        float blendWeight = fs_H;
        
        vec3 c1 = mix(white, yellow, bias(0.8, smoothstep(0.0, 1.0, blendWeight)));
        vec3 c2 = mix(c1, orange1, bias(0.85, smoothstep(0.0, 1.0, blendWeight)));
        vec3 c3 = mix(c2, orange2, bias(0.5, smoothstep(0.0, 1.0, blendWeight)));

        vec3 c4 = mix(c3, red, bias(0.15, smoothstep(0.0, 1.0, blendWeight)));
        vec3 c5 = mix(c4, darkRed, bias(0.3, smoothstep(0.0, 1.0, blendWeight)));

        //vec3 color = mix(finalYellow, finalRed, fs_H);
        //vec3 color = mix(finalYellow, finalRed, smoothstep(0.0, 1.0, fs_H));
        //out_Col = vec4(color.rgb  / 255.0, 1.0);
        out_Col = vec4(c5 / 255.0, 1.0);

}   
