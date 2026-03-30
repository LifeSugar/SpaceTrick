Shader "Hidden/Rift/CopyDepth"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "CopyDepth"
            ZWrite On       
            ZTest Always    
            ColorMask 0     
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl" 

            float Frag(Varyings input) : SV_Depth
            {
                float depth = SampleSceneDepth(input.texcoord);
                return depth;
            }
            ENDHLSL
        }
    }
}