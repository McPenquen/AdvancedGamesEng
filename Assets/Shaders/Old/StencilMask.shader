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
        ZWrite off

        Stencil
        {
            Ref 1
            Comp NotEqual
            Pass replace
        }

    
            CGINCLUDE
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
            
            Pass
            {
                Cull Front
                ZTest Less

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                ENDCG
            }
            Pass
            {
                Cull Back
                ZTest Greater

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                ENDCG
            }        
    }
}
