#ifndef __LIGHTING_CGINC__
#define __LIGHTING_CGINC__

#include "parameters.cginc"


inline half3	Diffuse_Lambertian(half3 Cdiff);

inline half3	Specular_Phong(half3 Rspec, float3 R, float3 V, float shininess);
inline half3	Specular_Blinn_Phong(half3 Cspec, float3 N, float3 L, float3 V, float smoothness);

inline half3	dhr_dhrByRefractiveIndex(half3 n);

inline half3	Fresnel_Schlick(half3 Rspec, float3 N, float3 L);

inline half3	Irradiance(half3 El, float3 N, float3 L);

inline half3	Fdist_InvSqrt(float3 LightPos, float3 SurfPos, half3 Il);
inline half3	Fdist_Clamped(float3 LightPos, float3 SurfPos, half3 Il, float Rstart, float Rend);


// ~~~~~ BRDF Diffuse Terms ~~~~~

/*! \brief Lambertian term. Part of the diffuse BRDF term.
 *
 * \param Rdiff The diffuse reflectance value.
 */
inline half3	Diffuse_Lambertian(half3 Rdiff)
{
	return Rdiff / PI;
}

// ~~~~~ BRDF Specular Terms ~~~~~

/*! \brief Phong term. Part of the specular BRDF term. [Normalized]
 *
 * \param Rspec The specular reflectance value.
 * \param R The ideal reflection vector [Normalized][World space].
 * \param V The view vector [Normalized][World space].
 * \param shininess Controls both the size and power of the specular highlight.
 */
inline half3	Specular_Phong(half3 Rspec, float3 R, float3 V, float shininess)
{
	return ((shininess + 2.0) / (2.0 * PI)) * pow(dot(R, V), shininess) * Rspec;
}

/*! \brief Blinn-Phong term. Part of the specular BRDF term. [Normalized]
 *
 * \param Rspec The specular reflectance value.
 * \param N The normal vector [Normalized][World space].
 * \param H The half vector [Normalized][World space].
 * \param shininess Controls both the size and power of the specular highlight.
 */
inline half3	Specular_Blinn_Phong(half3 Rspec, float3 N, float3 H, float shininess)
{
	return ((shininess + 8.0) / (8.0 * PI)) * pow(saturate(dot(H, N)), shininess) * Rspec;
}

// ~~~~~ Directional-hemispherical reflectance ~~~~~

/*! \brief Compute the directional-hemispherical reflectance using the substance's refractive index.
 *
 * \param n The substance's refractive index.
 */
inline half3	dhr_dhrByRefractiveIndex(half3 n)
{
	return ((n - 1.0) / (n + 1.0)) * ((n - 1.0) / (n + 1.0));
}

// ~~~~~ Fresnel ~~~~~

/*! \brief Schlick's fresnel term. Part of the surface reflectance term.
 * 
 * \param Rspec The specular reflectance value.
 * \param Dir1 The Dir1 vector [Normalized][World space]. Depends of which fresnel effect do you want to have. Usually the half vector or normal vector.
 * \param Dir2 The Dir2 vector [Normalized][World space]. Depends of the kind of reflection. If External reflection => The light vector. If Internal reflection => The transmited vector.
 * \param Power The power with which the Schlick's fresnel term is compute. Normal power is 5. A lower power will reduce accuracy but computation will be much faster.
 */
inline half3	Fresnel_Schlick(half3 Rspec, float3 Dir1, float3 Dir2, int Power)
{
	return Rspec + (1.0 - Rspec) * pow((1.0 - saturate(dot(Dir1, Dir2))), Power);
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