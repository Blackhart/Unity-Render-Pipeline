#ifndef __LIGHTING_CGINC__
#define __LIGHTING_CGINC__

#include "parameters.cginc"


inline half3	Diffuse_Lambertian(half3 Rdiff);

inline half3	Specular_Phong(half3 Rspec, float3 R, float3 V, float shininess);
inline half3	Specular_Blinn_Phong(half3 Rspec, float3 N, float3 H, float shininess);
inline half3	Specular_Cook_Torrance(float NDF, float GF, half3 F, float3 V, float3 L, float3 N);

inline float	NDF_Trowbridge_Reitz_GGX(float3 N, float3 H, float roughness);
inline float	NDF_Beckmann(float3 N, float3 H, float roughness);

inline float	GF_Base(float3 N, float3 L, float3 V);
inline float	GF_Neumann(float3 N, float3 L, float3 V);
inline float	GF_Cook_Torrance(float3 N, float3 L, float3 V, float3 H);
inline float	GF_Kelemen(float3 N, float3 L, float3 V, float3 H);
inline float	GF_Schlick_GGX(float3 N, float3 L, float3 V, float roughness);

inline half3	Fresnel_Schlick(half3 Rspec, float3 Dir1, float3 Dir2, int Power);

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

/*! \brief Cook-Torrance term. Part of the specular BRDF term. [Normalized]
 *
 *	f(l,v) = D(h)F(v,h)G(l,v,h) / PI(n.l)(n.v)
 *
 * \param NDF The normal distribution function's factor.
 * \param GF The geometry function's factor.
 * \param F The fresnel factor.
 * \param V The view vector [Normalized][World space].
 * \param L The light vector [Normalized][World space].
 * \param N The normal vector [Normalized][World space].
 */
inline half3	Specular_Cook_Torrance(float NDF, float GF, half3 F, float3 V, float3 L, float3 N)
{
	return (NDF * GF * F) / (PI * dot(V, N) * dot(L, N));
}

// ~~~~~ Normal Distribution Function ~~~~~

/*! \brief Trowbridge-Reitz GGX term. It's a normal distribution function used by microfacet based BRDF.
 *
 *	D(h) = pow(a, 2) / PI * pow((pow(n.h, 2) * (pow(a, 2) - 1) + 1), 2)
 *
 * \param N The normal vector [Normalized][World space].
 * \param H The half vector [Normalized][World space].
 * \param roughness The surface's roughness. Controls both the size and power of the specular highlight.
 */
inline float	NDF_Trowbridge_Reitz_GGX(float3 N, float3 H, float roughness)
{
	float sqrRoughness = roughness * roughness;
	float NdotH = saturate(dot(N, H));
	float sqrNdotH = NdotH * NdotH;
	float normalizeFactor = (sqrNdotH * (sqrRoughness - 1.0) + 1.0);
	return sqrRoughness / (PI * normalizeFactor * normalizeFactor);
}

/*! \brief Beckmann term. It's a normal distribution function used by microfacet based BRDF.
 *
 *	D(h) = (pow(a, 2) / (PI * pow(a, 2) * pow(n.h, 4))) * exp((pow(n.h, 2) - 1.0) / (pow(a, 2) * pow(n.h, 2)))
 *
 * \param N The normal vector [Normalized][World space].
 * \param H The half vector [Normalized][World space].
 * \param roughness The surface's roughness. Controls both the size and power of the specular highlight.
 */
inline float	NDF_Beckmann(float3 N, float3 H, float roughness)
{
	float sqrRoughness = roughness * roughness;
	float NdotH = saturate(dot(N, H));
	float sqrNdotH = NdotH * NdotH;
	return (1.0 / (PI * sqrRoughness * sqrNdotH * sqrNdotH)) * exp((sqrNdotH - 1.0) / (sqrRoughness * sqrNdotH));
}

// ~~~~~ Geometry Function ~~~~~

/*! \brief GF base term. It is a geometry function used by microfacet based BRDF.
 *
 *	G(l,v,h) = (n.l)(n.v)
 *
 * \param N The normal vector [Normalized][World space].
 * \param V The view vector [Normalized][World space].
 * \param L The light vector [Normalized][World space].
 */
inline float	GF_Base(float3 N, float3 L, float3 V)
{
	return saturate(dot(N, L)) * saturate(dot(N, V));
}

/*! \brief Neumann term. It is a geometry function used by microfacet based BRDF.
 *
 *	G(l,v,h) = (n.l)(n.v) / max(n.l, n.v)
 *
 * \param N The normal vector [Normalized][World space].
 * \param V The view vector [Normalized][World space].
 * \param L The light vector [Normalized][World space].
 */
inline float	GF_Neumann(float3 N, float3 L, float3 V)
{
	float NdotL = saturate(dot(N, L));
	float NdotV = saturate(dot(N, V));
	return (NdotL * NdotV) / max(NdotL, NdotV);
}

/*! \brief Cook-Torrance term. It is a geometry function used by microfacet based BRDF.
 *
 *	G(l,v,h) = min(1, 2(n.h)(n.h) / v.h, 2(n.h)(n.l) / v.h)
 *
 * \param N The normal vector [Normalized][World space].
 * \param V The view vector [Normalized][World space].
 * \param L The light vector [Normalized][World space].
 * \param H The half vector [Normalized][World space].
 */
inline float	GF_Cook_Torrance(float3 N, float3 L, float3 V, float3 H)
{
	float NdotH = saturate(dot(N, H));
	float NdotV = saturate(dot(N, V));
	float NdotL = saturate(dot(N, L));
	float VdotH = saturate(dot(V, H));
	float CT1 = (2.0 * NdotH * NdotV) / VdotH;
	float CT2 = (2.0 * NdotH * NdotL) / VdotH;
	return min(1.0, min(CT1, CT2));
}

/*! \brief Kelemen term. It is a geometry function used by microfacet based BRDF.
 *
 *	G(l,v,h) = (n.l)(n.v) / pow(v.h, 2)
 *
 * \param N The normal vector [Normalized][World space].
 * \param V The view vector [Normalized][World space].
 * \param L The light vector [Normalized][World space].
 * \param H The half vector [Normalized][World space].
 */
inline float	GF_Kelemen(float3 N, float3 L, float3 V, float3 H)
{
	float NdotL = saturate(dot(N, L));
	float NdotV = saturate(dot(N, V));
	float VdotH = saturate(dot(V, H));
	float sqrVdotH = VdotH * VdotH;
	return (NdotL * NdotV) / sqrVdotH;
}

/*! \brief Schlick GGX term. It is a geometry function used by microfacet based BRDF.
 *
 *	G(l,v,h) = G1(l) * G1(v)
 *
 *	G1(x) = (n.x) / (n.x)(1-k)+k
 *
 *	k = a * sqrt(2/PI)
 *
 * \param N The normal vector [Normalized][World space].
 * \param V The view vector [Normalized][World space].
 * \param L The light vector [Normalized][World space].
 * \param roughness The surface's roughness. Controls both the size and power of the specular highlight.
 */
inline float	GF_Schlick_GGX(float3 N, float3 L, float3 V, float roughness)
{
	float NdotV = saturate(dot(N, V));
	float NdotL = saturate(dot(N, L));
	float k = ((roughness + 1.0) * (roughness + 1.0)) / 8.0;
	float Gv = NdotV / (NdotV * (1.0 - k) + k);
	float Gl = NdotL / (NdotL * (1.0 - k) + k);
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