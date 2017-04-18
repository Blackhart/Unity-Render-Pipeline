#ifndef __LIGHTING_CGINC__
#define __LIGHTING_CGINC__

#include "parameters.cginc"


inline half3	Diffuse_Lambertian(half3 Rdiff);

inline half3	Specular_Phong(half3 Rspec, float3 R, float3 V, float shininess);
inline half3	Specular_Blinn_Phong(half3 Rspec, float3 N, float3 H, float shininess);
inline half3	Specular_Cook_Torrance(float NDF, float GF, half3 F, float NdotV, float NdotL);

inline float	NDF_Trowbridge_Reitz_GGX(float NdotH, float roughness);
inline float	NDF_Beckmann(float NdotH, float roughness);

inline float	GF_Base(float NdotL, float NdotV);
inline float	GF_Neumann(float NdotL, float NdotV);
inline float	GF_Cook_Torrance(float NdotH, float NdotV, float NdotL, float VdotH);
inline float	GF_Kelemen(float NdotL, float NdotV, float VdotH);
inline float	GF_Schlick_GGX(float NdotV, float NdotL, float roughness);

inline half3	Fresnel_Schlick(half3 Rspec, float3 Dir1, float3 Dir2, int Power);

inline half3	Irradiance(half3 El, float NdotL);

inline half3	Fdist_InvSqrt(float3 LightPos, float3 SurfPos, half3 Il);
inline half3	Fdist_Clamped(float3 LightPos, float3 SurfPos, half3 Il, float Rstart, float Rend);


// ~~~~~ BRDF Diffuse Terms ~~~~~

/*! \brief Lambertian term. Part of the diffuse BRDF term.
 *
 * \param Rdiff The diffuse reflectance value.
 */
inline half3	Diffuse_Lambertian(half3 Rdiff)
{
	return Rdiff * ONE_OVER_PI;
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

/*! \brief Cook-Torrance term. Part of the specular BRDF term. [Normalized]
 *
 *	f(l,v) = D(h)F(v,h)G(l,v,h) / PI(n.l)(n.v)
 *
 * \param NDF The normal distribution function's factor.
 * \param GF The geometry function's factor.
 * \param F The fresnel factor.
 * \param NdotV Dot product between the normal vector and the view vector.
 * \param NdotL Dot product between the normal vector and the light vector.
 */
inline half3	Specular_Cook_Torrance(float NDF, float GF, half3 F, float NdotV, float NdotL)
{
	return NDF * GF * F * ONE_OVER_PI * (1.0 / (NdotV * NdotL));
}

// ~~~~~ Normal Distribution Function ~~~~~

/*! \brief Trowbridge-Reitz GGX term. It's a normal distribution function used by microfacet based BRDF.
 *
 *	D(h) = r2 / PI * (NdotH2 * (r2 - 1.0) + 1.0)2
 *
 * \param NdotH Dot product between the normal vector and the half vector.
 * \param roughness The surface's roughness. Controls both the size and power of the specular highlight.
 */
inline float	NDF_Trowbridge_Reitz_GGX(float NdotH, float roughness)
{
	float r = roughness * roughness;
	float r2 = r * r;
	float denom = NdotH * NdotH * (r2 - 1.0) + 1.0;
	denom = 1.0 / (denom * denom);
	return r2 * ONE_OVER_PI * denom;
}

/*! \brief Beckmann term. It's a normal distribution function used by microfacet based BRDF.
 *
 *	D(h) = 1.0 / (PI * r2 * NdotH4) * exp -( 1.0 - NdotH2 / r2 * NdotH2 ) 
 *
 * \param NdotH Dot product between the normal vector and the half vector.
 * \param roughness The surface's roughness. Controls both the size and power of the specular highlight.
 */
inline float	NDF_Beckmann(float NdotH, float roughness)
{
	float r = roughness * roughness;
	float r2 = r * r;
	float NdotH2 = NdotH * NdotH;
	float NdotH4 = NdotH2 * NdotH2;
	float t1 = ONE_OVER_PI * (1.0 / (r2 * NdotH4));
	float t21 = 1.0 - NdotH2;
	float t22 = 1.0 / (r2 * NdotH2);
	float t2 = exp(-(t21 * t22));
	return t1 * t2;
}

// ~~~~~ Geometry Function ~~~~~

/*! \brief GF base term. It is a geometry function used by microfacet based BRDF.
 *
 *	G(l,v,h) = (n.l)(n.v)
 *
 * \param NdotL Dot product between the normal vector and the light vector.
 * \param NdotV Dot product between the normal vector and the view vector.
 */
inline float	GF_Base(float NdotL, float NdotV)
{
	return NdotL * NdotV;
}

/*! \brief Neumann term. It is a geometry function used by microfacet based BRDF.
 *
 *	G(l,v,h) = (n.l)(n.v) / max(n.l, n.v)
 *
 * \param NdotL Dot product between the normal vector and the light vector.
 * \param NdotV Dot product between the normal vector and the view vector.
 */
inline float	GF_Neumann(float NdotL, float NdotV)
{
	return NdotL * NdotV * (1.0 / max(NdotL, NdotV));
}

/*! \brief Cook-Torrance term. It is a geometry function used by microfacet based BRDF.
 *
 *	G(l,v,h) = min(1, 2(n.h)(n.v) / v.h, 2(n.h)(n.l) / v.h)
 *
 * \param NdotH Dot product between the normal vector and the half vector.
 * \param NdotV Dot product between the normal vector and the view vector.
 * \param NdotL Dot product between the normal vector and the light vector.
 * \param VdotH Dot product between the view vector and the half vector.
 */
inline float	GF_Cook_Torrance(float NdotH, float NdotV, float NdotL, float VdotH)
{
	float NdotHp2 = 2.0 * NdotH;
	float CT1 = NdotHp2 * NdotV * (1.0 / VdotH);
	float CT2 = NdotHp2 * NdotL * (1.0 / VdotH);
	return min(1.0, min(CT1, CT2));
}

/*! \brief Kelemen term. It is a geometry function used by microfacet based BRDF.
 *
 *	G(l,v,h) = (n.l)(n.v) / pow(v.h, 2)
 *
 * \param NdotL Dot product between the normal vector and the light vector.
 * \param NdotV Dot product between the normal vector and the view vector.
 * \param VdotH Dot product between the view vector and the half vector.
 */
inline float	GF_Kelemen(float NdotL, float NdotV, float VdotH)
{
	float sqrVdotH = VdotH * VdotH;
	return NdotL * NdotV * (1.0 / sqrVdotH);
}

/*! \brief Schlick GGX term. It is a geometry function used by microfacet based BRDF.
 *
 *	G(l,v,h) = G1(l) * G1(v)
 *
 *	G1(x) = (n.x) / (n.x)(1-k)+k
 *
 *	k = a * sqrt(2/PI)
 *
 * \param NdotV Dot product between the normal vector and the view vector.
 * \param NdotL Dot product between the normal vector and the light vector.
 * \param roughness The surface's roughness. Controls both the size and power of the specular highlight.
 */
inline float	GF_Schlick_GGX(float NdotV, float NdotL, float roughness)
{
	roughness = (roughness + 1.0) / 2.0;
	float k = roughness / 2.0;
	float Gv = NdotV * (1.0 / (NdotV * (1.0 - k) + k));
	float Gl = NdotL * (1.0 / (NdotL * (1.0 - k) + k));
	return Gv * Gl;
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
	return Rspec + (1.0 - Rspec) * pow((1.0 - dot(Dir1, Dir2)), Power);
}

// ~~~~~ Irradiance ~~~~~

/*! \brief Irradiance at the object's surface.
 *
 * \param El The irradiance perpendicular to the light vector.
 * \param NdotL Dot product between the normal vector and the light vector.
 */
inline half3	Irradiance(half3 El, float NdotL)
{
	return El * NdotL;
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