Shader "Custom/GrabInnerDepth"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        // 关闭深度写入把深度渲染到一张自定义的 Color RT 上
        ZWrite Off
        ZTest Always
        Cull Off

        Pass
        {
            Name "GrabInnerDepth"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            TEXTURE2D_X_FLOAT(_CameraDepthAttachment);
            SAMPLER(sampler_CameraDepthAttachment);

            half4 Frag(Varyings input) : SV_Target
            {
                float rawDepth = SAMPLE_TEXTURE2D_X(_CameraDepthAttachment, sampler_CameraDepthAttachment, input.texcoord).r;

                // float linearDepth = Linear01Depth(rawDepth, _ZBufferParams);


                return half4(rawDepth, 0, 0, 1);
            }
            ENDHLSL
        }
    }
}