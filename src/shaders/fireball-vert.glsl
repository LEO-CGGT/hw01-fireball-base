#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.


// Reference: 
// Animating Worley Noise: https://thebookofshaders.com/12/

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform float u_Time; 

uniform float u_Height;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Pos;
out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

out float fs_H; // displacement

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.
float noise_gen1(vec3 p)
{
    return fract(sin((dot(p, vec3(127.1, 311.7, 191.999)))) * 43758.5453);
}

float noise_gen1_4D(vec4 p)
{
    return fract(sin((dot(p, vec4(127.1, 311.7, 191.999, 433.7)))) * 43758.5453);
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

float interpNoise4D(vec4 noise)
{
    int intX = int(floor(noise.x));
    float fractX = fract(noise.x);
    int intY = int(floor(noise.y));
    float fractY = fract(noise.y);
    int intZ = int(floor(noise.z));
    float fractZ = fract(noise.z);
    int intW = int(floor(noise.w));
    float fractW = fract(noise.w);

    float v1 = noise_gen1_4D(vec4(intX, intY, intZ, intW));
    float v2 = noise_gen1_4D(vec4(intX + 1, intY, intZ, intW));

    float v3 = noise_gen1_4D(vec4(intX, intY + 1, intZ, intW));
    float v4 = noise_gen1_4D(vec4(intX + 1, intY + 1, intZ, intW));

    float v5 = noise_gen1_4D(vec4(intX, intY, intZ + 1, intW));
    float v6 = noise_gen1_4D(vec4(intX+1, intY, intZ + 1, intW));
    
    float v7 = noise_gen1_4D(vec4(intX, intY + 1, intZ + 1, intW));
    float v8 = noise_gen1_4D(vec4(intX+1, intY+1, intZ + 1, intW));
    
    float v9 = noise_gen1_4D(vec4(intX, intY, intZ, intW + 1));
    float v10 = noise_gen1_4D(vec4(intX + 1, intY, intZ, intW + 1));
    float v11 = noise_gen1_4D(vec4(intX, intY + 1, intZ, intW + 1));
    float v12 = noise_gen1_4D(vec4(intX + 1, intY + 1, intZ, intW + 1));
    float v13 = noise_gen1_4D(vec4(intX, intY, intZ + 1, intW + 1));
    float v14 = noise_gen1_4D(vec4(intX+1, intY, intZ + 1, intW + 1));
    float v15 = noise_gen1_4D(vec4(intX, intY + 1, intZ + 1, intW + 1));
    float v16 = noise_gen1_4D(vec4(intX+1, intY+1, intZ + 1, intW + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    float i3 = mix(v5, v6, fractX);
    float i4 = mix(v7, v8, fractX);
    
    float i5 = mix(v9, v10, fractX);
    float i6 = mix(v11, v12, fractX);
    float i7 = mix(v13, v14, fractX);
    float i8 = mix(v15, v16, fractX);

    float ii1 = mix(i1, i2, fractY);
    float ii2 = mix(i3, i4, fractY);
    float ii3 = mix(i5, i6, fractY);
    float ii4 = mix(i7, i8, fractY);

    float iii1 = mix(ii1, ii2, fractZ);
    float iii2 = mix(ii3, ii4, fractZ);

    return mix(iii1, iii2, fractW);

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
float fbm4D(vec4 noise)
{
    float total = 0.0f;
    float persistence = 0.5f;
    int octaves = 8;
    float freq = 2.0f;
    float amp = 0.5f;
    
    for (int i=1; i<=octaves; i++)
    {
        total += interpNoise4D(noise * freq) * amp;
        freq *= 2.0f;
        amp *= persistence;
    }
    return total;
}
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
                
                point = 0.5 + 0.5*sin(u_Time / 1000.0 + 6.2831*point);
                
                vec3 diff = neighbor + point - pFract; // Distance between fragment coord and neighbor’s Voronoi point
                //vec3 diff = neighbor - pFract; // Distance between fragment coord and neighbor’s Voronoi point
                float dist = length(diff);
                minDist = min(minDist, dist);
            }
        }
    }
    return minDist;
}
// WorleyNoise function copied from the lecture notes
float WorleyNoise4D(vec4 p) 
{
    vec4 pInt = floor(p);
    vec4 pFract = fract(p);
    float minDist = 1.0; // Minimum distance initialized to max.
    for (int w = -1; w<=1;++w)
    {
        for (int z = -1; z <= 1; ++z)
        {
            for(int y = -1; y <= 1; ++y) 
            {
                for(int x = -1; x <= 1; ++x) 
                {
                    vec4 neighbor = vec4(float(x), float(y), float(z), float(w)); // Direction in which neighbor cell lies
                    vec4 diff = neighbor - pFract; // Distance between fragment coord and neighbor’s Voronoi point
                    float dist = length(diff);
                    minDist = min(minDist, dist);
                }
            }
        }
    }
    return minDist;
}

// https://thebookofshaders.com/13
float fbmWorley(vec3 p, float freq) {
    float sum = 0.0;
    float persistence = 0.5;

    for(int i = 0; i < 4; ++i) {
        sum += persistence * WorleyNoise(p * freq);
        //p = rot * p + shift;
        persistence *= 0.5;
        freq *= 2.0;
    }
    return sum;
}

float fbmWorley4D(vec4 p, float freq) {
    float sum = 0.0;
    float persistence = 0.5;
    for(int i = 0; i < 4; ++i) {
        sum += persistence * WorleyNoise4D(p * freq);
        //p = rot * p + shift;
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

float gain(float g, float t)
{
    if(t<0.5)
    return bias(1.0-g, 2.0*t) /2.0;
    else
    return 1.0-bias(1.0-g, 2.0-2.0*t) / 2.0;
}


void main()
{
    float radius = 1.0f;

    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    float h = 0.0;      // displacement amount


    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    float theta = atan(modelposition.y / modelposition.x);
    float phi = atan(length(modelposition.xy) / modelposition.z);


    float fbm_worley = fbmWorley(1.0 * vs_Pos.xyz, 1.0);
    h = sinSmooth(fbm_worley);

    float fbm_layer1 = fbm3D(h + vs_Pos.xyz);
    h = fbm4D(vec4(vs_Pos.xyz + fbm_layer1, u_Time/500.0 + WorleyNoise(modelposition.xyz) ));

    h = gain(0.6, h);

    modelposition = modelposition + fs_Nor * 1.0 * h * u_Height;

    fs_H = h;

    fs_Pos = modelposition;
    
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices


}
