//*********************************************************************************
// Filename:  SkyBox.shader
// Author:    XDT Graphics Team
// Date:      2025-07-23
//
// Description:
//   This shader renders a physically-inspired, feature-rich skybox for an environment,
//   supporting gradient sky, sun, moon, stars, and dynamic clouds with SDF-based blending,
//   fog, and various artistic controls. It is designed for the Universal Render Pipeline.
//
//*********************************************************************************

Shader "XDT/Environment/SkyBox"
{
    Properties
    {
        // Cloud color controls near and far from the sun
        _CloudRimColorNearSun("Cloud Bright Color Near Sun", Color) = (0.7529424, 0.8468735, 0.9911022, 1) // Rim color for clouds near the sun.
        _CloudBrightColorNearSun("Cloud Bright Color Near Sun", Color) = (0.7529424, 0.8468735, 0.9911022, 1) // Bright color for clouds near the sun.
        _CloudDarkColorNearSun("Cloud Bright Color Near Sun", Color) = (0.7529424, 0.8468735, 0.9911022, 1) // Dark color for clouds near the sun.
        _CloudRimColorFarSun("Cloud Rim Color Far Sun", Color) = (0.7529424, 0.8468735, 0.9911022, 1) // Rim color for clouds far from the sun.
        _CloudBrightColorFarSun("Cloud Bright Color Far Sun", Color) = (0.7529424, 0.8468735, 0.9911022, 1) // Bright color for clouds far from the sun.
        _CloudDarkColorFarSun("Cloud Bright Color Far Sun", Color) = (0.7529424, 0.8468735, 0.9911022, 1) // Dark color for clouds far from the sun.
        [NoScaleOffset]_CloudWrinkleNoise("Cloud Wrinkle Noise", 2D) = "gray" {} // Small-scale cloud detail noise
        _CloudWrinkleSpeed("Cloud Wrinkle Speed", Range(-0.2, 0.2)) = 0.0        // Speed of wrinkle movement
        _CloudWrinkleTiling("Cloud Wrinkle Tiling", Range(1.0, 14.0)) = 7.0      // Tiling of wrinkle noise
        _CloudWrinkleStrength("Cloud Wrinkle Strength", Range(0.0, 0.020)) = 0.008 // Intensity of wrinkle effect

        // Gradient sky colors and blending controls
        _GradientSkyUpperColor("Sky Top Color", Color) = (.47, .45, .75, 1)            // Color of sky zenith
        _GradientSkyMiddleColor("Sky Middle Color", Color) = (1, 1, 1, 1)              // Middle gradient color
        _GradientSkyLowerColor("Sky Lower Color", Color) = (.7, .53, .69, 1)           // Horizon color
        _GradientSkyDawnColor("Sky Dawn Color", Color) = (1.0, 0.441, 0.0, 1.0)        // Dawn color
        _GradientFadeBegin("Horizon Fade Begin", Range(-1, 1)) = -.179                 // Start of horizon fade
        _GradientFadeEnd("Horizon Fade End", Range(-1, 1)) = .302                      // End of horizon fade
        _GradientFadeMiddlePosition("Horizon Fade Middle Position", Range(0, 1)) = .5  // Middle gradient position
        _GradientSmoothWidth("Gradient Smooth Width", Range(0.0, 1)) = 0.2             // Gradient smoothness
        _GradientSmoothWidthTop("Gradient Smooth Width Top",Range(0.0, 1)) = 0.2       // Top gradient smoothness

        // Sun controls
        _SunRimColor("Sun Rim Color", Color) = (.66, .65, .55, 1)                    // Sun rim tint
        _SunScatterSize("Sun Scatter Size", Range(0.1, 10)) = 1                      // Sun scattering radius
        _SunBodySize("Sun Body Size", Range(0.15, 10)) = 1                           // Sun body radius
        _SunEdgeFade("Sun Edge Feathering", Range(0.0001, .9999)) = .3               // Sun edge softness
        _SunRimSize("Sun Rim Size", Range(1, 10)) = 1                                // Sun rim size for HDR
        _SunDawnSize("Sun Dawn Size", Range(0.16, 1.0)) = 0.8                        // Sun dawn size
        _SunTotalColor("Sun Total Color", Color) = (1.0, 1.0, 1.0, 1.0)              // Sun total color
        _SunScatterStrength("Sun Scatter Strength", Range(0.0, 0.7)) = 0.618         // Sun scattering intensity
        _SunScatterColor("Sun Scatter Color", Color) = (1.0, 0.8944, 0.76, 1.0)      // Sun scatter color

        // Moon controls
        [NoScaleOffset]_MoonTex("Moon Texture", 2D) = "white" {}                     // Moon texture
        _MoonColor("Moon Color", Color) = (.66, .65, .55, 1)                         // Moon tint
        _MoonBodyBrightness("Moon Body Brightness", Range(0.0, 2.0)) = 1.2           // Moon brightness
        _MoonRadius("Moon Size", Range(0, 1)) = .1                                   // Moon radius
        _MoonScatterSize("Moon Scatter Size", Range(0, 10)) = 1.5                    // Moon scattering size
        _MoonEdgeFade("Moon Edge Feathering", Range(0.0001, .9999)) = .3             // Moon edge softness
        _MoonHDRBoost("Moon Body Size", Range(1, 10)) = 1                            // Moon HDR bloom boost
        _MoonTotalColor("Moon Total Color", Color) = (0.8980392, 0.8980392, 0.8980392, 1.0) // Moon total color
        _MoonScatterStrength("Moon Scatter Strength", Range(0.0, 0.7)) = 0.618       // Moon scatter strength
        _MoonScatterColor("Moon Scatter Color", Color) = (0.8944, 0.8944, 1.0, 1.0)  // Moon scatter color
        _MoonSpriteDimensions("Moon Sprite Dimensions", Vector) = (0, 0, 0, 0)       // Moon sprite sheet cols/rows
        _MoonSpriteItemCount("Moon Sprite Total Items", int) = 1                     // Moon sprite sheet count
        _MoonSpriteAnimationSpeed("Moon Sprite Speed", int) = 1                      // Moon sprite animation speed

        // Star controls
        [HDR]_StarColor("Star Color",Color) = (1,1,1,1)                              // Star color
        [HDR]_StarColor2("Star Color2",Color) = (1,1,1,1)                            // Secondary star color
        _StarMask("Star Mask", 2D) = "white" {}                                      // Star mask texture
        _starMin("Star Far Scale",Range(0.1,3)) = 1                                  // Star scale (far)
        _starMax("Star Near Scale",Range(0.1,3)) = 1                                 // Star scale (near)
        _StarAlpha("Star Aplha",Range(0,1)) = 1                                      // Star alpha

        // Cloud controls
        _CloudTex("Cloud Texture", 2D) = "black" {}                                  // Dynamic cloud texture
        _CloudThickness("Cloud Thick",2D) = "black"{}                                // Cloud thickness map
        _CloudSDF("Cloud SDF",2D) = "white"{}                                        // Cloud SDF for blending
        _CloudMap("Cloud Map",2D) = "white"{}                                        // Static cloud map
        _CloudThicknessMap("Cloud Thickness Map",2D) = "white"{}                     // Static cloud thickness

        _CloudRotationOffset("Cloud Rotation Offset",float) = 0                      // Cloud rotation offset
        _CloudFadingWidth("Cloud Fading Width",Range(0,0.3)) = 0.3                   // Cloud fade width
        _DynamicCloudThreshold("Dynamic Cloud Threshold",Range(0,1)) = 0             // Dynamic cloud SDF threshold
        _DynamicCloudSmoothDelta("Dynamic Cloud SmoothDelta",Range(0,1)) = 0.05      // SDF smoothness
        _CloudFadingThresholdR("CloudFadingThresholdR",Range(0,2)) = 0               // Red channel fade threshold
        _CloudFadingThresholdG("CloudFadingThresholdG",Range(0,2)) = 0               // Green channel fade threshold
        _CloudFadingThresholdB("CloudFadingThresholdB",Range(0,2)) = 0               // Blue channel fade threshold
        _CloudFadingThresholdAnimal("CloudFadingThresholdAnimal",Range(0,2)) = 0     // Animal channel fade threshold

        _RX("RX",Range(0,1)) = 0                                                     // Cloud UV X offset
        _RY("RY",Range(0,0.1)) = 0                                                   // Cloud UV Y offset
        _RotationSpeed("Rotation Speed",Range(0,0.1)) = 0.005                        // Cloud rotation speed

        // Fog controls
        _HorizonFogColor("Fog Color", Color) = (1, 1, 1, 1)                          // Fog color
        _HorizonFogDensity("Fog Density", Range(0, 20)) = 20                         // Fog density
        _HorizonFogLength("Fog Height", Range(.03, 1)) = .1                          // Fog height
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue"="Geometry" }
        Cull back
        ZWrite Off
        LOD 100

        HLSLINCLUDE
        #pragma target 3.0
        ENDHLSL

        Pass
        {
            Name "Forward"
            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex vert
            #pragma fragment frag
            #include "Library/cloudInputs.hlsl"

            float _RX; // Cloud UV X offset (runtime)
            float _RY; // Cloud UV Y offset (runtime)
            half _starMin; // Star field scale at horizon
            half _starMax; // Star field scale at zenith
            half4 _SDFMask; // SDF mask for dynamic cloud blending

            //---------------------------------------------------------------------------------
            // Vertex input structure for the skybox.
            //---------------------------------------------------------------------------------
            struct Attributes {
                float4 positionOS   : POSITION;    // Object-space position of the vertex.
                float2 uv           : TEXCOORD0;   // Primary UV coordinates.
                float4 color        : COLOR;       // Vertex color (unused).
            };

            //---------------------------------------------------------------------------------
            // Interpolator structure passed from vertex to fragment shader.
            //---------------------------------------------------------------------------------
            struct Varyings {
                float4 positionCS   : SV_POSITION;     // Clip-space position.
                float4 uv           : TEXCOORD0;       // UVs for sampling textures.
                float3 positionWS   : TEXCOORD2;       // World-space position.
                float3 smoothVertex : TEXCOORD3;       // Smoothed/normalized vertex position (for sky calculations).
                float3 positionMoonOS : TEXCOORD4;     // Moon local-space position (for moon UV lookup).
                half4 backGroudColor : TEXCOORD5;      // Precomputed background color (gradient).
            };

            /**
             * @brief Vertex shader for skybox rendering. Computes world/clip positions, 
             *        prepares data for gradient, sun, moon, and cloud calculations.
             * @param IN The input vertex attributes.
             * @return The interpolated data for the fragment shader.
             */
            Varyings vert(Attributes IN) 
            {
                Varyings OUT = (Varyings)0;

                // Compute world and clip-space positions.
                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = positionInputs.positionCS;

                #if UNITY_UV_STARTS_AT_TOP
                OUT.positionCS.z = 0; // For platforms where UV origin is top-left, set z to 0 for skybox depth.
                #else
                OUT.positionCS.z = OUT.positionCS.w;
                #endif

                OUT.positionWS = positionInputs.positionWS;

                OUT.smoothVertex = IN.positionOS.xyz;
                float3 normalizedVertex = normalize(IN.positionOS.xyz);

                // Transform normalized vertex to moon local space for moon UV lookup.
                OUT.positionMoonOS = mul(_MoonWorldToLocalMat, float4(normalizedVertex, 1.0)).xyz;

                // Flip X UV for correct sky orientation.
                OUT.uv.xy = float2(1 - IN.uv.x, IN.uv.y);

                // Compute horizontal distance to sun for gradient blending.
                float horizontalDistToSun = distance(_SkyWaterSunPosition.xz, IN.positionOS.xz);

                // Precompute the 3-way gradient background color at this vertex.
                OUT.backGroudColor = Calculate3WayGradientBackgroundAtPosition(IN.positionOS.xyz, horizontalDistToSun, _SkyWaterSunPosition.xyz);

                return OUT;
            }

            /**
             * @brief Fragment shader for the skybox. Composes the sky color by blending
             *        gradient, sun, moon, stars, and clouds, applying fog and SDF-based cloud blending.
             * @param IN The interpolated data from the vertex shader.
             * @return The final skybox color for this pixel.
             */
            half4 frag(Varyings IN) : SV_Target
            {
                // Compute normalized view direction from world-space position.
                half3 viewDir = SafeNormalize(IN.positionWS);

                half4 backGroudColor = half4(0,0,0,0);
                float horizontalDistToSun = distance(_SkyWaterSunPosition.xz, IN.smoothVertex.xz);

                // Use precomputed background color, then refine with gradient.
                backGroudColor = IN.backGroudColor;
                backGroudColor = Calculate3WayGradientBackground(backGroudColor, IN.smoothVertex.xyz);

                half scatteredArea = 0;
                half diffusedSun = 0;
                float3 normalizedSmoothVertex = normalize(IN.smoothVertex);
                half sunCosTheta = dot(viewDir, _SkyWaterSunPosition.xyz);
                half4 sunColor = half4(0,0,0,0);
                half moonExtinction = saturate((viewDir.y) * 2.5); // Fade moon near horizon.

                half3 posToCloud = _SkyWaterSunPosition.xyz;

                // Render sun if enabled and scattering is significant.
                UNITY_BRANCH
                if(_SunScatterStrength > 0.05)
                {
                    if(_Quality > 0)
                    {
                        // High quality: physically-inspired sun with scattering and rim.
                        sunColor = OrbitBodyColorNoTexture(
                            normalizedSmoothVertex,
                            _SkyWaterSunPosition.xyz,
                            _SunRimColor,
                            _SunScatterSize,
                            _SunBodySize,
                            _SunRimSize,
                            _SunScatterStrength,
                            _SunScatterColor,
                            _SunTotalColor,
                            _SunDawnSize,
                            backGroudColor,
                            scatteredArea,
                            diffusedSun);
                    }
                    else
                    {
                        // Low quality: simple sun rendering.
                        sunColor = OrbitBodyColorSimple(
                            normalizedSmoothVertex,
                            _SkyWaterSunPosition.xyz,
                            _SunRimColor,
                            _SunBodySize,
                            _SunRimSize,
                            _SunTotalColor,
                            _SunDawnSize,
                            diffusedSun);
                    }
                }

                half4 moonColor = half4(0,0,0,0);
                half moonCosTheta = dot(viewDir, _MoonPosition.xyz);

                // Render moon if enabled and bright enough.
                if(_MoonBodyBrightness > 0.05)
                {
                    // Convert moon local position to UV for sprite/texture lookup.
                    float2 moonUV = ConvertLocalPointToUV(IN.positionMoonOS.xy, _MoonRadius * 2.0);
                    posToCloud = _MoonPosition.xyz;

                    if(_Quality > 0)
                    {
                        // High quality: moon with scattering and texture.
                        moonColor = OrbitBodyColorWithTextureUV(
                            normalizedSmoothVertex,
                            _MoonPosition.xyz,
                            _MoonColor,
                            _MoonRadius,
                            _MoonEdgeFade,
                            moonUV,
                            _MoonScatterSize,
                            _MoonScatterStrength,
                            _MoonScatterColor,
                            _MoonBodyBrightness,
                            moonCosTheta);
                    }
                    else
                    {
                        // Low quality: simple moon with texture.
                        moonColor = OrbitBodyColorWithTextureUVSimple(
                            normalizedSmoothVertex,
                            _MoonPosition.xyz,
                            _MoonColor,
                            _MoonRadius,
                            _MoonEdgeFade,
                            moonUV,
                            _MoonBodyBrightness);
                    }

                    // Fade moon near horizon.
                    moonColor *= moonExtinction;
                }

                half3 starFinalColor = half3(0,0,0);

                // Render stars if enabled.
                if(_StarAlpha > 0.05)
                {
                    float2 uv = IN.smoothVertex.xz + 0.5;
                    half lerpT = smoothstep(0,1,normalizedSmoothVertex.y); // Fade stars toward zenith.
                    uv *= lerp(_starMin, _starMax, lerpT); // Scale star field based on elevation.
                    half4 mask = SAMPLE_TEXTURE2D(_StarMask, sampler_StarMask, uv);
                    half starsdf = smoothstep(0, 0.55, mask.r); // SDF for star shape.

                    if(_Quality >= 1)
                    {
                        // Animate star brightness for twinkle effect.
                        half starRandom = sin(_Time.y * 2 + UNITY_TWO_PI * IN.smoothVertex.x) * 0.5 + 0.5;
                        starFinalColor = lerp(_StarColor.rgb, _StarColor2.rgb, starsdf) * (1-starsdf) * lerp(0.2,1,starRandom) * lerpT * _StarAlpha;
                    }
                    else
                    {
                        // Static star color.
                        starFinalColor = lerp(_StarColor.rgb, _StarColor2.rgb, starsdf) * (1-starsdf) * lerpT * _StarAlpha;
                    }
                }

                // Add moon, stars, and sun to the background color.
                backGroudColor.rgb += moonColor.rgb;
                backGroudColor.rgb += starFinalColor.rgb;
                backGroudColor.rgb += sunColor.rgb;

                float2 sampleOffset = float2(0,0);

                // Compute distance to sun/moon for cloud lighting.
                half distToSun = saturate(distance(posToCloud, normalizedSmoothVertex) * (1 - _SunRange));
                distToSun = smoothstep(0.1, 1, distToSun);

                // Add wrinkle noise to clouds for high quality.
                if(_Quality >= 2)
                {
                    float2 wrinkleOffset = float2(_Time.y * _CloudWrinkleSpeed, 0.0);
                    sampleOffset = (SAMPLE_TEXTURE2D(_CloudWrinkleNoise, sampler_CloudWrinkleNoise, IN.uv.xy * _CloudWrinkleTiling - wrinkleOffset).xy - 0.5) * _CloudWrinkleStrength * 0.5;
                }

                half2 rotation = half2(_Time.x * _RotationSpeed, 0);
                float2 r = float2(_RX, _RY);

                // Sample static cloud color map with offset and rotation.
                half4 cloudColorMap = SAMPLE_TEXTURE2D(_CloudMap, sampler_CloudMap, IN.uv.xy + sampleOffset * 0.5 - r - rotation);

                half4 cloudOrigin = half4(0,0,0,0);
                half4 cloudVoidColor = half4(0,0,0,0);

                // Render static clouds with thickness and void blending.
                if(_Quality >= 1)
                {
                    half4 cloudThickness = SAMPLE_TEXTURE2D(_CloudThicknessMap, sampler_CloudThicknessMap, IN.uv.xy + sampleOffset * 0.5 - r - rotation);
                    cloudOrigin = RenderCloudColorOrigin(cloudColorMap, cloudThickness, distToSun, diffusedSun, backGroudColor);
                    cloudVoidColor = RenderCloudColorVoid(cloudThickness.a, distToSun, diffusedSun);
                    backGroudColor = AlphaBlend(cloudVoidColor, backGroudColor);
                }
                else
                {
                    // Simple static cloud rendering.
                    cloudOrigin = RenderCloudColorOriginSimple(cloudColorMap, distToSun, diffusedSun);
                }

                // Blend static clouds over the background.
                backGroudColor = AlphaBlend(cloudOrigin, backGroudColor);

                // Dynamic SDF-based cloud blending if enabled.
                if(_DynamicCloudThreshold < 0.995)
                {
                    float2 dnyCloudUV = IN.uv.xy + sampleOffset * float2(0.1,2) - rotation;

                    half4 cloud0 = SAMPLE_TEXTURE2D(_CloudTex, sampler_CloudTex, dnyCloudUV);
                    half4 sdf = SAMPLE_TEXTURE2D(_CloudSDF, sampler_CloudSDF, dnyCloudUV);

                    half sdfValue = 0;
                    half alphaValue = cloud0.r;
                    half4 sdfLerp;

                    // Compute SDF lerp thresholds for each channel based on SDF mask.
                    half invMaxA = _SDFMask.a > 0 ? 0.25 : 0;
                    half invMaxB = _SDFMask.b > 0 ? 0.5 : 0;
                    half invMaxG = _SDFMask.g > 0 ? 0.75 : 0;

                    half cloudDis = distance(viewDir.xz, half2(0,0));
                    cloudDis = pow(cloudDis, 2);

                    // Compute SDF lerp values for each channel.
                    sdfLerp.r = invLerp(0, 1 - max(invMaxA, max(invMaxB, invMaxG)), _DynamicCloudThreshold);
                    sdfLerp.g = invLerp(0.25, 1 - max(invMaxB, invMaxA), _DynamicCloudThreshold);
                    sdfLerp.b = invLerp(0.5, 1 - invMaxA, _DynamicCloudThreshold);
                    sdfLerp.a = invLerp(0.75, 1.0, _DynamicCloudThreshold);

                    // Smoothstep for SDF blending.
                    sdfLerp.r = smoothstep(0, cloudDis, sdfLerp.r);
                    sdfLerp.g = smoothstep(0, cloudDis, sdfLerp.g);
                    sdfLerp.b = smoothstep(0, cloudDis, sdfLerp.b);
                    sdfLerp.a = smoothstep(0, cloudDis, sdfLerp.a);

                    half4 fadeLerp;
                    // Calculate fade for each SDF channel.
                    fadeLerp.r = CalcFade(sdfLerp.r, sdf.r, _DynamicCloudSmoothDelta, cloud0.r, _DynamicCloudThreshold) * _SDFMask.r;
                    fadeLerp.g = CalcFade(sdfLerp.g, sdf.g, _DynamicCloudSmoothDelta, cloud0.g, _DynamicCloudThreshold) * _SDFMask.g;
                    fadeLerp.b = CalcFade(sdfLerp.b, sdf.b, _DynamicCloudSmoothDelta, cloud0.b, _DynamicCloudThreshold) * _SDFMask.b;
                    fadeLerp.a = CalcFade(sdfLerp.a, sdf.a, _DynamicCloudSmoothDelta, cloud0.a, _DynamicCloudThreshold) * _SDFMask.a;

                    // Use the maximum fade across channels.
                    half fade = max(max(fadeLerp.r, fadeLerp.g), max(fadeLerp.b, fadeLerp.a));

                    // Blend SDF and alpha values across channels for smooth cloud edges.
                    sdfValue = lerp(sdf.r, sdf.g, sdfLerp.r);
                    sdfValue = lerp(sdfValue, sdf.b, sdfLerp.g);
                    sdfValue = lerp(sdfValue, sdf.a, sdfLerp.b);
                    alphaValue = lerp(cloud0.r, cloud0.g, sdfLerp.r);
                    alphaValue = lerp(alphaValue, cloud0.b, sdfLerp.g);
                    alphaValue = lerp(alphaValue, cloud0.a, sdfLerp.b);

                    float finalSdf = sdf.r * 0.25 + sdf.g * 0.25 + sdf.b * 0.25 + sdf.a * 0.25;

                    // Sample thickness for dynamic cloud SDF.
                    half2 thickness0 = SAMPLE_TEXTURE2D(_CloudThickness, sampler_CloudThickness, float2(1-sdfValue, _DynamicCloudThreshold)).rg;
                    half4 cloudParameter0 = half4(thickness0.r, thickness0.g, 0, alphaValue);

                    // Render dynamic cloud color with SDF fade.
                    half4 cloudColor0 = RenderCloudColor(cloudParameter0, distToSun, diffusedSun, _DynamicCloudThreshold, sdfValue, _DynamicCloudSmoothDelta, fade);

                    // Add rim lighting to clouds near the sun.
                    half smooth = smoothstep(_CloudRimThresholdMin, _CloudRimThresholdMax, thickness0.r);
                    smooth *= smooth;
                    cloudColor0.rgb += _CloudRimColorNearSun.rgb * smooth * _CloudRimInstensity * 3 * distToSun;

                    // Blend dynamic clouds over the background.
                    backGroudColor = AlphaBlend(cloudColor0, backGroudColor);
                }

                // Set alpha to sun's alpha for correct blending.
                backGroudColor.a = sunColor.a;

                // Apply horizon fog for atmospheric depth.
                backGroudColor = ApplyHorizonFog(backGroudColor, IN.smoothVertex, scatteredArea, horizontalDistToSun, _SkyWaterSunPosition.xyz);

                return backGroudColor;
            }

            ENDHLSL
        }
    }
}
