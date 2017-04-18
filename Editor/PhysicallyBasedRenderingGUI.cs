using UnityEngine;

namespace UnityEditor
{
	public class PhysicallyBasedRenderingGUI : ShaderGUI
	{
		#region Enums

		public enum eBodyBRDF
		{
			Lambertian
		};

		public enum eSurfaceBRDF
		{
			Cook_Torrance
		};

		public enum eNDF
		{
			Trowbridge_Reitz,
			Beckmann
		};

		public enum eGF
		{
			Base,
			Neumann,
			Cook_Torrance,
			Kelemen,
			Schlick_GGX
		};

		public enum eFresnel
		{
			Schlick
		};

		#endregion

		#region Parameters

		private Material	__material;

		private float	__Smoothness;

		private MaterialProperty	__DiffMap;
		private MaterialProperty	__DiffColor;
		private MaterialProperty	__SpecMap;
		private MaterialProperty	__SpecColor;
		private MaterialProperty	__NormalMap;

		private static GUIContent	__DiffValue_Text = new GUIContent("Diffuse");
		private static GUIContent	__SpecValue_Text = new GUIContent("Specular (R,G,B) | Smoothness (A)");
		private static GUIContent	__NormalMap_Text = new GUIContent("Normal");

		#endregion

		#region Properties

		private eBodyBRDF	BodyBRDF
		{
			set
			{
			}
			get
			{
				return eBodyBRDF.Lambertian;
			}
		}

		private eSurfaceBRDF	SurfaceBRDF
		{
			set 
			{
			}
			get
			{
				return eSurfaceBRDF.Cook_Torrance;
			}
		}

		private eNDF	NDF
		{
			set
			{
				SetKeyword("NDF_BECKMANN", value == eNDF.Beckmann);
				SetKeyword ("NDF_TROWBRIDGE_REITZ", value == eNDF.Trowbridge_Reitz);
			}
			get
			{
				if (__material.IsKeywordEnabled ("NDF_BECKMANN"))
					return eNDF.Beckmann;
				else if (__material.IsKeywordEnabled ("NDF_TROWBRIDGE_REITZ"))
					return eNDF.Trowbridge_Reitz;
				else
					return eNDF.Trowbridge_Reitz;
			}
		}

		private eGF	GF
		{
			set
			{
				SetKeyword ("GF_BASE", value == eGF.Base);
				SetKeyword ("GF_COOK_TORRANCE", value == eGF.Cook_Torrance);
				SetKeyword ("GF_KELEMEN", value == eGF.Kelemen);
				SetKeyword ("GF_NEUMANN", value == eGF.Neumann);
				SetKeyword ("GF_SCHLICK_GGX", value == eGF.Schlick_GGX);
			}
			get
			{
				if (__material.IsKeywordEnabled ("GF_BASE"))
					return eGF.Base;
				else if (__material.IsKeywordEnabled ("GF_NEUMANN"))
					return eGF.Neumann;
				else if (__material.IsKeywordEnabled ("GF_COOK_TORRANCE"))
					return eGF.Cook_Torrance;
				else if (__material.IsKeywordEnabled ("GF_KELEMEN"))
					return eGF.Kelemen;
				else if (__material.IsKeywordEnabled ("GF_SCHLICK_GGX"))
					return eGF.Schlick_GGX;
				else
					return eGF.Schlick_GGX;
			}
		}

		private eFresnel	Fresnel
		{
			set
			{
			}
			get
			{
				return eFresnel.Schlick;
			}
		}

		#endregion

		#region Constructor

		public	PhysicallyBasedRenderingGUI()
		{
			__DiffMap = null;
			__DiffColor = null;
			__SpecMap = null;
			__SpecColor = null;
			__NormalMap = null;
		}

		#endregion

		#region Inspector

		public override void OnGUI(MaterialEditor pMaterialEditor, MaterialProperty[] pProperties)
		{
			//base.OnGUI (materialEditor, properties);
			__material = pMaterialEditor.target as Material;

			GetProperties(pProperties);
			DrawProperties(pMaterialEditor);
		}

		#endregion

		#region Methods

		private void	GetProperties(MaterialProperty[] pProperties)
		{
			__DiffMap = FindProperty("_DiffMap", pProperties);
			__DiffColor = FindProperty("_DiffColor", pProperties);
			__SpecMap = FindProperty("_SpecMapTMP", pProperties);
			__SpecColor = FindProperty("_SpecColorTMP", pProperties);
			__Smoothness = __SpecColor.colorValue.a;
			__NormalMap = FindProperty("_NormalMap", pProperties);
		}

		private void	DrawProperties(MaterialEditor pMaterialEditor)
		{
			GUIStyle lStyle = new GUIStyle ();
			lStyle.alignment = TextAnchor.MiddleCenter;
			lStyle.fontStyle = FontStyle.Bold;

			EditorGUILayout.LabelField ("Bidirectional Reflectance Distribution Function", lStyle);

			EditorGUILayout.Space ();

			BodyBRDF = (eBodyBRDF)EditorGUILayout.EnumPopup("Body BRDF", BodyBRDF);
			EditorGUILayout.Space();
			SurfaceBRDF = (eSurfaceBRDF)EditorGUILayout.EnumPopup("Surface BRDF", SurfaceBRDF);
			NDF = (eNDF)EditorGUILayout.EnumPopup("Normal Distribution", NDF);
			GF = (eGF)EditorGUILayout.EnumPopup("Geometry", GF);
			Fresnel = (eFresnel)EditorGUILayout.EnumPopup("Fresnel", Fresnel);

			EditorGUILayout.Space ();
			EditorGUILayout.Space ();

			EditorGUILayout.LabelField ("Material", lStyle);

			EditorGUILayout.Space ();

			pMaterialEditor.TexturePropertySingleLine(__DiffValue_Text, __DiffMap, __DiffColor);
			EditorGUILayout.BeginHorizontal();
				pMaterialEditor.TexturePropertySingleLine(__SpecValue_Text, __SpecMap, __SpecColor);
				__Smoothness = EditorGUILayout.Slider(__Smoothness, 0.0f, 1.0f);
				Color lSpecColor = __SpecColor.colorValue;
				lSpecColor.a = __Smoothness;
				__SpecColor.colorValue = lSpecColor;
			EditorGUILayout.EndVertical();

			EditorGUILayout.Space ();
			EditorGUILayout.Space ();

			EditorGUILayout.LabelField ("Geometry", lStyle);

			EditorGUILayout.Space ();

			pMaterialEditor.TexturePropertySingleLine(__NormalMap_Text, __NormalMap);
			SetKeyword("_NORMALMAP", __NormalMap.textureValue != null);
		}

		private void	SetKeyword(string pKeyword, bool pState)
		{
			if (pState)
				__material.EnableKeyword(pKeyword);
			else
				__material.DisableKeyword(pKeyword);
		}

		#endregion
	}
}