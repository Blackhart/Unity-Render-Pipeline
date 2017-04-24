Shader "Development/Gaussian"
{
	Properties
	{
		_MainTex ("Sprite Texture", 2D) = "white" {}

		_Width ("Width", Int) = 0
		_Height ("Height", Int) = 0

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

			#pragma shader_feature HORIZONTAL VERTICAL

			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			sampler2D	_MainTex;
			int			_Width;
			int			_Height;

			struct vertOutput
			{
				float4 clipPos : SV_POSITION;
				float2 texcoord[5] : TEXCOORD0;
			};

			void	vert(in appdata_base pIN, out vertOutput pOUT)
			{
				// ~~~~~ Data ~~~~~

			#if defined(HORIZONTAL)
				float x = 1.0 / (float)_Width;
				float xc = 2.0 * x;
				pOUT.texcoord[0] = float2(pIN.texcoord.x - xc, pIN.texcoord.y);
				pOUT.texcoord[1] = float2(pIN.texcoord.x - x, pIN.texcoord.y);
				pOUT.texcoord[2] = pIN.texcoord;
				pOUT.texcoord[3] = float2(pIN.texcoord.x + x, pIN.texcoord.y);
				pOUT.texcoord[4] = float2(pIN.texcoord.x + xc, pIN.texcoord.y);
			#elif defined(VERTICAL)
				float y = 1.0 / (float)_Height;
				float yc = 2.0 * x;
				pOUT.texcoord[0] = float2(pIN.texcoord.x, pIN.texcoord.y - yc);
				pOUT.texcoord[1] = float2(pIN.texcoord.x, pIN.texcoord.y - y);
				pOUT.texcoord[2] = pIN.texcoord;
				pOUT.texcoord[3] = float2(pIN.texcoord.x, pIN.texcoord.y + y);
				pOUT.texcoord[4] = float2(pIN.texcoord.x, pIN.texcoord.y + yc);
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
				pOUT.color = tex2D(_MainTex, pIN.texcoord[0]);
			}

			ENDCG
		}
	}
}
