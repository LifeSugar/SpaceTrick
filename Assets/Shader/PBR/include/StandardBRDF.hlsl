#ifndef STANDARD_BRDF_HLSL
#define STANDARD_BRDF_HLSL

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

// Pow5 helper (Common.hlsl provides Sq and Pow4)
half Pow5(half x)
{
    half x2 = Sq(x);
    return x * Sq(x2);
}

half3 BRDFDiffuseColor(half3 Albedo, half Metallic)
{
    return Albedo * (1.0 - Metallic);
}
half3 BRDFSpecularColor(half3 Albedo, half Metallic, half Specular)
{
    // return lerp(half3(0.04, 0.04, 0.04), Albedo, Metallic);
    return lerp(half3(0.08, 0.08, 0.08) * Specular, Albedo, Metallic);
}
half avoidZero(half x)
{
    return max(x, 0.0001);
}


//GGX分布 UE4实现
half D_GGX_UE4(half a2, half NoH)
{
    half NoH2 = Sq(NoH);
    half denom = NoH2 * (a2 - 1.0) + 1.0;
    return a2 / (3.141592653 * avoidZero(Sq(denom)));
}

//Smith几何遮蔽 标准
half Vis_SmithJoint(half a2, half NoV, half NoL)
{
    half Vis_SmithV = NoL * sqrt(a2 + (1.0 - a2) * Sq(NoV));
    half Vis_SmithL = NoV * sqrt(a2 + (1.0 - a2) * Sq(NoL));
    return 0.5 / avoidZero(Vis_SmithV + Vis_SmithL);
}

//Smith几何遮蔽 lerp拟合
half Vis_SmithJointApprox(half a2, half NoV, half NoL)
{
    half a = sqrt(a2);
    half Vis_SmithV = NoL * (NoV * (1.0 - a) + a);
    half Vis_SmithL = NoV * (NoL * (1.0 - a) + a);
    return 0.5 / avoidZero(Vis_SmithV + Vis_SmithL);
}

half3 Fresnel_SchlickUE4(half VoH, half3 SpecularColor)
{
    half Fc = Pow5(1.0 - VoH);
    return saturate(50.0 * SpecularColor.g) * Fc + (1.0 - Fc) * SpecularColor;
}

half3 StandardBRDFDirect(half3 N, 
    half3 V, 
    half3 L, 
    half3 DiffuseColor, 
    half3 SpecularColor,
    half Metallic, 
    half Roughness,
    half3 LightColor,
    half Shadow)
{
    half a2 = Pow4(Roughness);
    half3 H = normalize(V + L);
    half NoV = avoidZero(saturate(dot(N, V)));
    half NoL = avoidZero(saturate(dot(N, L)));
    half NoH = avoidZero(saturate(dot(N, H)));
    half VoH = avoidZero(saturate(dot(V, H)));

    half3 Radiance = LightColor * Shadow;
    

    half D = D_GGX_UE4(a2, NoH);
    half G = Vis_SmithJointApprox(a2, NoV, NoL);
    half3 F = Fresnel_SchlickUE4(VoH, SpecularColor);
    half3 kD = (1.0h - F);   
    // half3 Diffuse = DiffuseColor / 3.141592653 * kD * NoL * Radiance ;
    half3 Diffuse = DiffuseColor * kD * NoL * Radiance ;
    half3 Specular = D * G * F * NoL * Radiance;


    return Diffuse + Specular;
}

half3 Fresnel_SchlickUE4Roughness(half NoV, half3 SpecularColor, half Roughness)
{
    half smoothness = 1.0 - Roughness;
    half3 maxF = max(SpecularColor, half3(smoothness, smoothness, smoothness));
    return SpecularColor + (maxF - SpecularColor) * pow(max(1.0 - NoV, 0.0), 5.0);
}

// 通过纯数学拟合获得 BRDF LUT 的 Scale(x) 和 Bias(y)
half2 GetEnvBRDFApprox(half Roughness, half NoV)
{
    half4 c0 = half4(-1.0, -0.0275, -0.572, 0.022);
    half4 c1 = half4(1.0, 0.0425, 1.04, -0.04);
    
    half4 r = Roughness * c0 + c1;
    half a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
    half2 AB = half2(-1.04, 1.04) * a004 + r.zw;
    
    return AB; // AB.x = Scale, AB.y = Bias
}

half3 StandardBRDFAmbient(
    half3 N,
    half3 V,
    half3 DiffuseColor,
    half3 SpecularColor,
    half Roughness,
    half occlusion,
    half3 IndirectIrradiance, //SH 或者lightmap中的漫反射环境光
    half3 PrefilteredColor, //预过滤环境光
    half2 EnvBRDF  //预过滤环境光的BRDF LUT
)
{
    half NoV = avoidZero(saturate(dot(N, V)));
    half3 F = Fresnel_SchlickUE4Roughness(NoV, SpecularColor, Roughness);
    half3 kD = (1.0h - F);
    half3 Diffuse = DiffuseColor * kD * IndirectIrradiance * occlusion; //pi 已经包含在
    half3 Specular = PrefilteredColor * (SpecularColor * EnvBRDF.x + EnvBRDF.y) * occlusion;

    return Diffuse + Specular;
}


#endif // STANDARD_BRDF_HLSL