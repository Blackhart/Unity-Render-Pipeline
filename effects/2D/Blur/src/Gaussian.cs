﻿using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;

namespace Effects
{
	[ExecuteInEditMode]
	public class Gaussian : MonoBehaviour 
	{
		#region Parameters

		private static readonly string	SHADER_NAME = "Development/Gaussian";

		private CommandBuffer	__commandBuffer = null;
		private Material 		__material = null;
		private int				__blurredTextureID = -1;
		private Texture			__blurredTexture = null;
		[SerializeField]
		private int				__downsampling = 1;

		#endregion

		#region Properties

		public int	Downsampling
		{
			get { return __downsampling; }
			set 
			{
				__downsampling = value;
				Initialize();
			}
		}

		#endregion

		#region Unity Callbacks

		public void	Awake()
		{
			Initialize();
		}

		public void	OnDestroy()
		{
			Uninitialize();
		}

		public void	OnDisable()
		{
			Uninitialize();
		}

		public void	LateUpdate()
		{
			Process();
		}

		#endregion

		#region Impl

		private void	Uninitialize()
		{
			if (__commandBuffer != null)
				__commandBuffer.Clear();
			__commandBuffer = null;
			Material lMaterial = GetComponent<Image>().material;
			lMaterial.EnableKeyword("MAIN_TEX");
			lMaterial.DisableKeyword("OVERRIDE_TEX");
		}

		private void	Initialize()
		{
			if (__material == null)
			{
				__material = new Material(Shader.Find(SHADER_NAME));
				__material.hideFlags = HideFlags.HideAndDontSave;
			}

			__commandBuffer = new CommandBuffer();
			__commandBuffer.name = "Object: " + transform.name + " 2D Gaussian Blur";

			Image lImage = GetComponent<Image>();
			int lWidth = lImage.sprite.texture.width / __downsampling;
			int lHeight = lImage.sprite.texture.height / __downsampling;

			int	lRenderTarget1ID = Shader.PropertyToID("_RenderTarget1");
			int lRenderTarget2ID = Shader.PropertyToID("_RenderTarget2");
			__commandBuffer.GetTemporaryRT(lRenderTarget1ID, lWidth, lHeight, 0, lImage.sprite.texture.filterMode);
			__commandBuffer.GetTemporaryRT(lRenderTarget2ID, lWidth, lHeight, 0, lImage.sprite.texture.filterMode);

			__commandBuffer.SetGlobalFloat("_Width", lWidth);
			__commandBuffer.SetGlobalFloat("_Height", lHeight);
			__commandBuffer.SetGlobalFloatArray("_Weight", new float[4] { 0.23463f, 0.20111f, 0.12569f, 0.05586f });

			__commandBuffer.EnableShaderKeyword("HORIZONTAL");
			__commandBuffer.DisableShaderKeyword("VERTICAL");
			__commandBuffer.Blit(lImage.sprite.texture, lRenderTarget1ID, __material);

			__commandBuffer.EnableShaderKeyword("VERTICAL");
			__commandBuffer.DisableShaderKeyword("HORIZONTAL");
			__commandBuffer.Blit(lRenderTarget1ID, lRenderTarget2ID, __material);

			__blurredTextureID = Shader.PropertyToID("_BlurredTexture");
			__commandBuffer.SetGlobalTexture(__blurredTextureID, lRenderTarget2ID);

			__commandBuffer.ReleaseTemporaryRT(lRenderTarget1ID);
			__commandBuffer.ReleaseTemporaryRT(lRenderTarget2ID);
		}

		private void	Process()
		{
			if (__commandBuffer == null)
				Initialize();
			
			Graphics.ExecuteCommandBuffer(__commandBuffer);

			Texture lBlurredTexture = Shader.GetGlobalTexture(__blurredTextureID);
			if (lBlurredTexture != null)
				__blurredTexture = lBlurredTexture;

			Material lMaterial = GetComponent<Image>().material;
			if (__blurredTexture != null)
			{
				lMaterial.EnableKeyword("OVERRIDE_TEX");
				lMaterial.DisableKeyword("MAIN_TEX");
				lMaterial.SetTexture("_OverrideTex", __blurredTexture);			
			} 
			else
			{
				lMaterial.DisableKeyword("OVERRIDE_TEX");
				lMaterial.EnableKeyword("MAIN_TEX");
			}			
		}

		#endregion
	}
}
