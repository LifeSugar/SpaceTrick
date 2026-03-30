Shader "Hidden/Custom/WriteStencil_Blitter"
{
    Properties
    {
        // 全局 RT 不需要在这里声明，只需要保留控制阈值即可
        _Threshold ("B Channel Threshold", Range(0.0, 1.0)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }

        Pass
        {
            Name "WriteStencilBlitter"
            
            ColorMask 0
            ZWrite Off
            ZTest Always

            Stencil
            {
                Ref 14
                Comp Always
                Pass Replace
            }

            HLSLPROGRAM
            #pragma vertex Vert 
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl" 

            // 【关键修改】直接在 HLSL 中声明你的全局 RT 和采样器
            TEXTURE2D(_RiftMaskRT);
            SAMPLER(sampler_RiftMaskRT);
            
            float _Threshold;

            half4 frag(Varyings input) : SV_Target
            {
                // 采样你的 RiftMaskRT
                half4 col = SAMPLE_TEXTURE2D(_RiftMaskRT, sampler_RiftMaskRT, input.texcoord);

                // 根据 b 通道的值进行剔除 (如果 b < 0.5 则丢弃，不写入 Stencil)
                clip(col.b - _Threshold);

                return half4(0, 0, 0, 0); 
            }
            ENDHLSL
        }
    }
}