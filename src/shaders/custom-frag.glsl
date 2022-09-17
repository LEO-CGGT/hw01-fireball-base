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

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

vec3 random3(vec3 p)
{
    return fract(sin(vec3(dot(p, vec3(127.1f, 311.7f, 191.999f)),
                     dot(p, vec3(269.5f,183.3f, 472.6f)),
                     dot(p, vec3(377.4f,451.1f, 159.2f)))
                     * 43758.5453f));
}

// WorleyNoise function copied from the lecture notes
float WorleyNoise(vec3 p) 
{
    vec3 pInt = floor(p);
    vec3 pFract = fract(p);
    float minDist = 1.0; // Minimum distance initialized to max.
    for (int z = -1; z <= 1; ++z)
    {
        for(int y = -1; y <= 1; ++y) 
        {
            for(int x = -1; x <= 1; ++x) 
            {
                vec3 neighbor = vec3(float(x), float(y), float(z)); // Direction in which neighbor cell lies
                vec3 point = random3(pInt + neighbor); // Get the Voronoi centerpoint for the neighboring cell
                vec3 diff = neighbor + point - pFract; // Distance between fragment coord and neighbor’s Voronoi point
                float dist = length(diff);
                minDist = min(minDist, dist);
            }
        }
    }
    return minDist;
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
float fbm(vec3 noise)
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
void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.
        
        vec3 col1 = vec3(abs(fs_Pos.x), abs(fs_Pos.y),  abs(fs_Pos.z));
        vec3 col2 = vec3(abs(fs_Pos.y), abs(fs_Pos.z),  abs(fs_Pos.x));
        vec3 col3 = vec3(abs(fs_Pos.z), abs(fs_Pos.x),  abs(fs_Pos.y));

        vec3 col4 = fbm(fs_Pos.xyz) * col2;
        vec3 col5 = WorleyNoise(fs_Pos.xyz) * col3;

        vec3 mix1 = mix(col1, col2, sin(u_Time/800.0f));
        vec3 mix2 = mix(col2, col3, sin(u_Time/800.0f));
        vec3 mix3 = mix(col3, col4, sin(u_Time/800.0f));
        vec3 mix4 = mix(col4, col5, sin(u_Time/800.0f));

        vec3 mix5 = mix(mix1, mix2, cos(u_Time/400.0f));
        vec3 mix6 = mix(mix4, mix3, cos(u_Time/400.0f));

        vec3 mix7 = mix(mix5, mix6, sin(u_Time/200.0f));
        vec3 mix8 = mix(mix6, mix5, sin(u_Time/200.0f));

        vec3 mix9 = mix(mix7, mix8, cos(u_Time/100.0f));

        // Compute final shaded color
        //out_Col = vec4(col, 1.0);
        out_Col = vec4(mix9, 1.0) ;

}
