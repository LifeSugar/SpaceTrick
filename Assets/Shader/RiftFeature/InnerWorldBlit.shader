Shader "Hidden/InnerWorldBlit"
{
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "InnerWorldBlit"
            Cull Off
            ZWrite Off
            ZTest Always
            Blend SrcAlpha OneMinusSrcAlpha

            Stencil
            {
                Ref 14
                Comp Equal
                Pass Keep
                Fail Keep
                ZFail Keep
            }

            HLSLPROGRAM
            

            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #pragma vertex Vert
            #pragma fragment Frag

            TEXTURE2D_FLOAT(_InnerWorldDepth);
            SAMPLER(sampler_InnerWorldDepth);
            float4 _InnerWorldZBufferParams;

            half4 Frag(Varyings input) : SV_Target
            {
                float2 screenUV = input.texcoord;

                // 采样内世界深度，用内世界相机参数线性化
                float innerRaw = SAMPLE_TEXTURE2D(_InnerWorldDepth, sampler_InnerWorldDepth, screenUV).r;
                float innerLinear = 1.0 / (_InnerWorldZBufferParams.z * innerRaw + _InnerWorldZBufferParams.w);

                // 采样主相机深度并线性化
                float cameraRaw = SampleSceneDepth(screenUV);
                float cameraLinear = LinearEyeDepth(cameraRaw, _ZBufferParams);

                // LEqual：内世界更近或相等才绘制
                clip(cameraLinear - innerLinear);

                half4 color = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, screenUV);
                return color;
            }
            ENDHLSL
        }
    }
}
