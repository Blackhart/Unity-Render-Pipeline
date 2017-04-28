using UnityEngine;

namespace URP.Utility
{
	public static class Transform
	{
		#region Struct

		public struct sTransform
		{
			public Vector2	position;
			public Vector2	size;
		};

		#endregion

		#region Impl(PUBLIC)

		public static sTransform	RectTransformToScreenSpace(RectTransform pRectTransform)
		{
			sTransform lTransform = new sTransform();
			Vector2 lNormalizedPivot = pRectTransform.pivot;
			lTransform.size = Vector2.Scale(pRectTransform.rect.size, pRectTransform.lossyScale);
			lTransform.position = pRectTransform.position - new Vector3(lTransform.size.x * lNormalizedPivot.x, lTransform.size.y * lNormalizedPivot.y, 0.0f);
		}

		#endregion
	}
}