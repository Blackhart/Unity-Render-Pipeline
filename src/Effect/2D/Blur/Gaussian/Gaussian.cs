using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;

namespace URP.Effects
{
	[System.Serializable]
	public class Gaussian : Effect 
	{
		#region Parameters

		private static readonly string	BLUR_SHADER_NAME = "URP/Gaussian";
		private static readonly string	RENDER_TARGET_NAME = "URP_2D_GAUSSIAN_RenderTarget";
		private static readonly string	SHADER_WIDTH_PROPERTY_NAME = "URP_2D_GAUSSIAN_Width";
		private static readonly string	SHADER_HEIGHT_PROPERTY_NAME = "URP_2D_GAUSSIAN_Height";
		private static readonly string	SHADER_WEIGHT_PROPERTY_NAME = "URP_2D_GAUSSIAN_Weight";
		private static readonly string	SHADER_HORIZONTAL_PASS_NAME = "URP_2D_GAUSSIAN_HORIZONTAL";
		private static readonly string	SHADER_VERTICAL_PASS_NAME = "URP_2D_GAUSSIAN_VERTICAL";
		private static readonly string	BLURRED_TEXTURE_NAME = "URP_2D_GAUSSIAN_BlurredTexture";

		private CommandBuffer	__commandBuffer;
		private Material 		__blurMaterial;
		private int				__blurredTextureID;
		private int				__downsampling;

		#endregion

		#region Properties

		public override Texture IN
		{
			get { return base.IN; }
			set 
			{
				base.IN = value;
				UpdateCommandBuffer();
			}
		}

		public int	Downsampling
		{
			get { return __downsampling; }
			set 
			{
				__downsampling = value;
				UpdateCommandBuffer();
			}
		}

		#endregion

		#region Object

		public	Gaussian()
		{
			Initialize();
		}

		#endregion

		#region Impl(PUBLIC)

		public override void	Initialize()
		{
			__commandBuffer = new CommandBuffer();
			__commandBuffer.name = "Effect: 2D Gaussian Blur";

			__blurMaterial = new Material(Shader.Find(BLUR_SHADER_NAME));
			__blurMaterial.hideFlags = HideFlags.HideAndDontSave;

			__blurredTextureID = Shader.PropertyToID(BLURRED_TEXTURE_NAME);

			__downsampling = 8;
		}

		public override void	Uninitialize()
		{
			__commandBuffer = null;
			__blurMaterial = null;
			__blurredTextureID = -1;
			__downsampling = 1;
		}

		public override void	Execute()
		{
			if (_repeatMode == eRepeatMode.FOREVER || _repeatMode == eRepeatMode.ONCE)
			{
				Graphics.ExecuteCommandBuffer(__commandBuffer);
				_OUT = Shader.GetGlobalTexture(__blurredTextureID);
			}
		}

		#endregion

		#region Impl(HIDDEN)

		protected void	UpdateCommandBuffer()
		{
			__commandBuffer.Clear();
			SetCommandBuffer();
		}

		protected void	SetCommandBuffer()
		{
			int lWidth = _IN.width / __downsampling;
			int lHeight = _IN.height / __downsampling;
			FilterMode lFilterMode = _IN.filterMode;

			int	lRenderTarget_ID1 = Shader.PropertyToID(RENDER_TARGET_NAME + "_1");
			int	lRenderTarget_ID2 = Shader.PropertyToID(RENDER_TARGET_NAME + "_2");
			__commandBuffer.GetTemporaryRT(lRenderTarget_ID1, lWidth, lHeight, 0, lFilterMode);
			__commandBuffer.GetTemporaryRT(lRenderTarget_ID2, lWidth, lHeight, 0, lFilterMode);

			__commandBuffer.SetGlobalFloat(SHADER_WIDTH_PROPERTY_NAME, lWidth);
			__commandBuffer.SetGlobalFloat(SHADER_HEIGHT_PROPERTY_NAME, lHeight);
			__commandBuffer.SetGlobalFloatArray(SHADER_WEIGHT_PROPERTY_NAME, new float[4] { 0.23463f, 0.20111f, 0.12569f, 0.05586f });

			__commandBuffer.EnableShaderKeyword(SHADER_HORIZONTAL_PASS_NAME);
			__commandBuffer.DisableShaderKeyword(SHADER_VERTICAL_PASS_NAME);
			__commandBuffer.Blit(_IN, lRenderTarget_ID1, __blurMaterial);

			__commandBuffer.EnableShaderKeyword(SHADER_VERTICAL_PASS_NAME);
			__commandBuffer.DisableShaderKeyword(SHADER_HORIZONTAL_PASS_NAME);
			__commandBuffer.Blit(lRenderTarget_ID1, lRenderTarget_ID2, __blurMaterial);

			__commandBuffer.SetGlobalTexture(__blurredTextureID, lRenderTarget_ID2);

			__commandBuffer.ReleaseTemporaryRT(lRenderTarget_ID1);
			__commandBuffer.ReleaseTemporaryRT(lRenderTarget_ID2);
		}

		#endregion
	}
}
