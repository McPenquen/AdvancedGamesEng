Shader "Unlit/GLSLShader"
{
    SubShader
    {
        Pass
        {
            GLSLPROGRAM
            // Vertex Shader
            #ifdef VERTEX 

            void main() 
            {
                gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
            }
            #endif

            // Fragment shader
            #ifdef FRAGMENT 

            void main() 
            {
                gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0); 
            }
            #endif 
            ENDGLSL
        }
    }
}
