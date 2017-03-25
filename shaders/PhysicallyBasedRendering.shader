Shader "Development/Physically Based Rendering"
{
	Properties
	{
		_DiffMap ("DiffMap", 2D) = "white" {}
		_DiffColor ("DiffColor", Color) = (1.0, 1.0, 1.0, 1.0)
		_SpecMapTMP ("SpecMap", 2D) = "white" {}
		_SpecColorTMP ("SpecColor", Color) = (1.0, 1.0, 1.0, 1.0)
		_NormalMap ("NormalMap", 2D) = "bump" {}
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
			#pragma shader_feature GF_SCHLICK_GGX GF_BASE GF_NEUMANN GF_COOK_TORRANCE GF_KELEMEN
			#pragma shader_feature _NORMALMAP

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
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
				half Roughness = max(SpecColor.a * SpecColor.a, 0.01);
			#if !defined(_NORMALMAP)
				float3 WorldNormal = normalize(pIN.Normal);
			#else
				fixed3 Normal = UnpackNormal(tex2D(_NormalMap, pIN.Texcoord));
				float3 WorldNormal = mul(pIN.TBNMatrix, Normal);
			#endif
				float3 WorldLightDir = normalize(pIN.WorldLightDir);
				float3 WorldViewDir = normalize(pIN.WorldViewDir);
				float3 H = normalize(WorldLightDir + WorldViewDir);

				// ~~~~~ Microfacet ~~~~~

			#if defined(NDF_TROWBRIDGE_REITZ)
				float NDF = NDF_Trowbridge_Reitz_GGX(WorldNormal, H, Roughness);
			#elif defined(NDF_BECKMANN)
				float NDF = NDF_Beckmann(WorldNormal, H, Roughness);
			#endif

			#if defined(GF_BASE)
				float GF = GF_Base(WorldNormal, WorldLightDir, WorldViewDir);
			#elif defined(GF_NEUMANN)
			 	float GF = GF_Neumann(WorldNormal, WorldLightDir, WorldViewDir);
			#elif defined(GF_COOK_TORRANCE)
				float GF = GF_Cook_Torrance(WorldNormal, WorldLightDir, WorldViewDir, H);
			#elif defined(GF_KELEMEN)
				float GF = GF_Kelemen(WorldNormal, WorldLightDir, WorldViewDir, H);
			#elif defined(GF_SCHLICK_GGX)
				float GF = GF_Schlick_GGX(WorldNormal, WorldLightDir, WorldViewDir, Roughness);
			#endif

				// ~~~~~ Reflectance Values ~~~~~

				half3 Rspec = Fresnel_Schlick(SpecColor.rgb, H, WorldLightDir, 5.0);
				half3 Rdiff = (1.0 - Rspec) * DiffColor.rgb;

				// ~~~~~ BRDF terms ~~~~~

				half3 Ldiff = Diffuse_Lambertian(Rdiff);
				half3 Lspec = Specular_Cook_Torrance(NDF, GF, Rspec, WorldViewDir, WorldLightDir, WorldNormal);
				half3 L0 = (Ldiff + Lspec) * Irradiance(Il, WorldNormal, WorldLightDir);

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
			#pragma shader_feature GF_SCHLICK_GGX GF_BASE GF_NEUMANN GF_COOK_TORRANCE GF_KELEMEN
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
				half Roughness = max(SpecColor.a * SpecColor.a, 0.01);
			#if !defined(_NORMALMAP)
				float3 WorldNormal = normalize(pIN.Normal);
			#else
				fixed3 Normal = UnpackNormal(tex2D(_NormalMap, pIN.Texcoord));
				float3 WorldNormal = mul(pIN.TBNMatrix, Normal);
			#endif
				float3 WorldLightDir = normalize(pIN.WorldLightDir);
				float3 WorldViewDir = normalize(pIN.WorldViewDir);
				float3 H = normalize(WorldLightDir + WorldViewDir);

				// ~~~~~ Light Attenuation ~~~~~

			#if defined(POINT)
				Il *= tex2D(_LightTexture0, dot(pIN.LightCoord, pIN.LightCoord).xx).UNITY_ATTEN_CHANNEL;
			#elif defined(SPOT)
				Il *= (pIN.LightCoord.z > 0) * UnitySpotCookie(pIN.LightCoord) * UnitySpotAttenuate(pIN.LightCoord.xyz);
			#endif

			// ~~~~~ Microfacet ~~~~~

			#if defined(NDF_TROWBRIDGE_REITZ)
				float NDF = NDF_Trowbridge_Reitz_GGX(WorldNormal, H, Roughness);
			#elif defined(NDF_BECKMANN)
				float NDF = NDF_Beckmann(WorldNormal, H, Roughness);
			#endif

			#if defined(GF_BASE)
				float GF = GF_Base(WorldNormal, WorldLightDir, WorldViewDir);
			#elif defined(GF_NEUMANN)
			 	float GF = GF_Neumann(WorldNormal, WorldLightDir, WorldViewDir);
			#elif defined(GF_COOK_TORRANCE)
				float GF = GF_Cook_Torrance(WorldNormal, WorldLightDir, WorldViewDir, H);
			#elif defined(GF_KELEMEN)
				float GF = GF_Kelemen(WorldNormal, WorldLightDir, WorldViewDir, H);
			#elif defined(GF_SCHLICK_GGX)
				float GF = GF_Schlick_GGX(WorldNormal, WorldLightDir, WorldViewDir, Roughness);
			#endif

				// ~~~~~ Reflectance values ~~~~~

				half3 Rspec = Fresnel_Schlick(SpecColor.rgb, H, WorldLightDir, 5);
				half3 Rdiff = (1.0 - Rspec) * DiffColor.rgb;

				// ~~~~~ BRDF terms ~~~~~

				half3 Ldiff = Diffuse_Lambertian(Rdiff);
				half3 Lspec = Specular_Cook_Torrance(NDF, GF, Rspec, WorldViewDir, WorldLightDir, WorldNormal);
				half3 L0 = (Ldiff + Lspec) * Irradiance(Il, WorldNormal, WorldLightDir);

				// ~~~~~ OUTPUT ~~~~~

				pOUT.Color = half4(L0, 1.0);
			}

			ENDCG
		}
	}

	CustomEditor "PhysicallyBasedRenderingGUI"
}