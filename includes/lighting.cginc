#ifndef __LIGHTING_CGINC__
#define __LIGHTING_CGINC__

#include "parameters.cginc"


inline half3	Lambertian_Diffuse(half3 Cdiff);

inline half3	Blinn_Phong_Specular(half3 Cspec, float3 N, float3 L, float3 V, float smoothness);

inline half3	dhrByRefractiveIndex(half3 n);
inline half3	Fresnel_Schlick(half3 Rspec, float3 N, float3 L);

inline half3	Irradiance(half3 El, float3 N, float3 L);

inline half3	Fdist_InvSqrt(float3 LightPos, float3 SurfPos, half3 Il);
inline half3	Fdist_Clamped(float3 LightPos, float3 SurfPos, half3 Il, float Rstart, float Rend);


// ~~~~~ BRDF Diffuse Terms ~~~~~

/*! \brief Lambertian term. Part of the diffuse BRDF term.
 *
 * \param Rdiff The diffuse reflectance value.
 */
inline half3	Lambertian_Diffuse(half3 Rdiff)
{
	return Rdiff / PI;
}

// ~~~~~ BRDF Specular Terms ~~~~~

/*! \brief Blinn-Phong term. Part of the specular BRDF term.
 *
 * \param Rspec The specular reflectance value.
 * \param N The normal vector [Normalized][World space].
 * \param L The light vector [Normalized][World space].
 * \param V The view vector [Normalized][World space].
 * \param smoothness The smoothness value. High value == shark reflection due to optically perfect surface. Low value == diffuse reflection due to surface discontinuities.
 */
inline half3	Blinn_Phong_Specular(half3 Rspec, float3 N, float3 L, float3 V, float smoothness)
{
	half3 H = normalize(L + V);
	return ((smoothness + 8.0) / (8.0 * PI)) * pow(saturate(dot(H, N)), smoothness) * Rspec;
}

// ~~~~~ Directional-hemispherical reflectance ~~~~~

/*! \brief Compute the directional-hemispherical reflectance using the substance's refractive index.
 *
 * \param n The substance's refractive index.
 */
inline half3	dhrByRefractiveIndex(half3 n)
{
	return ((n - 1.0) / (n + 1.0)) * ((n - 1.0) / (n + 1.0));
}

/*! \brief Schlick's fresnel term. Part of the surface reflectance term.
 * 
 * \param Rspec The specular reflectance value.
 * \param N The normal vector [Normalized][World space].
 * \param L The light vector [Normalized][World space].
 * \param Power The power with which the Schlick's fresnel term is compute. Normal power is 5. A lower power will reduce accuracy but computation will be much faster.
 */
inline half3	Fresnel_Schlick(half3 Rspec, float3 N, float3 L, int Power)
{
	return Rspec + (1.0 - Rspec) * pow((1.0 - saturate(dot(N, L))), Power);
}

// ~~~~~ Irradiance ~~~~~

/*! \brief Irradiance at the object's surface.
 *
 * \param El The irradiance perpendicular to the light vector.
 * \param N The normal vector [Normalized][World space].
 * \param L The light vector [Normalized][World space].
 */
inline half3	Irradiance(half3 El, float3 N, float3 L)
{
	return El * saturate(dot(N, L));
}

// ~~~~~ Distance Fallof Functions ~~~~~

/*! \brief Realistic distance fallof function.
 *
 * \param LightPos The light position [World space].
 * \param SurfPos The surface position [World space].
 * \param Il The light intensity.
 */
inline half3	Fdist_InvSqrt(float3 LightPos, float3 SurfPos, half3 Il)
{
	float r = distance(LightPos, SurfPos);
	return Il * (1.0 / (r * r));
}

/*! \brief Unrealisitic distance fallof function. Used in video games. 
 *
 * \param LightPos The light position [World space].
 * \param SurfPos The surface position [World space].
 * \param Il The light intensity.
 * \param Rstart Distance at which the light attenuation begin.
 * \param Rend Distance at which the light attenuation finish.
 */
inline half3	Fdist_Clamped(float3 LightPos, float3 SurfPos, half3 Il, float Rstart, float Rend)
{
	float r = distance(LightPos, SurfPos);
	return Il * saturate((Rend - r) / (Rend - Rstart));
}

#endif