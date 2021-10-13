// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/StencilMask"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent+5" "IgnoreProjector"="True"}
        ColorMask 0
        ZTest on

        Stencil
        {
            Ref 1
            Comp NotEqual
            Pass Replace
            Fail Keep
            Zfail Keep
            ReadMask 1
            WriteMask 1
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };
            
            float4 vert(appdata v) : POSITION 
            {
                return UnityObjectToClipPos(v.vertex);
            }

            fixed4 frag(float4 sp:WPOS) : COLOR 
            {
                return fixed4(1.0, 1.0, 1.0, 1.0);
            }
            ENDCG
        }
    }
}
