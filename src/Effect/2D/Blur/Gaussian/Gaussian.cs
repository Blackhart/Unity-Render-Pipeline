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
		private static readonly string	RENDER_TARGET_NAME = "URP_2D_GAUSSIAN_RENDER_TARGET";
		private static readonly string	SHADER_WIDTH_PROPERTY_NAME = "URP_2D_GAUSSIAN_Width";
		private static readonly string	SHADER_HEIGHT_PROPERTY_NAME = "URP_2D_GAUSSIAN_Height";
		private static readonly string	SHADER_WEIGHT_PROPERTY_NAME = "URP_2D_GAUSSIAN_Weight";
		private static readonly string	SHADER_HORIZONTAL_PASS_NAME = "URP_2D_GAUSSIAN_HORIZONTAL";
		private static readonly string	SHADER_VERTICAL_PASS_NAME = "URP_2D_GAUSSIAN_VERTICAL";
		private static readonly string	BLURRED_TEXTURE_NAME = "URP_2D_GAUSSIAN_TEXTURE";

		private int	__downsampling;

		#endregion

		#region Properties

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
			_commandBuffer = new CommandBuffer();
			_commandBuffer.name = "Effect: 2D Gaussian Blur";

			_material = new Material(Shader.Find(BLUR_SHADER_NAME));
			_material.hideFlags = HideFlags.HideAndDontSave;

			_OUT_Texture_ID = Shader.PropertyToID(BLURRED_TEXTURE_NAME);

			__downsampling = 8;
		}

		public override void	Uninitialize()
		{
			base.Uninitialize();
			__downsampling = 1;
		}

		#endregion

		#region Impl(HIDDEN)

		protected override void	UpdateCommandBuffer()
		{
			base.UpdateCommandBuffer();
			SetCommandBuffer();
		}

		protected void	SetCommandBuffer()
		{
			int lWidth = _IN.width / __downsampling;
			int lHeight = _IN.height / __downsampling;
			FilterMode lFilterMode = _IN.filterMode;

			int	lRenderTarget_ID1 = Shader.PropertyToID(RENDER_TARGET_NAME + "_1");
			int	lRenderTarget_ID2 = Shader.PropertyToID(RENDER_TARGET_NAME + "_2");
			_commandBuffer.GetTemporaryRT(lRenderTarget_ID1, lWidth, lHeight, 0, lFilterMode);
			_commandBuffer.GetTemporaryRT(lRenderTarget_ID2, lWidth, lHeight, 0, lFilterMode);

			_commandBuffer.SetGlobalFloat(SHADER_WIDTH_PROPERTY_NAME, lWidth);
			_commandBuffer.SetGlobalFloat(SHADER_HEIGHT_PROPERTY_NAME, lHeight);
			_commandBuffer.SetGlobalFloatArray(SHADER_WEIGHT_PROPERTY_NAME, new float[4] { 0.23463f, 0.20111f, 0.12569f, 0.05586f });

			_commandBuffer.EnableShaderKeyword(SHADER_HORIZONTAL_PASS_NAME);
			_commandBuffer.DisableShaderKeyword(SHADER_VERTICAL_PASS_NAME);
			_commandBuffer.Blit(_IN, lRenderTarget_ID1, _material);

			_commandBuffer.EnableShaderKeyword(SHADER_VERTICAL_PASS_NAME);
			_commandBuffer.DisableShaderKeyword(SHADER_HORIZONTAL_PASS_NAME);
			_commandBuffer.Blit(lRenderTarget_ID1, lRenderTarget_ID2, _material);

			_commandBuffer.SetGlobalTexture(_OUT_Texture_ID, lRenderTarget_ID2);

			_commandBuffer.ReleaseTemporaryRT(lRenderTarget_ID1);
			_commandBuffer.ReleaseTemporaryRT(lRenderTarget_ID2);
		}

		#endregion
	}
}
