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
                float dist = length(diff);
                minDist = min(minDist, dist);
            }
        }
    }
    return minDist;
}


// https://thebookofshaders.com/13
float fbmWorley(vec3 p, float freq) {
    float sum = 0.0;
    float persistence = 0.5;

    vec3 shift = vec3(1000.0);
    float time = u_Time / 1.0;
    mat3 rot = mat3(cos(time), sin(time),0.0, 
                    -sin(time), cos(time), 0.0,
                    0.0, 0.0, 1.0);

    for(int i = 0; i < 4; ++i) {
        sum += persistence * WorleyNoise(p * freq);
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

void main()
{
    float radius = 1.0f;

    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    //fs_Pos = vs_Pos;

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

//    float worley = fbmWorley(vs_Pos.xyz, 1.0);
    vec3 temp_pos = vs_Pos.xyz + u_Time / 1000.0;
//    float temp_scale = fbmWorley(vs_Pos.xyz, 1.0) * sin(u_Time / 1000.0);
    float temp_scale = fbmWorley(vs_Pos.xyz, 1.0);
    float worley = fbm(temp_scale + temp_pos);
//    float worley = fbm(fbm(fbmWorley(vs_Pos.xyz, 1.0) + vs_Pos.xyz) + vs_Pos.xyz);


    worley = sinSmooth(worley);

    h = 4.0 * worley;
    //h += 2.0 * sin(fbmWorley(vs_Pos.yzx, 2.0));
    //h += 1.0 * sin(fbmWorley(vs_Pos.zxy, 4.0));

    //h +=  0.5 * fbm1;

    modelposition = modelposition + fs_Nor * 0.25 * h * u_Height;

    fs_H = h;

    fs_Pos = modelposition;
    
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices


}
