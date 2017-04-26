using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;

namespace Effects
{
	[ExecuteInEditMode]
	public class Gaussian : MonoBehaviour 
	{
		#region Parameters

		private static readonly string	BLUR_SHADER_NAME = "Development/Gaussian";
		private static readonly string	DEFAULT_SHADER_NAME = "URP/Default";
		private static readonly string	RENDER_TARGET_NAME = "URP_2D_GAUSSIAN_RenderTarget";
		private static readonly string	SHADER_WIDTH_PROPERTY_NAME = "URP_2D_GAUSSIAN_Width";
		private static readonly string	SHADER_HEIGHT_PROPERTY_NAME = "URP_2D_GAUSSIAN_Height";
		private static readonly string	SHADER_WEIGHT_PROPERTY_NAME = "URP_2D_GAUSSIAN_Weight";
		private static readonly string	SHADER_HORIZONTAL_PASS_NAME = "URP_2D_GAUSSIAN_HORIZONTAL";
		private static readonly string	SHADER_VERTICAL_PASS_NAME = "URP_2D_GAUSSIAN_VERTICAL";
		private static readonly string	BLURRED_TEXTURE_NAME = "URP_2D_GAUSSIAN_BlurredTexture";

		private CommandBuffer	__commandBuffer = null;
		private Material 		__blurMaterial = null;
		private Material		__defaultMaterial = null;
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

		public void	OnEnable()
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

		public void	Initialize()
		{
			__blurMaterial = new Material(Shader.Find(BLUR_SHADER_NAME));
			__blurMaterial.hideFlags = HideFlags.HideAndDontSave;

			__defaultMaterial = new Material(Shader.Find(DEFAULT_SHADER_NAME));
			__defaultMaterial.hideFlags = HideFlags.HideAndDontSave;

			__blurredTextureID = Shader.PropertyToID(BLURRED_TEXTURE_NAME);

			Image lImage = GetComponent<Image>();

			lImage.material = __defaultMaterial;

			int lWidth = lImage.sprite.texture.width / __downsampling;
			int lHeight = lImage.sprite.texture.height / __downsampling;
			FilterMode lFilterMode = lImage.sprite.texture.filterMode;

			__commandBuffer = new CommandBuffer();
			__commandBuffer.name = "Object: " + transform.name + " | Effect: 2D Gaussian Blur";

			int lRenderTarget_ID1 = Shader.PropertyToID(RENDER_TARGET_NAME + "_1");
			int lRenderTarget_ID2 = Shader.PropertyToID(RENDER_TARGET_NAME + "_2");
			__commandBuffer.GetTemporaryRT(lRenderTarget_ID1, lWidth, lHeight, 0, lFilterMode);
			__commandBuffer.GetTemporaryRT(lRenderTarget_ID2, lWidth, lHeight, 0, lFilterMode);

			__commandBuffer.SetGlobalFloat(SHADER_WIDTH_PROPERTY_NAME, lWidth);
			__commandBuffer.SetGlobalFloat(SHADER_HEIGHT_PROPERTY_NAME, lHeight);
			__commandBuffer.SetGlobalFloatArray(SHADER_WEIGHT_PROPERTY_NAME, new float[4] { 0.23463f, 0.20111f, 0.12569f, 0.05586f });

			__commandBuffer.EnableShaderKeyword(SHADER_HORIZONTAL_PASS_NAME);
			__commandBuffer.DisableShaderKeyword(SHADER_VERTICAL_PASS_NAME);
			__commandBuffer.Blit(lImage.sprite.texture, lRenderTarget_ID1, __blurMaterial);

			__commandBuffer.EnableShaderKeyword(SHADER_VERTICAL_PASS_NAME);
			__commandBuffer.DisableShaderKeyword(SHADER_HORIZONTAL_PASS_NAME);
			__commandBuffer.Blit(lRenderTarget_ID1, lRenderTarget_ID2, __blurMaterial);

			__commandBuffer.SetGlobalTexture(__blurredTextureID, lRenderTarget_ID2);

			__commandBuffer.ReleaseTemporaryRT(lRenderTarget_ID1);
			__commandBuffer.ReleaseTemporaryRT(lRenderTarget_ID2);
		}

		public void	Uninitialize()
		{
			__commandBuffer = null;
			__blurMaterial = null;
			if (__defaultMaterial)
			{
				__defaultMaterial.DisableKeyword("OVERRIDE_TEX");
				__defaultMaterial.EnableKeyword("MAIN_TEX");
			}
			__defaultMaterial = null;
			__blurredTextureID = -1;
			__blurredTexture = null;
		}

		public void	Process()
		{
			Graphics.ExecuteCommandBuffer(__commandBuffer);

			Texture lBlurredTexture = Shader.GetGlobalTexture(__blurredTextureID);
			if (__blurredTexture == null)
				__blurredTexture = lBlurredTexture;

			if (__blurredTexture != null)
			{
				__defaultMaterial.EnableKeyword("OVERRIDE_TEX");
				__defaultMaterial.DisableKeyword("MAIN_TEX");
				__defaultMaterial.SetTexture("_OverrideTex", __blurredTexture);			
			} 
			else
			{
				__defaultMaterial.DisableKeyword("OVERRIDE_TEX");
				__defaultMaterial.EnableKeyword("MAIN_TEX");
			}			
		}

		#endregion
	}
}
