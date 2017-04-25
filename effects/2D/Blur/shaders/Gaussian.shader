Shader "Development/Gaussian"
{
	Properties
	{
		_MainTex ("Sprite Texture", 2D) = "white" {}

		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255
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

		Pass
		{
			Cull Off // Culling sets to off
			ZWrite Off // ZWrite sets to off

			CGPROGRAM

			#pragma shader_feature URP_2D_GAUSSIAN_HORIZONTAL URP_2D_GAUSSIAN_VERTICAL

			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			sampler2D	_MainTex;
			int			URP_2D_GAUSSIAN_Width;
			int			URP_2D_GAUSSIAN_Height;
			float		URP_2D_GAUSSIAN_Weight[4];

			struct vertOutput
			{
				float4 clipPos : SV_POSITION;
				float2 texcoord[7] : TEXCOORD0;
			};

			void	vert(in appdata_base pIN, out vertOutput pOUT)
			{
				// ~~~~~ Data ~~~~~

			#if defined(URP_2D_GAUSSIAN_HORIZONTAL)
				float x = 1.0 / (float)URP_2D_GAUSSIAN_Width;
				float xc = 2.0 * x;
				float xcc = 3.0 * x;
				pOUT.texcoord[0] = float2(pIN.texcoord.x - xcc, pIN.texcoord.y);
				pOUT.texcoord[1] = float2(pIN.texcoord.x - xc, pIN.texcoord.y);
				pOUT.texcoord[2] = float2(pIN.texcoord.x - x, pIN.texcoord.y);
				pOUT.texcoord[3] = pIN.texcoord;
				pOUT.texcoord[4] = float2(pIN.texcoord.x + x, pIN.texcoord.y);
				pOUT.texcoord[5] = float2(pIN.texcoord.x + xc, pIN.texcoord.y);
				pOUT.texcoord[6] = float2(pIN.texcoord.x + xcc, pIN.texcoord.y);
			#elif defined(URP_2D_GAUSSIAN_VERTICAL)
				float y = 1.0 / (float)URP_2D_GAUSSIAN_Height;
				float yc = 2.0 * y;
				float ycc = 3.0 * y;
				pOUT.texcoord[0] = float2(pIN.texcoord.x, pIN.texcoord.y - ycc);
				pOUT.texcoord[1] = float2(pIN.texcoord.x, pIN.texcoord.y - yc);
				pOUT.texcoord[2] = float2(pIN.texcoord.x, pIN.texcoord.y - y);
				pOUT.texcoord[3] = pIN.texcoord;
				pOUT.texcoord[4] = float2(pIN.texcoord.x, pIN.texcoord.y + y);
				pOUT.texcoord[5] = float2(pIN.texcoord.x, pIN.texcoord.y + yc);
				pOUT.texcoord[6] = float2(pIN.texcoord.x, pIN.texcoord.y + ycc);
			#endif

				// ~~~~~ Output ~~~~~

				pOUT.clipPos = UnityObjectToClipPos(pIN.vertex);
			}

			struct fragOutput
			{
				half4 color : SV_TARGET0;
			};

			void	frag(in vertOutput pIN, out fragOutput pOUT)
			{
				half4 color = half4(0.0, 0.0, 0.0, 0.0);
				color += tex2D(_MainTex, pIN.texcoord[0]) * URP_2D_GAUSSIAN_Weight[3];
				color += tex2D(_MainTex, pIN.texcoord[1]) * URP_2D_GAUSSIAN_Weight[2];
				color += tex2D(_MainTex, pIN.texcoord[2]) * URP_2D_GAUSSIAN_Weight[1];
				color += tex2D(_MainTex, pIN.texcoord[3]) * URP_2D_GAUSSIAN_Weight[0];
				color += tex2D(_MainTex, pIN.texcoord[4]) * URP_2D_GAUSSIAN_Weight[1];
				color += tex2D(_MainTex, pIN.texcoord[5]) * URP_2D_GAUSSIAN_Weight[2];
				color += tex2D(_MainTex, pIN.texcoord[6]) * URP_2D_GAUSSIAN_Weight[3];
				pOUT.color = color;
			}

			ENDCG
		}
	}
}
