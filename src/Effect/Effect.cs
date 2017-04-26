using UnityEngine;

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

		#endregion

		#region Properties

		public virtual Texture	IN
		{
			get { return _IN; }
			set { _IN = value; }
		}

		public virtual Texture	OUT
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
			_IN = null;
			_OUT = null;
			_repeatMode = eRepeatMode.NEVER;
		}

		#endregion

		#region Impl(PUBLIC)

		public abstract void	Initialize();
		public abstract void	Uninitialize();
		public abstract void	Execute();

		#endregion
	}
}