#ifndef __UTILS_CGINC__
#define __UTILS_CGINC__


inline float3x3	TBNMatrix(float3 N, float3 T);


// ~~~~~ Matrix ~~~~~

/*! \brief The TBN matrix
 *
 * \param N The normal vector [Normalized][Object space]
 * \param T The tangent space [Normalized][Object space]
 *
 */
inline float3x3	TBNMatrix(float3 N, float4 T)
{
	float3 B = cross(N, T.xyz) * T.w;
	return float3x3(T.x, B.x, N.x, T.y, B.y, N.y, T.z, B.z, N.z);
}

#endif