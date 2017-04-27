using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Effects
{
	public class Mask : Effect
	{
		#region Structs

		struct sMaskTransform
		{
			public int x;
			public int y;
			public int width;
			public int height;
		};

		#endregion

		#region Parameters

		private static readonly string	MASK_SHADER_NAME = "Development/Mask";
		private static readonly string	MASK_TEXTURE_NAME = "URP_2D_MASK_TEXTURE";
		private static readonly string	MASK_RENDER_TARGET_NAME = "URP_2D_MASK_RENDER_TARGET";

		private sMaskTransform	__maskTransform;

		#endregion

		#region Properties

		public sMaskTransform	MaskTransform
		{
			get { return __maskTransform; }
			set
			{
				__maskTransform = value;
				_dirty = true;
			}
		}

		#endregion

		#region Object

		public	Mask()
		{
			Initialize();
		}

		#endregion

		#region Impl(PUBLIC)

		public override void Initialize ()
		{
			_commandBuffer = new CommandBuffer();
			_commandBuffer.name = "Effect: 2D Mask";

			_material = new Material(Shader.Find(MASK_SHADER_NAME));
			_material.hideFlags = HideFlags.HideAndDontSave;

			_OUT_Texture_ID = Shader.PropertyToID(MASK_TEXTURE_NAME);

			__maskTransform = null;
		}

		public override void Uninitialize ()
		{
			base.Uninitialize();
		}

		#endregion

		#region Impl(HIDDEN)

		protected override void UpdateCommandBuffer()
		{
			base.UpdateCommandBuffer();
			SetCommandBuffer();
		}

		private void	SetCommandBuffer()
		{
			int lRenderTarget_ID = Shader.PropertyToID(MASK_RENDER_TARGET_NAME);
			_commandBuffer.GetTemporaryRT(lRenderTarget_ID, __maskTransform.width, __maskTransform.height, 0, _IN.filterMode);

			_commandBuffer.Blit(_IN, lRenderTarget_ID, _material);

			_commandBuffer.SetGlobalTexture(_OUT_Texture_ID, lRenderTarget_ID);

			_commandBuffer.ReleaseTemporaryRT(lRenderTarget_ID);
		}

		#endregion
	}
}
