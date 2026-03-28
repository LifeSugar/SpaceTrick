#ifndef CHARACTER_SHADOW_CASTER_PASS_INCLUDED
#define CHARACTER_SHADOW_CASTER_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

// Provided by URP shadow caster keywords
float3 _LightDirection;
float3 _LightPosition;

struct ShadowCasterAttributes
{
    float4 positionOS : POSITION;
    float3 normalOS   : NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct ShadowCasterVaryings
{
    float4 positionCS : SV_POSITION;
};

float4 GetCharacterShadowPositionHClip(ShadowCasterAttributes input)
{
    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    float3 normalWS   = TransformObjectToWorldNormal(input.normalOS);

#if _CASTING_PUNCTUAL_LIGHT_SHADOW
    float3 lightDirectionWS = normalize(_LightPosition - positionWS);
#else
    float3 lightDirectionWS = _LightDirection;
#endif

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#endif

    return positionCS;
}

ShadowCasterVaryings ShadowPassVertex(ShadowCasterAttributes input)
{
    ShadowCasterVaryings output;
    UNITY_SETUP_INSTANCE_ID(input);
    output.positionCS = GetCharacterShadowPositionHClip(input);
    return output;
}

half4 ShadowPassFragment(ShadowCasterVaryings input) : SV_TARGET
{
    return 0;
}

#endif // CHARACTER_SHADOW_CASTER_PASS_INCLUDED
