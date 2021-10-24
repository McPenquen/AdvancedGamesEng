Shader "Unlit/CustomLighting"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _LightSourcePosition ("Light Source Position", Vector) = (0, 0 ,0, 0)
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _LightSourcePosition;
        ENDCG

        Pass
        {
            Tags { "RenderType"="Opaque" }
            LOD 100

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2g vert (appdata v)
            {
                v2g o;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            fixed4 frag (v2g i) : SV_Target
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
    }
}
// shader basics learned from: https://www.youtube.com/watch?v=4XfXOEDzBx4&ab_channel=WorldofZero
// geom shader learned from: https://gamedevbill.com/unity-vertex-shader-and-geometry-shader-tutorial/ 

