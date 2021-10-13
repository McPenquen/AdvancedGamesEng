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
        //HLSLINCLUDE
        //    struct GeomData
        //    {
        //        float2 uv : TEXCOORD0;
        //        float4 vertex : SV_POSITION;
        //        float3 worldNormal : TEXCOORD1;
        //        float3 worldPosition : TEXCOORD2;     
        //    };
//
        //    [maxvertexcount(3)]
        //    void geom(triangle GeomData input[3], inout TriangleStream<GeomData> triStream)
        //    {
        //        GeomData vert0 = input[0];
        //        GeomData vert1 = input[1];
        //        GeomData vert2 = input[2];
//
        //        triStream.Append(vert0);
        //        triStream.Append(vert1);
        //        triStream.Append(vert2);
        //        triStream.RestartStrip();
        //    }
//
        //ENDHLSL
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            //#pragma geometry geom
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };

            struct v2g
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPosition : TEXCOORD2;
                UNITY_FOG_COORDS(1)
            };

            struct g2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPosition : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _LightSourcePosition;

            v2g vert (appdata v)
            {
                v2g o;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2g i) : SV_Target
            {
                // Calculate the amount of light falling on the 
                fixed3 lightDirection = normalize(i.worldPosition - _LightSourcePosition.xyz);
                fixed intensity = - dot(lightDirection, i.worldNormal);
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _Color * intensity;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
// learned from: https://www.youtube.com/watch?v=4XfXOEDzBx4&ab_channel=WorldofZero