using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Effects
{
	public abstract class Effect
	{
		#region Enums

		public enum eRepeatMode
		{
			ONCE,
			FOREVER,
			NEVER
		};

		#endregion

		#region Parameters

		protected Texture		_IN;
		protected Texture		_OUT;
		protected eRepeatMode	_repeatMode;
		protected CommandBuffer	_commandBuffer;
		protected Material		_material;
		protected int			_OUT_Texture_ID;

		#endregion

		#region Properties

		public Texture	IN
		{
			get { return _IN; }
			set
			{
				_IN = value;
				UpdateCommandBuffer();
			}
		}

		public Texture	OUT
		{
			get { return _OUT; }
			protected set { _OUT = value; }
		}

		public virtual eRepeatMode	RepeatMode
		{
			get { return _repeatMode; }
			set { _repeatMode = value; }
		}

		#endregion

		#region Object

		protected	Effect()
		{
			Uninitialize();
		}

		#endregion

		#region Impl(PUBLIC)

		public abstract void	Initialize();

		public virtual void	Uninitialize()
		{
			_IN = null;
			_OUT = null;
			_repeatMode = eRepeatMode.NEVER;
			_commandBuffer = null;
			_material = null;
			_OUT_Texture_ID = -1;
		}

		public virtual void	Execute()
		{
			if (_repeatMode == eRepeatMode.FOREVER || _repeatMode == eRepeatMode.ONCE)
			{
				Graphics.ExecuteCommandBuffer(_commandBuffer);
				_OUT = Shader.GetGlobalTexture(_OUT_Texture_ID);
			}
		}

		#endregion

		#region Impl(HIDDEN)

		protected abstract void	UpdateCommandBuffer();

		#endregion
	}
}