#ifndef CHARACTER_DEPTH_NORMALS_PASS_INCLUDED
#define CHARACTER_DEPTH_NORMALS_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

struct DepthNormalsAttributes
{
    float4 positionOS : POSITION;
    float3 normalOS   : NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct DepthNormalsVaryings
{
    float4 positionCS : SV_POSITION;
    float3 normalWS   : TEXCOORD0;
    UNITY_VERTEX_OUTPUT_STEREO
};

DepthNormalsVaryings DepthNormalsVertex(DepthNormalsAttributes input)
{
    DepthNormalsVaryings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.normalWS   = TransformObjectToWorldNormal(input.normalOS);
    return output;
}

half4 DepthNormalsFragment(DepthNormalsVaryings input) : SV_TARGET
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    float3 normalWS = NormalizeNormalPerPixel(input.normalWS);
    // Encode view-space normal using oct encoding, matching URP's _CameraNormalsTexture format
    return half4(PackNormalOctRectEncode(TransformWorldToViewDir(normalWS, true)), 0.0, 0.0);
}

#endif // CHARACTER_DEPTH_NORMALS_PASS_INCLUDED
