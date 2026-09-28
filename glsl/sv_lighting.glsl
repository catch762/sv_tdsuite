//*****************************
// 	SV_LIGHTING
//
//	Depends on: sv_common
//				sv_sup
//*****************************

//*************************************************
// Part 1: Actual Blinn-phong material and lighting
//*************************************************

//The Blinn-phong material
#define STRMETA_BPM(V,N) STRMAIN_ARG3(BPM,V,N,		\
vec4, 	basecolor,				ui("color = []")	\
vec4, 	speccolor,				ui("color = []")	\
vec2, 	RoughnessRefraction)	ui("lims=[0, 2, 1]")	
STRDECL(BPM)

vec3 bpm_lighting(vec3 n, vec3 rd, vec3 l, vec3 kl, vec3 kd, vec3 ks, float km, float kn)
{
	// n -> normal
	// l -> light direction
	// rd -> ray direction
	// kl -> light color
	// kd -> diffuse color
	// ks -> specular color
	// km -> roughness / microfacet amount
	// kn -> refraction index

    float ndl = clamp(dot(n, l), 0., 1.); // diffuse/lambert / N⋅L
    
	vec3 h = normalize(l - rd); // half vector
    float ndh = max(dot(n, h), 0.0);
    
    // ggx / Trowbridge and Reitz specular model approximation
    float g = ndh*ndh * (km*km - 1.) + 1.;
    float ggx = km*km / (3.141592*g*g);

    // shlick approximation
    float fre = 1.+dot(rd, n); // fresnel
	
    // fresnel amount
    float f0 = (kn-1.)/(kn+1.);
          f0 = f0*f0;
    float kr = f0 + (1.-f0)*(1.-km)*(1.-km) * pow(fre, 5.); // reflectivity
    
    return kl*ndl*(kd + ks*kr*ggx); // diffuse + specular
}

vec3 bpm_lighting(vec3 normal, vec3 raydir, vec3 lightdir, vec3 lightcolor, BPM mat)
{
	vec3 	kd = mulw(mat.basecolor);
	vec3 	ks = mulw(mat.speccolor);
	float 	km = mat.RoughnessRefraction.x;
	float 	kn = mat.RoughnessRefraction.y;
	
	return bpm_lighting(normal, raydir, lightdir, lightcolor, kd, ks, km, kn);
}


//****************************************************************************
// Part 2: Some common code for lighting. Controversial and subject to change.
//****************************************************************************

#define STRMETA_Light(V,N) STRMAIN_ARG4(Light,V,N,	\
vec4, 	pos,			ui("lims=[-1,1,0]")				\
float, 	radius,			ui("lims=[0.5, 2, 2]")		\
vec4, 	color,			ui("color = []")			\
float, 	intensity01)	ui("lims=[0, 25, 5]")
STRDECL(Light)

float lightintensity_rangefactor(Light light, vec3 p)
{
	float   rangefactor01   = 1.0 - clamp01(distance(mulw(light.pos), p) / light.radius);
	return rangefactor01 * rangefactor01 * light.intensity01;
}	

//'hit11 value': if there is a hit, its [0.0 if was at start, 1.0 if was at end]. If no hit, then its -1.0
//'obstacleLightModRange': 	x is light01 when obstacle is at the light source (hit11 = 0)
//							y is light01 when obstacle is at the light destination (hit11 = 1)
float getObstacleFactoredLight01(float hit11_toObstacle, vec2 obstacleLightModRange01)
{
	//We return this if hit11_toObstacle = [0, 1] (there was obstacle somewhere)
	float light01_for_hit = mix(obstacleLightModRange01.x, obstacleLightModRange01.y, hit11_toObstacle);
	
	//We return this if hit11_toObstacle = -1 (there was no shadow, so full brightness)
	float light01_for_no_hit = 1.0;
	
	//Branchless if selector
	float zero_if_no_hit_one_if_hit = sign(hit11_toObstacle + 0.5) * 0.5 + 0.5;
	
	return mix(light01_for_no_hit, light01_for_hit, zero_if_no_hit_one_if_hit);
}



//see DECL_MARCH_GETHIT11 in sv_sdfinterm for first function
#define MAKE_LIGHTCONTRIBUTION_FUNC(SDFNAME, SHADOWS_ENABLED_FLAG) 							\
	vec3 SDFNAME ## _getlightcontribution_withshadow(Light light, vec3 p, 					\
	vec3 n, vec3 raydir, BPM bpm, vec2 obstacleLightModRange01)								\
	{																						\
		float rangeintensity  = lightintensity_rangefactor(light, p);						\
		if (rangeintensity < 0.00001) return vec3(0);										\
																							\
		vec3 dir2light = normalize(mulw(light.pos)-p);										\
		Ray ray = Ray(p, dir2light);														\
																							\
		float obstacleFactor01 = 1.0; /* 0 full shadow, 1 no shadow */						\
																							\
		if(SHADOWS_ENABLED_FLAG == 1)														\
		{																					\
			float hit11 = GET_HIT11_FUNC_NAME(SDFNAME) (									\
				ray,mindist(),distance(ray.origin, mulw(light.pos)));						\
			obstacleFactor01 = getObstacleFactoredLight01(hit11, obstacleLightModRange01);	\
		}																					\
																							\
		return obstacleFactor01 * 															\
			bpm_lighting(n, raydir, dir2light, mulw(light.color) * rangeintensity, bpm);	\
	}

//************************************************
// Part 3: Just some collections of some materials
//************************************************

//Makes function which takes 'int id' which can be any value and returns material from array
#define MAKE_MATGETTER_FUNC(ARRAYNAME, ARRAYSIZE) 	BPM ARRAYNAME ## _get(int unconstrainedId) {			\
														return ARRAYNAME[ abs(unconstrainedId)%ARRAYSIZE ]; \
													}

// Default materials collection
BPM iron      = BPM(vec4(0.6, 0.6, 0.6, 1.0), vec4(0.1, 0.1, 0.1, 1.0), vec2(0.5, 1.5));      
BPM dirt      = BPM(vec4(0.4, 0.3, 0.1, 1.0), vec4(0.02, 0.02, 0.02, 1.0), vec2(0.8, 1.3));   
BPM mirror    = BPM(vec4(0.0, 0.0, 0.0, 1.0), vec4(1.0, 1.0, 1.0, 1.0), vec2(0.01, 1.0));     
BPM glass     = BPM(vec4(0.01, 0.01, 0.01, 1.0), vec4(0.9, 0.9, 0.9, 1.0), vec2(0.05, 1.5));  
BPM grass     = BPM(vec4(0.13, 0.3, 0.05, 1.0), vec4(0.03, 0.07, 0.03, 1.0), vec2(0.6, 1.33));
BPM plastic   = BPM(vec4(0.5, 0.5, 0.5, 1.0), vec4(0.3, 0.3, 0.3, 1.0), vec2(0.25, 1.49));    
BPM gold      = BPM(vec4(1.0, 0.8, 0.1, 1.0), vec4(1.0, 0.8, 0.1, 1.0), vec2(0.1, 0.47));     
BPM silver    = BPM(vec4(0.7, 0.7, 0.7, 1.0), vec4(0.9, 0.9, 1.0, 1.0), vec2(0.18, 0.15));    
BPM copper    = BPM(vec4(0.9, 0.4, 0.22, 1.0), vec4(0.9, 0.4, 0.22, 1.0), vec2(0.25, 0.26));  
BPM wood      = BPM(vec4(0.5, 0.34, 0.13, 1.0), vec4(0.1, 0.1, 0.09, 1.0), vec2(0.6, 1.55));  
BPM stone     = BPM(vec4(0.4, 0.4, 0.45, 1.0), vec4(0.1, 0.1, 0.1, 1.0), vec2(0.65, 1.55));   
BPM marble    = BPM(vec4(0.8, 0.8, 0.8, 1.0), vec4(0.5, 0.5, 0.5, 1.0), vec2(0.18, 1.49));    
BPM water     = BPM(vec4(0.01, 0.01, 0.05, 1.0), vec4(0.2, 0.2, 0.2, 1.0), vec2(0.05, 1.33)); 
BPM skin      = BPM(vec4(1.0, 0.76, 0.65, 1.0), vec4(0.10, 0.06, 0.05, 1.0), vec2(0.8, 1.38));
BPM asphalt   = BPM(vec4(0.07, 0.07, 0.07, 1.0), vec4(0.01, 0.01, 0.01, 1.0), vec2(0.6, 1.6));
BPM chrome    = BPM(vec4(0.55, 0.57, 0.58, 1.0), vec4(0.99, 0.99, 0.99, 1.0), vec2(0.08, 1.0));
BPM aluminum  = BPM(vec4(0.77, 0.77, 0.77, 1.0), vec4(0.9, 0.92, 0.98, 1.0), vec2(0.07, 1.45));
BPM ceramic   = BPM(vec4(0.85, 0.78, 0.68, 1.0), vec4(0.3, 0.3, 0.3, 1.0), vec2(0.3, 1.54));   
BPM paper     = BPM(vec4(0.9, 0.9, 0.8, 1.0), vec4(0.1, 0.1, 0.09, 1.0), vec2(0.45, 1.47));    
BPM rubber    = BPM(vec4(0.02, 0.02, 0.02, 1.0), vec4(0.05, 0.05, 0.05, 1.0), vec2(0.9, 1.51));

#define DEFAULTMATS_COUNT 19
//Removed mirror
BPM defaultmats[DEFAULTMATS_COUNT] = {
		iron, dirt, marble, glass, grass, plastic, gold, silver, copper, wood,
		stone, water, skin, asphalt, chrome, aluminum, ceramic, paper, rubber
	};
MAKE_MATGETTER_FUNC(defaultmats, DEFAULTMATS_COUNT)

// Plants materials collection
BPM grass_vivid     = BPM(vec4(0.16, 0.35, 0.07, 1.0), vec4(0.03, 0.08, 0.04, 1.0), vec2(0.5, 1.38));  
BPM clover_leaf     = BPM(vec4(0.20, 0.46, 0.15, 1.0), vec4(0.02, 0.06, 0.02, 1.0), vec2(0.5, 1.42));  
BPM fern            = BPM(vec4(0.13, 0.33, 0.14, 1.0), vec4(0.03, 0.06, 0.03, 1.0), vec2(0.5, 1.41));  
BPM bamboo_leaf     = BPM(vec4(0.28, 0.52, 0.15, 1.0), vec4(0.05, 0.07, 0.01, 1.0), vec2(0.4, 1.44));  
BPM spinach_leaf    = BPM(vec4(0.21, 0.40, 0.18, 1.0), vec4(0.03, 0.09, 0.03, 1.0), vec2(0.55, 1.40)); 
BPM moss            = BPM(vec4(0.24, 0.40, 0.12, 1.0), vec4(0.03, 0.09, 0.04, 1.0), vec2(0.65, 1.39)); 
BPM lettuce_leaf    = BPM(vec4(0.30, 0.68, 0.24, 1.0), vec4(0.05, 0.10, 0.02, 1.0), vec2(0.45, 1.36)); 
BPM water_lily_leaf = BPM(vec4(0.17, 0.33, 0.08, 1.0), vec4(0.09, 0.17, 0.06, 1.0), vec2(0.38, 1.32)); 
BPM ivy_leaf        = BPM(vec4(0.11, 0.23, 0.09, 1.0), vec4(0.04, 0.10, 0.04, 1.0), vec2(0.52, 1.46)); 
BPM cactus_skin     = BPM(vec4(0.18, 0.36, 0.14, 1.0), vec4(0.09, 0.11, 0.08, 1.0), vec2(0.62, 1.48)); 
BPM withered_leaf   = BPM(vec4(0.23, 0.28, 0.13, 1.0), vec4(0.03, 0.05, 0.02, 1.0), vec2(0.68, 1.47)); 
BPM autumn_leaf     = BPM(vec4(0.65, 0.30, 0.10, 1.0), vec4(0.09, 0.07, 0.04, 1.0), vec2(0.72, 1.45)); 
BPM yellow_leaf     = BPM(vec4(0.72, 0.67, 0.13, 1.0), vec4(0.10, 0.12, 0.01, 1.0), vec2(0.77, 1.43)); 
BPM red_maple_leaf  = BPM(vec4(0.73, 0.21, 0.17, 1.0), vec4(0.10, 0.09, 0.06, 1.0), vec2(0.70, 1.44)); 
BPM poppy_petal     = BPM(vec4(0.94, 0.35, 0.15, 1.0), vec4(0.11, 0.08, 0.05, 1.0), vec2(0.58, 1.39)); 
BPM marigold_petal  = BPM(vec4(0.98, 0.62, 0.12, 1.0), vec4(0.14, 0.13, 0.03, 1.0), vec2(0.62, 1.37)); 
BPM sunflower_petal = BPM(vec4(0.97, 0.85, 0.20, 1.0), vec4(0.13, 0.16, 0.05, 1.0), vec2(0.60, 1.41)); 
BPM lily_petal      = BPM(vec4(0.98, 0.95, 0.92, 1.0), vec4(0.18, 0.17, 0.16, 1.0), vec2(0.64, 1.36)); 
BPM dried_leaf 		= BPM(vec4(0.62, 0.48, 0.21, 1.0), vec4(0.07, 0.06, 0.03, 1.0), vec2(0.67, 1.41)); 
BPM daisy_petal     = BPM(vec4(0.96, 0.93, 0.89, 1.0), vec4(0.15, 0.15, 0.15, 1.0), vec2(0.70, 1.52)); 

#define PLANTMATS_COUNT 20
BPM plantmats[PLANTMATS_COUNT] = { 
		grass_vivid, clover_leaf, fern, bamboo_leaf, spinach_leaf, moss, lettuce_leaf, water_lily_leaf,
		ivy_leaf, cactus_skin, withered_leaf, autumn_leaf, yellow_leaf, red_maple_leaf, poppy_petal,
		marigold_petal, sunflower_petal, lily_petal, dried_leaf, daisy_petal 
	};
MAKE_MATGETTER_FUNC(plantmats, PLANTMATS_COUNT)
								
// Derived material collections: selected mats that are good
#define COOLMATS_COUNT 8
BPM coolmats[COOLMATS_COUNT] = {stone, iron, ceramic, silver, skin, copper, marble, silver};
MAKE_MATGETTER_FUNC(coolmats, COOLMATS_COUNT)