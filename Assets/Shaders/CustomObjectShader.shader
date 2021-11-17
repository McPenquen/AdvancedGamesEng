Shader "Unlit/CustomObjectShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _LightSourcePosition1 ("Light Source Position 1", Vector) = (-1, -1 ,-1, -1)
        _LightSourcePosition2 ("Light Source Position 1", Vector) = (-1, -1 ,-1, -1)
        _LightSourcesAmount ("Number of light sources", Int) = 2
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

            // Struct for the light sources
            struct lightSourceObject
            {
                float4 position;
                float radius;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _LightSourcePosition1;
            fixed4 _LightSourcePosition2;
            int _LightSourcesAmount;

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
                fixed3 lightDirection = normalize(-i.worldPosition + _LightSourcePosition1.xyz);
                fixed intensity = max(dot(lightDirection, i.worldNormal), 0);
                
                // TODO adjust the diffuse based on the light's radius value

                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _Color * intensity;
                return col;

            }
            ENDCG
        }
    }
}
// shader basics learned from: https://www.youtube.com/watch?v=4XfXOEDzBx4&ab_channel=WorldofZero
// geom shader learned from: https://gamedevbill.com/unity-vertex-shader-and-geometry-shader-tutorial/ 
// stencil test learned from: https://liu-if-else.github.io/stencil-buffer's-uses-in-unity3d/ 
// shadow volume generation learned inspired from: https://web.archive.org/web/20110516024500/http://developer.nvidia.com/node/168 