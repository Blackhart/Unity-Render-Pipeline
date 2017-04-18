﻿Shader "Development/Physically Based Rendering"
{
	Properties
	{
		_DiffMap ("DiffMap", 2D) = "white" {}
		_DiffColor ("DiffColor", Color) = (1.0, 1.0, 1.0, 1.0)
		_SpecMapTMP ("SpecMap", 2D) = "white" {}
		_SpecColorTMP ("SpecColor", Color) = (1.0, 1.0, 1.0, 1.0)
		_NormalMap ("NormalMap", 2D) = "bump" {}
		_OcclusionMap ("OcclusionMap", 2D) = "white" {}
	}
	SubShader
	{
		Tags
		{
			"RenderType" = "Opaque"
		}
		LOD 200

		Pass
		{
			Tags
			{
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM

			#pragma multi_compile_fwdbase
			#pragma shader_feature NDF_TROWBRIDGE_REITZ NDF_BECKMANN
			#pragma shader_feature GF_SCHLICK_GGX GF_NEUMANN GF_BASE GF_COOK_TORRANCE GF_KELEMEN
			#pragma shader_feature _NORMALMAP

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "../includes/lighting.cginc"
			#include "../includes/utils.cginc"


			sampler2D	_DiffMap;
			float4		_DiffMap_ST;
			half4		_DiffColor;
			sampler2D	_SpecMapTMP;
			float4		_SpecMapTMP_ST;
			half4		_SpecColorTMP;
			sampler2D	_NormalMap;
			float4		_NormalMap_ST;
			sampler2D	_OcclusionMap;
			float4		_OcclusionMap_ST;


			struct vertOutput
			{
				float4	ClipPos : SV_POSITION;
				float2	Texcoord : TEXCOORD0;
			#if !defined(_NORMALMAP)
				float3	Normal : NORMAL;
			#endif
				float3	WorldLightDir : TEXCOORD1;
				float3	WorldViewDir : TEXCOORD2;
			#if defined(_NORMALMAP)
				float3x3	TBNMatrix : COLOR0;
			#endif
				SHADOW_COORDS(3)
			};

			void	vert(in appdata_tan pIN, out vertOutput pOUT)
			{
				// ~~~~~ Data ~~~~~

				pOUT.Texcoord = TRANSFORM_TEX(pIN.texcoord, _DiffMap);
			#if !defined(_NORMALMAP)
				pOUT.Normal = UnityObjectToWorldNormal(pIN.normal);
			#endif
				float3 WorldPos = mul(unity_ObjectToWorld, pIN.vertex);
				pOUT.WorldLightDir = UnityWorldSpaceLightDir(WorldPos);
				pOUT.WorldViewDir = _WorldSpaceCameraPos - WorldPos;
			#if defined(_NORMALMAP)
				pOUT.TBNMatrix = TBNMatrix(pIN.normal, pIN.tangent);
			#endif

			#if defined (SHADOWS_SCREEN)
				#if defined(UNITY_NO_SCREENSPACE_SHADOWS)
					pOUT._ShadowCoord = mul(unity_WorldToShadow[0], WorldPos);
				#else
					pOUT._ShadowCoord = ComputeScreenPos(UnityObjectToClipPos(pIN.vertex));
				#endif
			#endif
			#if defined (SHADOWS_DEPTH) && defined (SPOT)
				pOUT._ShadowCoord = mul(unity_WorldToShadow[0], WorldPos);
			#endif
			#if defined (SHADOWS_CUBE)
				pOUT._ShadowCoord = WorldPos - _LightPositionRange.xyz;
			#endif

				// ~~~~~ OUTPUT ~~~~~

				pOUT.ClipPos = UnityObjectToClipPos(pIN.vertex);

			}

			struct fragOutput
			{
				half4	Color : SV_TARGET0;
			};

			void	frag(in vertOutput pIN, out fragOutput pOUT)
			{
				// ~~~~~ Data ~~~~~

				half3 Il = _LightColor0.rgb;
				half4 DiffColor = _DiffColor * tex2D(_DiffMap, pIN.Texcoord);
				half4 SpecColor = _SpecColorTMP * tex2D(_SpecMapTMP, pIN.Texcoord);
				half Roughness = max(1.0 - SpecColor.a, 0.0);
			#if !defined(_NORMALMAP)
				float3 WorldNormal = normalize(pIN.Normal);
			#else
				fixed3 Normal = UnpackNormal(tex2D(_NormalMap, pIN.Texcoord));
				float3 WorldNormal = mul(pIN.TBNMatrix, Normal);
			#endif
				half4 Occlusion = tex2D(_OcclusionMap, pIN.Texcoord);
				float3 WorldLightDir = normalize(pIN.WorldLightDir);

				float NdotL = dot(WorldNormal, WorldLightDir);
				if (NdotL <= 0.0)
				{
					pOUT.Color = half4(0.0, 0.0, 0.0, 1.0);
					return;
				}

				float3 WorldViewDir = normalize(pIN.WorldViewDir);
				float3 H = normalize(WorldLightDir + WorldViewDir);

				float NdotV = dot(WorldNormal, WorldViewDir);
				float NdotH = dot(WorldNormal, H);
				float VdotH = dot(WorldViewDir, H);
				float LdotH = dot(WorldLightDir, H);

				// ~~~~~ SHADOW ~~~~~

				fixed Shadow = SHADOW_ATTENUATION(pIN);

				// ~~~~~ Microfacet ~~~~~

			#if defined(NDF_TROWBRIDGE_REITZ)
				float NDF = NDF_Trowbridge_Reitz_GGX(NdotH, Roughness);
			#elif defined(NDF_BECKMANN)
				float NDF = NDF_Beckmann(NdotH, Roughness);
			#endif

			#if defined(GF_BASE)
				float GF = GF_Base(NdotL, NdotV);
			#elif defined(GF_NEUMANN)
			 	float GF = GF_Neumann(NdotL, NdotV);
			#elif defined(GF_COOK_TORRANCE)
				float GF = GF_Cook_Torrance(NdotH, NdotV, NdotL, VdotH);
			#elif defined(GF_KELEMEN)
				float GF = GF_Kelemen(NdotL, NdotV, VdotH);
			#elif defined(GF_SCHLICK_GGX)
				float GF = GF_Schlick_GGX(NdotV, NdotL, Roughness);
			#endif

				// ~~~~~ Reflectance Values ~~~~~

				half3 Rspec = Fresnel_Schlick(SpecColor.rgb, H, WorldLightDir, 5.0);
				half3 Rdiff = (1.0 - Rspec) * DiffColor.rgb;

				// ~~~~~ BRDF terms ~~~~~

				half3 Ldiff = Diffuse_Lambertian(Rdiff);
				half3 Lspec = Specular_Cook_Torrance(NDF, GF, Rspec, NdotV, NdotL);
				half3 L0 = (Ldiff + Lspec) * Irradiance(Il, NdotL) * Occlusion * Shadow;

				// ~~~~~ OUTPUT ~~~~~

				pOUT.Color = half4(L0, 1.0);
			}

			ENDCG
		}

		Pass
		{
			Tags
			{
				"LightMode" = "ForwardAdd"
			}
			Blend One One

			CGPROGRAM

			#pragma multi_compile_fwdadd
			#pragma shader_feature NDF_TROWBRIDGE_REITZ NDF_BECKMANN
			#pragma shader_feature GF_SCHLICK_GGX GF_NEUMANN GF_BASE GF_COOK_TORRANCE GF_KELEMEN
			#pragma shader_feature _NORMALMAP

			#pragma skip_variants POINT_COOKIE
			#pragma skip_variants DIRECTIONAL_COOKIE

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "../includes/lighting.cginc"
			#include "../includes/utils.cginc"


			sampler2D	_DiffMap;
			float4		_DiffMap_ST;
			half4		_DiffColor;
			sampler2D	_SpecMapTMP;
			float4		_SpecMapTMP_ST;
			half4		_SpecColorTMP;
			sampler2D	_NormalMap;
			float4		_NormalMap_ST;
			sampler2D	_OcclusionMap;
			float4		_OcclusionMap_ST;


			struct vertOutput
			{
				float4	ClipPos : SV_POSITION;
				float2	Texcoord : TEXCOORD0;
			#if !defined(_NORMALMAP)
				float3	Normal : NORMAL;
			#endif
				float3	WorldLightDir : TEXCOORD1;
				float3	WorldViewDir : TEXCOORD2;
				float3	WorldPos : TEXCOORD3;
 			#if defined(POINT)
				float3	LightCoord : TEXCOORD4;
			#elif defined(SPOT)
				float4	LightCoord : TEXCOORD4;
			#endif
			#if defined(_NORMALMAP)
				float3x3	TBNMatrix : COLOR0;
			#endif
				SHADOW_COORDS(5)
			};

			void	vert(in appdata_tan pIN, out vertOutput pOUT)
			{
				// ~~~~~ Data ~~~~~

				pOUT.Texcoord = TRANSFORM_TEX(pIN.texcoord, _DiffMap);
			#if !defined(_NORMALMAP)
				pOUT.Normal = UnityObjectToWorldNormal(pIN.normal);
			#endif
				float4 WorldPos = mul(unity_ObjectToWorld, pIN.vertex);
				pOUT.WorldPos = WorldPos.xyz;
				pOUT.WorldLightDir = UnityWorldSpaceLightDir(pOUT.WorldPos);
				pOUT.WorldViewDir = _WorldSpaceCameraPos - pOUT.WorldPos;
			#if defined(POINT) || defined(SPOT)
				pOUT.LightCoord = mul(unity_WorldToLight, WorldPos);
			#endif
			#if defined(_NORMALMAP)
				pOUT.TBNMatrix = TBNMatrix(pIN.normal, pIN.tangent);
			#endif

			#if defined (SHADOWS_SCREEN)
				#if defined(UNITY_NO_SCREENSPACE_SHADOWS)
					pOUT._ShadowCoord = mul(unity_WorldToShadow[0], WorldPos);
				#else
					pOUT._ShadowCoord = ComputeScreenPos(UnityObjectToClipPos(pIN.vertex));
				#endif
			#endif
			#if defined (SHADOWS_DEPTH) && defined (SPOT)
				pOUT._ShadowCoord = mul(unity_WorldToShadow[0], WorldPos);
			#endif
			#if defined (SHADOWS_CUBE)
				pOUT._ShadowCoord = WorldPos - _LightPositionRange.xyz;
			#endif

				// ~~~~~ OUTPUT ~~~~~

				pOUT.ClipPos = UnityObjectToClipPos(pIN.vertex);
				
			}

			struct fragOutput
			{
				half4	Color : SV_TARGET0;
			};

			void	frag(in vertOutput pIN, out fragOutput pOUT)
			{
				// ~~~~~ Data ~~~~~

				half3 Il = _LightColor0.rgb;
				half4 DiffColor = _DiffColor * tex2D(_DiffMap, pIN.Texcoord);
				half4 SpecColor = _SpecColorTMP * tex2D(_SpecMapTMP, pIN.Texcoord);
				half Roughness = max(1.0 - SpecColor.a, 0.0);
			#if !defined(_NORMALMAP)
				float3 WorldNormal = normalize(pIN.Normal);
			#else
				fixed3 Normal = UnpackNormal(tex2D(_NormalMap, pIN.Texcoord));
				float3 WorldNormal = mul(pIN.TBNMatrix, Normal);
			#endif
				half4 Occlusion = tex2D(_OcclusionMap, pIN.Texcoord);
				float3 WorldLightDir = normalize(pIN.WorldLightDir);

				float NdotL = dot(WorldNormal, WorldLightDir);
				if (NdotL <= 0.0)
				{
					pOUT.Color = half4(0.0, 0.0, 0.0, 1.0);
					return;
				}

				float3 WorldViewDir = normalize(pIN.WorldViewDir);
				float3 H = normalize(WorldLightDir + WorldViewDir);

				float NdotV = dot(WorldNormal, WorldViewDir);
				float NdotH = dot(WorldNormal, H);
				float VdotH = dot(WorldViewDir, H);
				float LdotH = dot(WorldLightDir, H);

				// ~~~~~ SHADOW ~~~~~

				fixed Shadow = SHADOW_ATTENUATION(pIN);

				// ~~~~~ Light Attenuation ~~~~~

			#if defined(POINT)
				Il *= tex2D(_LightTexture0, dot(pIN.LightCoord, pIN.LightCoord).xx).UNITY_ATTEN_CHANNEL;
			#elif defined(SPOT)
				Il *= (pIN.LightCoord.z > 0) * UnitySpotCookie(pIN.LightCoord) * UnitySpotAttenuate(pIN.LightCoord.xyz);
			#endif

			// ~~~~~ Microfacet ~~~~~

			#if defined(NDF_TROWBRIDGE_REITZ)
				float NDF = NDF_Trowbridge_Reitz_GGX(NdotH, Roughness);
			#elif defined(NDF_BECKMANN)
				float NDF = NDF_Beckmann(NdotH, Roughness);
			#endif

			#if defined(GF_BASE)
				float GF = GF_Base(NdotL, NdotV);
			#elif defined(GF_NEUMANN)
			 	float GF = GF_Neumann(NdotL, NdotV);
			#elif defined(GF_COOK_TORRANCE)
				float GF = GF_Cook_Torrance(NdotH, NdotV, NdotL, VdotH);
			#elif defined(GF_KELEMEN)
				float GF = GF_Kelemen(NdotL, NdotV, VdotH);
			#elif defined(GF_SCHLICK_GGX)
				float GF = GF_Schlick_GGX(NdotV, NdotL, Roughness);
			#endif

				// ~~~~~ Reflectance values ~~~~~

				half3 Rspec = Fresnel_Schlick(SpecColor.rgb, H, WorldLightDir, 5);
				half3 Rdiff = (1.0 - Rspec) * DiffColor.rgb;

				// ~~~~~ BRDF terms ~~~~~

				half3 Ldiff = Diffuse_Lambertian(Rdiff);
				half3 Lspec = Specular_Cook_Torrance(NDF, GF, Rspec, NdotV, NdotL);
				half3 L0 = (Ldiff + Lspec) * Irradiance(Il, NdotL) * Occlusion;

				// ~~~~~ OUTPUT ~~~~~

				pOUT.Color = half4(L0, 1.0);
			}

			ENDCG
		}

		Pass
		{
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma multi_compile_shadowcaster

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct v2f
			{
				V2F_SHADOW_CASTER;
			};

			v2f	vert(appdata_base v)
			{
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			float4	frag(v2f i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}

			ENDCG
		}
	}

	CustomEditor "PhysicallyBasedRenderingGUI"
}