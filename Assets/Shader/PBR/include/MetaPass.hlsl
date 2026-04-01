#ifndef CHARACTER_META_PASS_INCLUDED
#define CHARACTER_META_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

struct MetaAttributes
{
    float4 positionOS : POSITION;
    float2 uv0        : TEXCOORD0;
    float2 uv1        : TEXCOORD1;
    float2 uv2        : TEXCOORD2;
};

struct MetaVaryings
{
    float4 positionCS : SV_POSITION;
    float2 uv         : TEXCOORD0;
};

MetaVaryings UniversalVertexMeta(MetaAttributes input)
{
    MetaVaryings output;
    output.positionCS = UnityMetaVertexPosition(input.positionOS.xyz, input.uv1, input.uv2);
    output.uv         = TRANSFORM_TEX(input.uv0, _BaseMap);
    return output;
}

half4 UniversalFragmentMetaLit(MetaVaryings input) : SV_TARGET
{
    half4 albedoAlpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;

    MetaInput metaInput;
    metaInput.Albedo   = albedoAlpha.rgb;
    metaInput.Emission = half3(0, 0, 0);

    return MetaFragment(metaInput);
}

#endif // CHARACTER_META_PASS_INCLUDED
