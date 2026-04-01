Shader "Custom/Standard"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _BaseMap("Base Map", 2D) = "white" {}
        _NormalMap("Normal Map", 2D) = "bump" {}
		_DetailNormalMap("Detail Normal Map", 2D) = "bump" {}
		_DetailNormalScale("Detail Normal Scale", Range(0,2)) = 1.0
        _Metallic("Metallic", Range(0,1)) = 0.0
        _MetallicMap("Metallic Map", 2D) = "white" {}
        _Roughness("Roughness", Range(0,1)) = 1
        _RoughnessMap("Roughness Map", 2D) = "white" {}
        _Specular("Specular", Range(0, 1)) = 0.5
        _OcclusionStrength("Occlusion Strength", Range(0,1)) = 1.0
        _OcclusionMap("Occlusion Map", 2D) = "white" {}
        [HDR] _EmissionColor("Emission Color", Color) = (0,0,0,1)
        _EmissionMap("Emission Map", 2D) = "black" {}

    }

	SubShader
	{
		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

		TEXTURE2D(_BaseMap);      SAMPLER(sampler_BaseMap);
		TEXTURE2D(_NormalMap);    SAMPLER(sampler_NormalMap);
		TEXTURE2D(_DetailNormalMap); SAMPLER(sampler_DetailNormalMap);
		TEXTURE2D(_MetallicMap);  SAMPLER(sampler_MetallicMap);
		TEXTURE2D(_RoughnessMap); SAMPLER(sampler_RoughnessMap);
		TEXTURE2D(_OcclusionMap); SAMPLER(sampler_OcclusionMap);
		TEXTURE2D(_EmissionMap);  SAMPLER(sampler_EmissionMap);

		CBUFFER_START(UnityPerMaterial)
			float4 _BaseColor;
			float4 _BaseMap_ST;
			float4 _DetailNormalMap_ST;
			float  _DetailNormalScale;
			float  _Metallic;
			float4 _MetallicMap_ST;
			float  _Roughness;
			float4 _RoughnessMap_ST;
			float  _Specular;
			float  _OcclusionStrength;
			float4 _OcclusionMap_ST;
			float4 _EmissionColor;
			float4 _EmissionMap_ST;
		CBUFFER_END
		ENDHLSL

		Tags
		{
			"RenderType" = "Opaque"
			"RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "ignoreProjector" = "True"
		}
		LOD 300

		Pass
		{
			Name "ForwardLit"
			Tags
			{
				"LightMode" = "UniversalForward"
			}

			Cull Back
			ZTest LEqual
			ZWrite On
			

			

			HLSLPROGRAM
			#pragma target 2.0
			#pragma vertex ForwardLitVertex
			#pragma fragment ForwardLitFragment

			#include "./include/StandardBRDF.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			// Material Keywords
			
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _FORWARD_PLUS

			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _SHADOWS_SOFT

			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile_fragment _ _LIGHT_LAYERS
			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS // 上次提到的修复
			#pragma multi_compile_fog
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer

			struct Attributes
			{
				float4 positionOS : POSITION;
				float2 uv0 : TEXCOORD0;
				float2 staticLightmapUV : TEXCOORD1;

				float4 positionWS : TEXCOORD2;

                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID

				
			};

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;

				float3 normalWS : NORMAL;
				float3 tangentWS : TANGENT;
				float3 bitangentWS : TEXCOORD1;

				float3 positionWS : TEXCOORD2;
				DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 4);

				#if defined(_ADDITIONAL_LIGHTS_VERTEX)
				// When using vertex lighting for additional lights, we need to pass the world space position to the fragment shader to calculate the additional light directions
				half3 vertexLighting : TEXCOORD3;
				#endif

				float fogCoord : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			half3 BlendDetailNormal(half3 baseNormalTS, half3 detailNormalTS)
			{
				return normalize(half3(baseNormalTS.xy + detailNormalTS.xy, baseNormalTS.z * detailNormalTS.z));
			}

			Varyings ForwardLitVertex(Attributes input)
			{
				Varyings output = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
				VertexPositionInputs inputStruct = GetVertexPositionInputs(input.positionOS.xyz);
				VertexNormalInputs normalInputStruct = GetVertexNormalInputs(input.normalOS, input.tangentOS);

				output.positionHCS = inputStruct.positionCS;
				output.positionWS = inputStruct.positionWS;

				// Transform the normal, tangent, and bitangent to world space
				output.normalWS = normalInputStruct.normalWS;
				output.tangentWS = normalInputStruct.tangentWS;
				output.bitangentWS = normalInputStruct.bitangentWS;

				OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.lightmapUV);
				OUTPUT_SH(output.normalWS, output.vertexSH);

				output.uv = input.uv0;

				#if defined(_ADDITIONAL_LIGHTS_VERTEX)
        		output.vertexLighting = VertexLighting(inputStruct.positionWS, normalInputStruct.normalWS);
    			#endif

				output.fogCoord = ComputeFogFactor(inputStruct.positionCS.z);

				return output;
				
			}

			void ForwardLitFragment(Varyings input
				, out half4 outColor : SV_Target0
			#ifdef _WRITE_RENDERING_LAYERS
				, out float4 outRenderingLayers : SV_Target1
			#endif
			)
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
				half4 normalPacked = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv);
				half3 normalTangent = UnpackNormal(normalPacked);

				float2 detailNormalUV = TRANSFORM_TEX(input.uv, _DetailNormalMap);
				half3 detailNormalTangent = UnpackNormal(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailNormalUV));
				detailNormalTangent.xy *= _DetailNormalScale;
				detailNormalTangent.z = sqrt(saturate(1.0h - dot(detailNormalTangent.xy, detailNormalTangent.xy)));
				normalTangent = BlendDetailNormal(normalTangent, detailNormalTangent);

				half3x3 TBN = half3x3(input.tangentWS, input.bitangentWS, input.normalWS);
				half3 normalWS = normalize(TransformTangentToWorld(normalTangent, TBN));
				
				half3 viewDirWS = normalize(GetWorldSpaceViewDir(input.positionWS));
				half3 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).rgb * _BaseColor.rgb;
				half metallic = SAMPLE_TEXTURE2D(_MetallicMap, sampler_MetallicMap, input.uv).r * _Metallic;
				half roughness = SAMPLE_TEXTURE2D(_RoughnessMap, sampler_RoughnessMap, input.uv).r * _Roughness;
				half occlusion = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, input.uv).r;
				occlusion = lerp(1.0h, occlusion, _OcclusionStrength);
					half4 shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);

				// Build InputData
				InputData inputData = (InputData)0;
				inputData.positionWS = input.positionWS;
				inputData.normalWS = normalWS;
				inputData.viewDirectionWS = viewDirWS;
				inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
				inputData.normalizedScreenSpaceUV = input.positionHCS.xy / _ScaledScreenParams.xy;
				inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, normalWS);

				// Main light
				Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);

				// Mix realtime & baked GI — fixes Mixed-mode double-contribution and layer leak
				MixRealtimeAndBakedGI(mainLight, normalWS, inputData.bakedGI, shadowMask);

				half3 diffuseColor = BRDFDiffuseColor(baseColor, metallic);
				half3 specularColor = BRDFSpecularColor(baseColor, metallic, _Specular);

				// GI (uses mixed bakedGI)
				half3 reflectVector = reflect(-viewDirWS, normalWS);
				half3 prefilteredColor = GlossyEnvironmentReflection(reflectVector, roughness, occlusion);
				half2 envBRDF = GetEnvBRDFApprox(roughness, saturate(dot(normalWS, viewDirWS)));
				half3 GIColor = StandardBRDFAmbient(normalWS, viewDirWS, diffuseColor, specularColor, roughness, occlusion, inputData.bakedGI, prefilteredColor, envBRDF);

				// Rendering layer mask — shared by light layer filtering and layer MRT output
				#if defined(_LIGHT_LAYERS) || defined(_WRITE_RENDERING_LAYERS)
				uint meshRenderingLayers = GetMeshRenderingLayer();
				#endif

				// Main light direct (with layer filter)
				half3 directLightColor = 0;
				#ifdef _LIGHT_LAYERS
				if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
				#endif
				{
					directLightColor = StandardBRDFDirect(normalWS, viewDirWS, mainLight.direction, diffuseColor, specularColor, metallic, roughness, mainLight.color, mainLight.shadowAttenuation * mainLight.distanceAttenuation);
				}

				// Additional lights
				#if defined(_ADDITIONAL_LIGHTS) || defined(_FORWARD_PLUS)
				uint pixelLightCount = GetAdditionalLightsCount();
				LIGHT_LOOP_BEGIN(pixelLightCount)
					Light additionalLight = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
					#ifdef _LIGHT_LAYERS
					if (IsMatchingLightLayer(additionalLight.layerMask, meshRenderingLayers))
					#endif
					{
						half additionalLightAttenuation = additionalLight.shadowAttenuation * additionalLight.distanceAttenuation;
						directLightColor += StandardBRDFDirect(normalWS, viewDirWS, additionalLight.direction, diffuseColor, specularColor, metallic, roughness, additionalLight.color, additionalLightAttenuation);
					}
				LIGHT_LOOP_END
				#endif

				#if defined(_ADDITIONAL_LIGHTS_VERTEX) && !defined(_LIGHT_LAYERS)
				directLightColor += input.vertexLighting * diffuseColor;
				#endif

				half3 emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, input.uv).rgb * _EmissionColor.rgb;
				half3 finalColor = directLightColor + GIColor + emission;
				finalColor = MixFog(finalColor, input.fogCoord);
				
				// return half4(shadowAttenuation, shadowAttenuation, shadowAttenuation, 1.0h);
				outColor = half4(finalColor, 1.0h);
				#ifdef _WRITE_RENDERING_LAYERS
				outRenderingLayers = float4(EncodeMeshRenderingLayer(meshRenderingLayers), 0, 0, 0);
				#endif
			}
			ENDHLSL
		}

		Pass
		{
			Name "ShadowCaster"
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			// -------------------------------------
			// Render State Commands
			ZWrite On
			ZTest LEqual
			ColorMask 0
			Cull[_Cull]

			HLSLPROGRAM
			#pragma target 2.0

			// -------------------------------------
			// Shader Stages
			#pragma vertex ShadowPassVertex
			#pragma fragment ShadowPassFragment

			// -------------------------------------
			// Material Keywords
			#pragma shader_feature_local _ALPHATEST_ON
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

			// -------------------------------------
			// Unity defined keywords
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

			// This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			// -------------------------------------
		// Includes
		#include "./include/ShadowCasterPass.hlsl"
			ENDHLSL
		}

		Pass
		{
			Name "DepthOnly"
			Tags
			{
				"LightMode" = "DepthOnly"
			}

			// -------------------------------------
			// Render State Commands
			ZWrite On
			ColorMask R
			Cull[_Cull]

			

			HLSLPROGRAM
			#pragma target 2.0

			// -------------------------------------
			// Shader Stages
			#pragma vertex DepthOnlyVertex
			#pragma fragment DepthOnlyFragment

			// -------------------------------------
			// Material Keywords
			#pragma shader_feature_local _ALPHATEST_ON
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			// -------------------------------------
			// Unity defined keywords
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

		// -------------------------------------
		// Includes
		#include "./include/DepthOnlyPass.hlsl"
			ENDHLSL
		}

		// This pass is used when drawing to a _CameraNormalsTexture texture
		Pass
		{
			Name "DepthNormals"
			Tags
			{
				"LightMode" = "DepthNormals"
			}

			// -------------------------------------
			// Render State Commands
			ZWrite On
			Cull[_Cull]

			

			HLSLPROGRAM
			#pragma target 2.0

			// -------------------------------------
			// Shader Stages
			#pragma vertex DepthNormalsVertex
			#pragma fragment DepthNormalsFragment

			// -------------------------------------
			// Material Keywords
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local _PARALLAXMAP
			#pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
			#pragma shader_feature_local _ALPHATEST_ON
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A


			// -------------------------------------
			// Unity defined keywords
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

			// -------------------------------------
			// Universal Pipeline keywords
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

		// -------------------------------------
		// Includes
		#include "./include/DepthNormalsPass.hlsl"
			ENDHLSL
		}

		// This pass it not used during regular rendering, only for lightmap baking.
		Pass
		{
			Name "Meta"
			Tags
			{
				"LightMode" = "Meta"
			}

			// -------------------------------------
			// Render State Commands
			Cull Off

			HLSLPROGRAM
			#pragma target 2.0

			// -------------------------------------
			// Shader Stages
			#pragma vertex UniversalVertexMeta
			#pragma fragment UniversalFragmentMetaLit

			// -------------------------------------
			// Material Keywords
			#pragma shader_feature_local_fragment _SPECULAR_SETUP
			#pragma shader_feature_local_fragment _EMISSION
			#pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
			#pragma shader_feature_local_fragment _SPECGLOSSMAP
			#pragma shader_feature EDITOR_VISUALIZATION

		// -------------------------------------
		// Includes
		#include "./include/MetaPass.hlsl"

			ENDHLSL
		}
	}

	FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
