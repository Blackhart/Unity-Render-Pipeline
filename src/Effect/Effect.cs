using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Effects
{
	public abstract class Effect : MonoBehaviour
	{
		#region Parameters

		protected Texture	_IN;
		protected Texture	_OUT;

		#endregion

		#region Properties

		public Texture	IN
		{
			get { return _IN; }
			set { _IN = value; }
		}

		public Texture	OUT
		{
			get { return _OUT; }
			set { _OUT = value; }
		}

		#endregion

		#region Impl

		public abstract void	Initialize();
		public abstract void	Uninitialize();
		public abstract void	Execute();

		#endregion
	}
}