Shader "Unlit/ShadowVolumeObjects"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _LightSourcePosition ("Light Source Position", Vector) = (0, 5 ,0, 0)
        _LightSourceRadius ("Light source radius", Float) = 20 
        _LightSourcePower ("Light source power", Float) = 10 
        _ShadowColor ("Shadow color", Color) = (0,0,0,0.5)
        _ShadowBias ("Shadow volume bias", Float) = 0.01 
        _MeshTrianglesNumber ("Number of triangles in the mesh", Int) = 6
    }
    SubShader
    {
        CGINCLUDE
            #include "UnityCG.cginc"
            // Initial app data
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };
            // Vertex shader info send to geomerty shader
            struct v2g
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPosition : TEXCOORD2;
            };
            // Geometry shader info send to fragment shader
            struct g2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPosition : TEXCOORD2;
            };
            // Shadow geometry shader info send to the shadow fragment shader
            struct sg2f
            {
                float4 vertex : SV_POSITION;
            };
            struct adjTrianglesStruct
            {
               float4 vertex1;
               float4 vertex2;
               float4 vertex3;
               float4 vertex4;
               float4 vertex5;
               float4 vertex6;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _LightSourcePosition;
            fixed4 _ShadowColor;
            fixed _LightSourceRadius;
            fixed _LightSourcePower;
            fixed _ShadowBias;
            int _MeshTrianglesNumber;

            StructuredBuffer<adjTrianglesStruct> adjTriangles;

            // The vertex shader
            v2g vert (appdata v)
            {
                v2g o;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = v.vertex;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            // The geometry shader for the object
            [maxvertexcount(3)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> triStream)
            {
                g2f o;
                for (int i = 0; i < 3; i++)
                {
                    o.vertex = UnityObjectToClipPos(input[i].vertex);
                    o.uv = input[i].uv;
                    o.worldPosition = input[i].worldPosition;
                    o.worldNormal = input[i].worldNormal;
                    triStream.Append(o);
                }
                triStream.RestartStrip();
            }

            // The geometry shader for the shadow
            [maxvertexcount(24)]
            void shadowGeom(triangle v2g input[3], inout TriangleStream<sg2f> triStream)
            {
                // Determine if we cast shadows
                bool castShadows = false;

                // Front cap vertices
                float4 frontCap[3];
                // Back cap vertices
                float4 backCap[3];
                // Centroid of the front cap
                float4 frontCentroid = (0,0,0,0);

                // To the light directions
                float3 lds[3];
                // Triangle normals
                float3 ns[3];
                // If the main triangle is oriented towards light
                bool isFacingLight = true; 

                // Vertex to be generated
                fixed4 vert;
                // Normal for triangle orientation calculations
                float3 normal;
                // Vertices for the sides of the shadow mesh
                float4 vert1, vert2, vert3;
                // Vector used for calculation
                float4 tempVec;

                // The object to retur
                sg2f o;

                // Calculate normals for each vertex
                ns[0] = cross(input[1].vertex - input[0].vertex, input[2].vertex - input[0].vertex);
                ns[1] = cross(input[0].vertex - input[1].vertex, input[2].vertex - input[1].vertex);
                ns[2] = cross(input[0].vertex - input[2].vertex, input[1].vertex - input[2].vertex);

                // Compute direction from vertices to light
                lds[0] = _LightSourcePosition - input[0].worldPosition;
                lds[1] = _LightSourcePosition - input[1].worldPosition;
                lds[2] = _LightSourcePosition - input[2].worldPosition;

                // Save the front cap vertices
                for (int i = 0; i < 3; i++)
                {
                    frontCap[i] = input[i].vertex;
                }
                // Find out if the triangle faces light
                //if (!(dot(ns[0], lds[0]) > 0 || dot(ns[1], lds[1]) > 0 || dot(ns[2], lds[2]) > 0 ))
                if (dot(ns[0], lds[0]) < 0)
                {
                    isFacingLight = false;
                    // Switch the vertices so it faves away from light
                    frontCap[1] = input[2].vertex;
                    frontCap[2] = input[1].vertex;
                }

                // Get the distance to light for all verices
                fixed toLightDistance0 = length(_LightSourcePosition - input[0].worldPosition);
                fixed toLightDistance1 = length(_LightSourcePosition - input[1].worldPosition);
                fixed toLightDistance2 = length(_LightSourcePosition - input[2].worldPosition);
                // Cast shadows only if we have all vertices within the radius of the light
                castShadows = (_LightSourceRadius - toLightDistance0) > 0 && 
                    (_LightSourceRadius - toLightDistance1) > 0 &&
                    (_LightSourceRadius - toLightDistance2) > 0;

                // Cast shadows only if it is within the light's radius
                if (castShadows)
                {
                    // First the front cap
                    for (int i = 0; i < 3; i++)
                    {
                        vert = frontCap[i];
                        o.vertex = UnityObjectToClipPos(vert);
                        if (!isFacingLight)
                        {
                            triStream.Append(o);
                        }
                    }
                    if (!isFacingLight)
                    {
                        triStream.RestartStrip();
                    }
                    

                    // Calculate centroid of the front cap triangle
                    frontCentroid.x = (frontCap[0].x + frontCap[1].x + frontCap[2].x) / 3;
                    frontCentroid.y = (frontCap[0].y + frontCap[1].y + frontCap[2].y) / 3;
                    frontCentroid.z = (frontCap[0].z + frontCap[1].z + frontCap[2].z) / 3;

                    // Then the back cap
                    for (int i = 0; i < 3; i++)
                    {
                        // World position
                        fixed3 worldPos = mul(unity_ObjectToWorld, frontCap[i]).xyz;

                        // Get the distance to light
                        fixed toLightDistance = length(_LightSourcePosition - worldPos);
                        // Calculate the displacement of the shadow vertices 
                        fixed shadowBackCapDisplacement = _LightSourceRadius - toLightDistance;

                        vert = frontCap[i];
                        fixed3 toLightDirection = normalize(worldPos - _LightSourcePosition.xyz);

                        vert.x = vert.x + toLightDirection.x * (_LightSourceRadius - toLightDistance);
                        vert.y = vert.y + toLightDirection.y * (_LightSourceRadius - toLightDistance);
                        vert.z = vert.z + toLightDirection.z * (_LightSourceRadius - toLightDistance);

                        backCap[i] = vert;
                    }
                    // Generate the far/back cap away from the light
                    if (isFacingLight) // Only for the vertices facing light
                    {
                        o.vertex = UnityObjectToClipPos(backCap[0]);
                        triStream.Append(o);
                        o.vertex = UnityObjectToClipPos(backCap[2]);
                        triStream.Append(o);
                        o.vertex = UnityObjectToClipPos(backCap[1]);
                        triStream.Append(o);
                        triStream.RestartStrip();
                    }
                    else
                    {
                        //o.vertex = UnityObjectToClipPos(backCap[0]);
                        //triStream.Append(o);
                        //o.vertex = UnityObjectToClipPos(backCap[1]);
                        //triStream.Append(o);
                        //o.vertex = UnityObjectToClipPos(backCap[2]);
                        //triStream.Append(o);
                        //triStream.RestartStrip();
                    }

                    // Primitive Index in adj triangles
                    int primitiveIdx = -1;
                    // Find the index in all the adj triangles
                    for (int j = 0; j < _MeshTrianglesNumber; j++)
                    {
                        bool3 b1 = adjTriangles[j].vertex1.xyz == frontCap[0].xyz;
                        bool3 b2 = adjTriangles[j].vertex3.xyz == frontCap[0].xyz;
                        bool3 b3 = adjTriangles[j].vertex5.xyz == frontCap[0].xyz;
                        
                        if ( all(b1) || all(b2) || all(b3))
                        {
                            b1 = adjTriangles[j].vertex1.xyz == frontCap[1].xyz;
                            b2 = adjTriangles[j].vertex3.xyz == frontCap[1].xyz;
                            b3 = adjTriangles[j].vertex5.xyz == frontCap[1].xyz;

                            if (all(b1) || all(b2) || all(b3))
                            {
                                b1 = adjTriangles[j].vertex1.xyz == frontCap[2].xyz;
                                b2 = adjTriangles[j].vertex3.xyz == frontCap[2].xyz;
                                b3 = adjTriangles[j].vertex5.xyz == frontCap[2].xyz;

                                if (all(b1) || all(b2) || all(b3))
                                {
                                    // If the 3 central vertices are these three front cap vertices we found the id
                                    primitiveIdx = j;
                                    break;      
                                }
                            }
                        }
                        
                    }

                    // Array for all the 6 vertices
                    float4 sixVertices[6];
                    // Save the adjTriangles in a list
                    sixVertices[0] = adjTriangles[primitiveIdx].vertex1;
                    sixVertices[1] = adjTriangles[primitiveIdx].vertex2;
                    sixVertices[2] = adjTriangles[primitiveIdx].vertex3;
                    sixVertices[3] = adjTriangles[primitiveIdx].vertex4;
                    sixVertices[4] = adjTriangles[primitiveIdx].vertex5;
                    sixVertices[5] = adjTriangles[primitiveIdx].vertex6;
                    

                    // Loop over the edges and connect the back and front cap
                    for (int i = 0; i < 3; i++)
                    {
                        // Find neighbour indeces for this triangle
                        int v0 = i*2;
                        int extraV = (i*2)+1;
                        int v2 = (i*2+2) % 6;
                        // Find the indecies for the front and back cap arrays
                        int fb0 = -1;
                        int fb1 = -1;
                        bool3 isIt; // check for vec3

                        for (int j = 0; j < 3; j++)
                        { 
                            isIt = sixVertices[v0].xyz == frontCap[j].xyz;
                            if (all(isIt))
                            {
                                fb0 = j;
                            }
                        }

                        for (int j = 0; j < 3; j++)
                        { 
                            isIt = sixVertices[v2].xyz == frontCap[j].xyz;
                            if (all(isIt))
                            {
                                fb1 = j;
                            }
                        }

                        // Calculate normals for each adj triangle
                        ns[0] = cross(sixVertices[extraV].xyz - sixVertices[v0].xyz, sixVertices[v2].xyz - sixVertices[v0].xyz);
                        ns[1] = cross(sixVertices[v2].xyz - sixVertices[extraV].xyz, sixVertices[v0].xyz - sixVertices[extraV].xyz);
                        ns[2] = cross(sixVertices[v0].xyz - sixVertices[v2].xyz, sixVertices[extraV].xyz - sixVertices[v2].xyz);

                        // Compute direction from vertices to light
                        lds[0] = _LightSourcePosition.xyz - mul(unity_ObjectToWorld, sixVertices[v0]).xyz;
                        lds[1] = _LightSourcePosition.xyz - mul(unity_ObjectToWorld, sixVertices[extraV]).xyz;
                        lds[2] = _LightSourcePosition.xyz - mul(unity_ObjectToWorld, sixVertices[v2]).xyz;

                        // If the w==-1 the extraV isn't assigned and so it is the edge,
                        // or if the new triangle changes that it faces light, then it is an edge too
                        if (sixVertices[extraV].w == -1 || 
                            isFacingLight != (dot(ns[0], lds[0]) > 0)
                            //isFacingLight != (dot(ns[0], lds[0]) > 0 || dot(ns[1], lds[1]) > 0 || dot(ns[2], lds[2]) > 0 )
                        )
                        {
                            // Triangle 1 vertices
                            vert1 = frontCap[fb0];
                            vert2 = frontCap[fb1];
                            vert3 = backCap[fb0];

                            // Calculate the normal
                            normal = cross(vert2 - vert1, vert3 - vert1);
                            // The direction from the centroid to one of the vertices
                            tempVec = frontCap[fb0] - frontCentroid;
                            // If the angle between the 2 vectors is more than 90 deg it is pointing inwards so flip the two coordinates to flip the face
                            if (dot(normal, tempVec) < 0)
                            {
                                vert2 = backCap[fb0];
                                vert3 = frontCap[fb1];
                            }

                            // Triangle 1 from the front cap
                            o.vertex = UnityObjectToClipPos(vert1);
                            triStream.Append(o);

                            o.vertex = UnityObjectToClipPos(vert2);
                            triStream.Append(o);

                            o.vertex = UnityObjectToClipPos(vert3);
                            triStream.Append(o); 

                            triStream.RestartStrip();

                            // Triangle 2 vertices
                            vert1 = backCap[fb0];
                            vert2 = backCap[fb1];
                            vert3 = frontCap[fb1];

                            // Calculate the normal
                            normal = cross(vert2 - vert1, vert3 - vert1);
                            // The direction from the centroid to one of the vertices
                            tempVec = frontCap[fb1] - frontCentroid;
                            // If the angle between the 2 vectors is more than 90 deg it is pointing inwards so flip the two coordinates to flip the face
                            if (dot(normal, tempVec) < 0)
                            {
                                vert2 = frontCap[fb1];
                                vert3 = backCap[fb1];
                            }
        
                            // Triangle 2 from the back cap
                            o.vertex = UnityObjectToClipPos(vert1);
                            triStream.Append(o);

                            o.vertex = UnityObjectToClipPos(vert2);
                            triStream.Append(o);

                            o.vertex = UnityObjectToClipPos(vert3);
                            triStream.Append(o);    

                            triStream.RestartStrip(); 
                        }
                    }
                }
            }
            
            // The shadow fragment shader
            fixed4 shadowFrag (sg2f i) : SV_Target
            {
                // Return shadow color
                return _ShadowColor;
            }

        ENDCG

        Pass
        {
            Tags { "RenderType"="Opaque" }
            LOD 100

            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            fixed4 frag (g2f i) : SV_Target
            {
                // Calculate the amount of light falling on the pixel
                fixed3 lightDirection = normalize(-i.worldPosition + _LightSourcePosition.xyz);
                fixed intensity = max(dot(lightDirection, i.worldNormal), 0);
                
                // TODO adjust the diffuse based on the light's radius value
                // Add distance in relation to the radius to the equation
                //fixed toLightDistance = length(-i.worldPosition + _LightSourcePosition.xyz);
                // Define light constants
                //fixed3 constants = (1, 1, 1);
                //fixed attenutation = 1 /(constants.x/_LightSourcePower + constants.y/_LightSourcePower * toLightDistance + constants.z * toLightDistance * toLightDistance);
                // learned from: https://gamedev.stackexchange.com/questions/21057/does-the-linear-attenuation-component-in-lighting-models-have-a-physical-counter 

                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _Color * intensity;
                return col;

            }
            ENDCG
        }

        // Shadow Passes beneath - Carmack's
        // Shadow pass 1
        Pass
        {
            Tags { "RenderType"="Transparent" "Queue"="Geometry+1" }
            LOD 100

            Cull Front
            Stencil
            {
                Ref 0
                Comp always
                ZFail IncrWrap
            }
            ColorMask 0

            CGPROGRAM
            #pragma vertex vert
            #pragma geometry shadowGeom
            #pragma fragment shadowFrag
            ENDCG
        }
        // Shadow pass 2
        Pass
        {
            Tags { "RenderType"="Transparent" "Queue"="Geometry+1" }
            LOD 100

            Cull Back
            Stencil
            {
                Ref 0
                Comp always
                ZFail DecrWrap
            }

            ColorMask 0

            CGPROGRAM
            #pragma vertex vert
            #pragma geometry shadowGeom
            #pragma fragment shadowFrag
            ENDCG
        }
        // Shadow Pass 3 - show the image
        Pass
        {
            Tags { "RenderType"="Transparent" "Queue"="Geometry+1" }
            LOD 100

            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
            //Stencil
            //{
            //    Ref 1
            //    Comp equal 
            //}


            CGPROGRAM
            #pragma vertex vert
            #pragma geometry shadowGeom
            #pragma fragment shadowFrag
            ENDCG
        }

        //Pass
        //{
        //    Tags { "RenderType"="Transparent" "Queue"="Geometry+1" }
        //    LOD 100
        //    Blend SrcAlpha OneMinusSrcAlpha
//
        //    CGPROGRAM
        //    #pragma vertex vert
        //    #pragma geometry shadowGeom
        //    #pragma fragment shadowFrag
        //    ENDCG
        //}
    }
}
// shader basics learned from: https://www.youtube.com/watch?v=4XfXOEDzBx4&ab_channel=WorldofZero
// geom shader learned from: https://gamedevbill.com/unity-vertex-shader-and-geometry-shader-tutorial/ 
// stencil test learned from: https://liu-if-else.github.io/stencil-buffer's-uses-in-unity3d/ 
// shadow volume generation learned inspired from: https://web.archive.org/web/20110516024500/http://developer.nvidia.com/node/168 