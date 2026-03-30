Shader "Custom/Skybox_CityPop_Cyber"
{
    Properties
    {
        [Header(Sky Colors)]
        _TopColor("Top Color", Color) = (0.05, 0.05, 0.2, 1)
        _MidColor("Middle Color", Color) = (0.8, 0.1, 0.5, 1)
        _BottomColor("Bottom Color", Color) = (1, 0.5, 0.2, 1)
        
        [Header(Retro Sun)]
        _SunColor("Sun Color", Color) = (1, 0.9, 0.2, 1)
        _SunDir("Sun Direction", Vector) = (0, 0, 1, 0)
        _SunSize("Sun Size", Range(0, 1)) = 0.15
        _SunSoftness("Sun Softness", Range(0, 0.1)) = 0.01
        _ScanlineFreq("Scanline Frequency", Float) = 20
        _ScanlineSpeed("Scanline Speed", Float) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Background" "Queue"="Background" "RenderPipeline" = "UniversalPipeline" }
        ZWrite Off
        Cull Off

        Stencil
        {
            Ref 14
            Comp Equal
            Pass Keep
        }      

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 viewDir : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _TopColor, _MidColor, _BottomColor, _SunColor;
                float4 _SunDir;
                float _SunSize, _SunSoftness, _ScanlineFreq, _ScanlineSpeed;
            CBUFFER_END

            Varyings vert (Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.viewDir = input.positionOS.xyz; 
                return output;
            }

            float4 frag (Varyings input) : SV_Target
            {
                float3 unitViewDir = normalize(input.viewDir);
                float y = unitViewDir.y;

                // --- 1. 背景渐变逻辑 ---
                // 使用 smoothstep 构建平滑的三色过渡
                float skyMask = smoothstep(-0.2, 0.8, y);
                float3 skyGradient = lerp(_MidColor.rgb, _TopColor.rgb, skyMask);
                float bottomMask = smoothstep(-0.5, 0.2, y);
                float3 finalSky = lerp(_BottomColor.rgb, skyGradient, bottomMask);

                // --- 2. 复古太阳逻辑 ---
                float3 sunD = normalize(_SunDir.xyz);
                float dist = 1.0 - dot(unitViewDir, sunD);
                
                // 太阳圆盘
                float sunAlpha = 1.0 - smoothstep(_SunSize, _SunSize + _SunSoftness, dist);
                
                // 水平切片效果 (Scanlines)
                // 在 viewDir 的 y 轴上施加正弦波
                float scanlines = sin(unitViewDir.y * _ScanlineFreq + _Time.y * _ScanlineSpeed);
                scanlines = smoothstep(-0.2, 0.5, scanlines); 
                
                // 只在太阳下半部分或整体应用切片
                float sunFinal = sunAlpha * scanlines;
                
                // --- 3. 混合输出 ---
                float3 color = lerp(finalSky, _SunColor.rgb, sunFinal);
                
                // 增加一点简单的地平线辉光
                float horizonGlow = pow(1.0 - abs(y), 10.0);
                color += _MidColor.rgb * horizonGlow * 0.5;

                return float4(color, 1.0);
            }
            ENDHLSL
        }
    }
}