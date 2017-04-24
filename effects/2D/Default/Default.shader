Shader "Development/Default"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_OverrideTex ("Override Sprite Texture", 2D) = "white" {}

		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255

		_ColorMask ("Color Mask", Float) = 15

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
	}
	SubShader
	{
		Tags 
		{
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}

		Stencil
		{
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp] 
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
		}
		
		LOD 100
		Lighting Off // Lighting sets to off
		ColorMask [_ColorMask] // Mask the picture when you add a Mask component on it

		Pass
		{
			Cull Off // Culling sets to off
			ZWrite Off // ZWrite sets to off
			ZTest [unity_GUIZTestMode]

			CGPROGRAM

			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			#pragma shader_feature MAIN_TEX OVERRIDE_TEX

			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

		#if defined (MAIN_TEX)
			sampler2D _MainTex;
		#elif defined (OVERRIDE_TEX)
			sampler2D _OverrideTex;
		#endif
			float4 _ClipRect; // Filled when using the Rect Mask 2D component

			struct vertOutput
			{
				float4 clipPos : SV_POSITION;
				fixed4 color : COLOR; // Additional per vertex color used by some components such as [Selectable | etc ]
				float2 texcoord : TEXCOORD0;
				float4 worldPos : TEXCOORD1;
				// Related to VR, specifically single pass stereo rendering for VR
				// https://docs.unity3d.com/Manual/SinglePassStereoRendering.html
				UNITY_VERTEX_OUTPUT_STEREO
			};

			void	vert(in appdata_full pIN, out vertOutput pOUT)
			{
				// ~~~~~ Initialization ~~~~~

				// Use for GPU instancing
				// https://docs.unity3d.com/Manual/GPUInstancing.html
				UNITY_SETUP_INSTANCE_ID(pIN);
				// Related to VR, specifically single pass stereo rendering for VR
				// https://docs.unity3d.com/Manual/SinglePassStereoRendering.html
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(pOUT);

				// ~~~~~ Data ~~~~~

				pOUT.color = pIN.color; // Additional per vertex color used by some components such as [Selectable | etc ]
				pOUT.texcoord = pIN.texcoord;
				pOUT.worldPos = pIN.vertex;

				// ~~~~~ Output ~~~~~

				pOUT.clipPos = UnityObjectToClipPos(pIN.vertex);
			}

			struct fragOutput
			{
				half4 color : SV_TARGET0;
			};

			void	frag(in vertOutput pIN, out fragOutput pOUT)
			{

			#if defined (MAIN_TEX)
				pOUT.color = tex2D(_MainTex, pIN.texcoord) * pIN.color;
			#elif defined (OVERRIDE_TEX)
				pOUT.color = tex2D(_OverrideTex, pIN.texcoord) * pIN.color;
			#endif
				
				pOUT.color.a *= UnityGet2DClipping(pIN.worldPos.xy, _ClipRect); // Masking with Rect Mask 2D component
				
			#ifdef UNITY_UI_ALPHACLIP
				clip (pOUT.color.a - 0.001);
			#endif

			}

			ENDCG
		}
	}
}
