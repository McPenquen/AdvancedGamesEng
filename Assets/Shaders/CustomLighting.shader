Shader "Unlit/CustomLighting"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _LightSourcePosition ("Light Source Position", Vector) = (0, 0 ,0, 0)
        _ShadowColor ("Shadow color", Color) = (0,0,0,0.5)
    }
    SubShader
    {
        CGINCLUDE
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct v2g
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPosition : TEXCOORD2;
            };

            struct g2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPosition : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _LightSourcePosition;
            fixed4 _ShadowColor;

            v2g vert (appdata v)
            {
                v2g o;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = v.vertex;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
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

            [maxvertexcount(3)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> triStream)
            {
                g2f o;
                for (int i = 0; i < 3; i++)
                {
                    o.vertex = UnityObjectToClipPos(input[i].vertex + (20,0,0,0));
                    o.uv = input[i].uv;
                    o.worldPosition = input[i].worldPosition;
                    o.worldNormal = input[i].worldNormal;
                    triStream.Append(o);
                }
                triStream.RestartStrip();
            }

            fixed4 frag (g2f i) : SV_Target
            {
                // Calculate the amount of light falling on the 
                fixed3 lightDirection = normalize(i.worldPosition - _LightSourcePosition.xyz);
                fixed intensity = - dot(lightDirection, i.worldNormal);
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _Color * intensity;
                return col;
            }
            ENDCG
        }

        // Shadow Passes beneath
        // Shadow pass 1
        Pass
        {
            Tags { "RenderType"="Opaque" "Queue"="Geometry+1" }
            LOD 100

            Cull Front
            Blend SrcAlpha OneMinusSrcAlpha
            Stencil
            {
                Ref 0
                Comp always
                Pass keep
                Fail keep
                ZFail IncrWrap
            }
            ColorMask 0

            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            [maxvertexcount(3)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> triStream)
            {
                // Transform the vertices to be of a shadow
                g2f o;
                for (int i = 0; i < 3; i++)
                {
                    fixed4 oldVert = input[i].vertex;
                    //oldVert.y = oldVert.y + 0.01;
                    //oldVert.z = oldVert.z - 1.01;
                    oldVert.y = oldVert.y  -0.5;
                    oldVert.z = oldVert.z - 1.01;
                    fixed4 newVert = UnityObjectToClipPos(oldVert + (0,0,0,0)) + (0,0,0,0);
                    o.vertex = newVert;
                    o.uv = input[i].uv;
                    o.worldPosition = input[i].worldPosition + (10,10,0,0);
                    o.worldNormal = input[i].worldNormal;
                    triStream.Append(o);
                }
                triStream.RestartStrip();
            }

            fixed4 frag (g2f i) : SV_Target
            {
                // Return shadow color
                return _ShadowColor;
            }
            ENDCG
        }
        // Shadow pass 2
        Pass
        {
            Tags { "RenderType"="Opaque" "Queue"="Geometry+1" }
            LOD 100

            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
            Stencil
            {
                Ref 0
                Comp always
                Pass keep
                Fail keep
                ZFail DecrWrap
            }

            ColorMask 0

            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            [maxvertexcount(3)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> triStream)
            {
                // Transform the vertices to be of a shadow
                g2f o;
                for (int i = 0; i < 3; i++)
                {
                    fixed4 oldVert = input[i].vertex;
                    //oldVert.y = oldVert.y + 0.01;
                    //oldVert.z = oldVert.z - 1.01;
                    oldVert.y = oldVert.y  -0.5;
                    oldVert.z = oldVert.z - 1.01;
                    fixed4 newVert = UnityObjectToClipPos(oldVert + (0,0,0,0)) + (0,0,0,0);
                    o.vertex = newVert;
                    o.uv = input[i].uv;
                    o.worldPosition = input[i].worldPosition + (10,10,0,0);
                    o.worldNormal = input[i].worldNormal;
                    triStream.Append(o);
                }
                triStream.RestartStrip();
            }

            fixed4 frag (g2f i) : SV_Target
            {
                // Return shadow color
                return _ShadowColor;
            }
            ENDCG
        }
        // Shadow Pass 3
                Pass
        {
            Tags { "RenderType"="Opaque" "Queue"="Geometry+1" }
            LOD 100

            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
            Stencil
            {
                Ref 1
                Comp equal 
                Pass keep
                Fail keep
                ZFail keep
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            [maxvertexcount(3)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> triStream)
            {
                // Transform the vertices to be of a shadow
                g2f o;
                for (int i = 0; i < 3; i++)
                {
                    fixed4 oldVert = input[i].vertex;
                    //oldVert.y = oldVert.y + 0.01;
                    //oldVert.z = oldVert.z - 1.01;
                    oldVert.y = oldVert.y  -0.5;
                    oldVert.z = oldVert.z - 1.01;
                    fixed4 newVert = UnityObjectToClipPos(oldVert + (0,0,0,0)) + (0,0,0,0);
                    o.vertex = newVert;
                    o.uv = input[i].uv;
                    o.worldPosition = input[i].worldPosition + (10,10,0,0);
                    o.worldNormal = input[i].worldNormal;
                    triStream.Append(o);
                }
                triStream.RestartStrip();
            }

            fixed4 frag (g2f i) : SV_Target
            {
                // Return shadow color
                return _ShadowColor;
            }
            ENDCG
        }
    }
}
// shader basics learned from: https://www.youtube.com/watch?v=4XfXOEDzBx4&ab_channel=WorldofZero
// geom shader learned from: https://gamedevbill.com/unity-vertex-shader-and-geometry-shader-tutorial/ 
// stencil test learned from: https://liu-if-else.github.io/stencil-buffer's-uses-in-unity3d/ 
