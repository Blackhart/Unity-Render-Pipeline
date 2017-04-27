Shader "Development/Mask"
{
	Properties
	{
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

		Lighting Off // Lighting sets to off

		Pass
		{
			Cull Off // Culling sets to off
			ZWrite Off // ZWrite sets to off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			struct vertOutput
			{
				float4 clipPos : SV_POSITION;
			};

			void	vert(in appdata_base pIN, out vertOutput pOUT)
			{
				// ~~~~~ Output ~~~~~

				pOUT.clipPos = UnityObjectToClipPos(pIN.vertex);
			}

			struct fragOutput
			{
				half4 color : SV_TARGET0;
			};

			void	frag(in vertOutput pIN, out fragOutput pOUT)
			{
				// ~~~~~ Output ~~~~~

				pOUT.color = half4(1.0, 0.0, 0.0, 1.0);
			}

			ENDCG
		}
	}
}
