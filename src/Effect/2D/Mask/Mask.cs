using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Effects
{
	public class Mask : Effect
	{
		#region Parameters

		private static readonly string	MASK_SHADER_NAME = "Development/Mask";
		private static readonly string	MASK_TEXTURE_NAME = "URP_2D_MASK_TEXTURE";

		#endregion

		#region Properties

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
		}

		public override void Uninitialize ()
		{
			base.Uninitialize();
		}

		#endregion

		#region Impl(HIDDEN)

		protected override void UpdateCommandBuffer()
		{
		}

		#endregion
	}
}
