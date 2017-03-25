#ifndef __UTILS_CGINC__
#define __UTILS_CGINC__


inline float3x3	TBNMatrix(float3 N, float3 T);


// ~~~~~ Matrix ~~~~~

/*! \brief The TBN matrix [WorldSpace]
 *
 * \param N The normal vector [Normalized][Object space]
 * \param T The tangent space [Normalized][Object space]
 */
inline float3x3	TBNMatrix(float3 N, float4 T)
{
	float3 WorldNormal = UnityObjectToWorldNormal(N);
	float3 WorldTangent = normalize(mul(unity_ObjectToWorld, T.xyz));
	float3 WorldBinormal = normalize(mul(unity_ObjectToWorld, cross(N, T.xyz) * T.w));
	return float3x3(WorldTangent.x, WorldBinormal.x, WorldNormal.x,
					WorldTangent.y, WorldBinormal.y, WorldNormal.y,
					WorldTangent.z, WorldBinormal.z, WorldNormal.z);
}

#endif