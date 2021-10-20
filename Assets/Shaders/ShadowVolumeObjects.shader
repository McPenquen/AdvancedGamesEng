Shader "Unlit/ShadowVolumeObjects"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _LightSourcePosition ("Light Source Position", Vector) = (0, 0 ,0, 0)
        _LightSourceRadius ("Light source radius", Float) = 10 
        _LightSourcePower ("Light source power", Float) = 10 
        _ShadowColor ("Shadow color", Color) = (0,0,0,0.5)
        _ShadowBias ("Shadow volume bias", Float) = 0.01 
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _LightSourcePosition;
            fixed4 _ShadowColor;
            fixed _LightSourceRadius;
            fixed _LightSourcePower;
            fixed _ShadowBias;

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
                float3 normals[3];
                float3 toLightDirs[3];
                float3 tempVertices[3];
                float4 lightOrientedTriangle[3];
                lightOrientedTriangle[0] = input[0].vertex;
                lightOrientedTriangle[1] = input[1].vertex;
                lightOrientedTriangle[2] = input[2].vertex;
                float4 frontCap[3];
                float4 backCap[3];

                // Calculate normals for each vertex
                normals[0] = cross(input[1].vertex - input[0].vertex, input[2].vertex - input[0].vertex);
                normals[1] = cross(input[0].vertex - input[1].vertex, input[2].vertex - input[1].vertex);
                normals[2] = cross(input[0].vertex - input[2].vertex, input[1].vertex - input[2].vertex);

                // Compute direction from vertices to light
                toLightDirs[0] = _LightSourcePosition - input[0].vertex;
                toLightDirs[1] = _LightSourcePosition - input[1].vertex;
                toLightDirs[2] = _LightSourcePosition - input[2].vertex;

                // Check if the triangle faces the light
                bool facesLight = true;
                if (!(dot(normals[0], toLightDirs[0]) > 0 || dot(normals[1], toLightDirs[1]) > 0 || dot(normals[2], toLightDirs[2]) > 0 ))
                {
                    facesLight = false;
                    lightOrientedTriangle[1] = input[2].vertex;
                    lightOrientedTriangle[2] = input[1].vertex;
                }

                // Transform the vertices to be of a shadow
                sg2f o;
                // First the front cap
                for (int i = 0; i < 3; i++)
                {
                    fixed4 oldVert = lightOrientedTriangle[i];
                    frontCap[i] = oldVert;
                    o.vertex = UnityObjectToClipPos(oldVert);
                    triStream.Append(o);
                }
                triStream.RestartStrip();

                // Then the back cap
                for (int i = 0; i < 3; i++)
                {
                    fixed4 oldVert = lightOrientedTriangle[i];
                    // Light to vertex dir
                    fixed3 toLightDirection = normalize(_LightSourcePosition - oldVert);
                    fixed toLightDistance = length(_LightSourcePosition - oldVert);

                    oldVert.x = oldVert.x + toLightDirection * (_LightSourceRadius - toLightDistance);
                    oldVert.y = oldVert.y + toLightDirection * (_LightSourceRadius - toLightDistance);
                    oldVert.z = oldVert.z + toLightDirection * (_LightSourceRadius - toLightDistance);

                    backCap[i] = oldVert;

                    o.vertex = UnityObjectToClipPos(oldVert);
                    triStream.Append(o);
                }
                triStream.RestartStrip();

                // Loop over the edges and connect the back and front cap
                for (int i = 0; i < 3; i++)
                {
                    // Find neighbour indeces for this triangle
                    int v0 = i;
                    int v1 = i+1;
                    int v2 = i+2;

                    if (i == 1)
                    {
                        v0 = 1;
                        v1 = 2;
                        v2 = 0;
                    }
                    else if (i == 2)
                    {
                        v0 = 2;
                        v1 = 0;
                        v2 = 1;
                    }
                    
                    // Compute again the normals and light directions                    
                    //normals[0] = cross(input[v1].vertex - input[v0].vertex, input[v2].vertex - input[v0].vertex);
                    //normals[1] = cross(input[v2].vertex - input[v1].vertex, input[v0].vertex - input[v1].vertex);
                    //normals[2] = cross(input[v0].vertex - input[v2].vertex, input[v1].vertex - input[v2].vertex);
                    //toLightDirs[0] = _LightSourcePosition - input[v0].vertex;
                    //toLightDirs[1] = _LightSourcePosition - input[v1].vertex;
                    //toLightDirs[2] = _LightSourcePosition - input[v2].vertex;

                    // Triangle 1 from the front cap
                    fixed4 oldVert = frontCap[v0];
                    o.vertex = UnityObjectToClipPos(oldVert);
                    triStream.Append(o);

                    oldVert = frontCap[v1];
                    o.vertex = UnityObjectToClipPos(oldVert);
                    triStream.Append(o);

                    oldVert = backCap[v0];
                    o.vertex = UnityObjectToClipPos(oldVert);
                    triStream.Append(o); 

                    triStream.RestartStrip();

                    // Triangle 1 from the back cap
                    oldVert = backCap[v0];
                    o.vertex = UnityObjectToClipPos(oldVert);
                    triStream.Append(o);

                    oldVert = backCap[v1];
                    o.vertex = UnityObjectToClipPos(oldVert);
                    triStream.Append(o);

                    oldVert = frontCap[v0];
                    o.vertex = UnityObjectToClipPos(oldVert);
                    triStream.Append(o);    

                    triStream.RestartStrip(); 
                };
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
        //Pass
        //{
        //    Tags { "RenderType"="Transparent" "Queue"="Geometry+1" }
        //    LOD 100
//
        //    Cull Front
        //    Stencil
        //    {
        //        Ref 0
        //        Comp always
        //        ZFail IncrWrap
        //    }
        //    ColorMask 0
//
        //    CGPROGRAM
        //    #pragma vertex vert
        //    #pragma geometry shadowGeom
        //    #pragma fragment shadowFrag
        //    ENDCG
        //}
        //// Shadow pass 2
        //Pass
        //{
        //    Tags { "RenderType"="Transparent" "Queue"="Geometry+1" }
        //    LOD 100
//
        //    Cull Back
        //    Stencil
        //    {
        //        Ref 0
        //        Comp always
        //        ZFail DecrWrap
        //    }
//
        //    ColorMask 0
//
        //    CGPROGRAM
        //    #pragma vertex vert
        //    #pragma geometry shadowGeom
        //    #pragma fragment shadowFrag
        //    ENDCG
        //}
        //// Shadow Pass 3 - show the image
        Pass
        {
            Tags { "RenderType"="Transparent" "Queue"="Geometry+1" }
            LOD 100

            //Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
            //Stencil
            //{
            //    Ref 1
            //    Comp equal 
            //}

            //ColorMask 0

            CGPROGRAM
            #pragma vertex vert
            #pragma geometry shadowGeom
            #pragma fragment shadowFrag
            ENDCG
        }
    }
}
// shader basics learned from: https://www.youtube.com/watch?v=4XfXOEDzBx4&ab_channel=WorldofZero
// geom shader learned from: https://gamedevbill.com/unity-vertex-shader-and-geometry-shader-tutorial/ 
// stencil test learned from: https://liu-if-else.github.io/stencil-buffer's-uses-in-unity3d/ 
// shadow volume generation learned inspired from: https://web.archive.org/web/20110516024500/http://developer.nvidia.com/node/168 