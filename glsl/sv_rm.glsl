#include "sv_rm_core_glsl"
#include "sv_rm_repl_glsl"
#include "sv_rm_primitives_glsl"
#include "sv_rm_iqn_glsl"
#include "sv_rm_water_glsl"


//**********************
//	EXAMPLE SECTION
//**********************
#ifdef SDFINTERM_EXAMPLE_SECTION
struct M1
{
	float dist;
};
DECL_MATERIAL(M1)

M1 sdf_example(vec3 p)
{
	p = sop_repl(p, vec3(2));
	
	M1 a = M1_at( sdf_box	(sop_repl(p, vec3(3)), vec3(0.8)) );
	M1 b = M1_at( sdf_sphere(sop_repl(p, vec3(3.85)), .28) );
	
	return sop_int(a, b);
}
DECL_NORM_MARCH(M1, sdf_example)

vec4 example_main(Ray ray)
{
	//this func made by macro
    M1    	mat     = sdf_example_march(ray, SDF_MIN_DIST, SDF_MAX_DIST);
    float   dist    = mat.dist;    
    vec3    p   	= walkray(ray, dist);
   
    if (dist > SDF_MAX_DIST - SDF_EPSILON)
    {
		return vec4(0);
    }
	
    //this func made by macro
    vec3    n       = sdf_example_normal(p);
	
	return vec4(nsin01(n + p - n * p), 1);
}

vec4 example_master(vec4 pix_ndc)
{
	vec3    eye         = vec3(1,1,1);
	vec3 	lookat		= vec3(0,0,0);
	vec3    dir         = ray_dir(55.0, agn_resolution(), pix_ndc.xy);
	vec3    dir_world   = ( m_view(eye,lookat,vec3(0,1,0)) * vec4(dir,0) ).xyz; //todo upvec?
	
	return example_main(Ray(eye, dir_world));
}

#endif