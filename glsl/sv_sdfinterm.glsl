//***********************************
// THIS WILL MOVE TO COMMON LATER  //
//***********************************
const int   SDF_MAX_MARCH_STEPS = 1000;
const float SDF_MIN_DIST        = 0.0001;
const float SDF_MAX_DIST        = 12.5; //2.5 
const float SDF_OUTSIDE         = SDF_MAX_DIST + 1;
const float SDF_EPSILON         = 0.000001;

bool sdf_beyondrange(float dist) {return dist > SDF_MAX_DIST - SDF_EPSILON;}

//************
// MATERIAL //
//************

#define SOP_ADD 0
#define SOP_SUB 1
#define SOP_INT 2
#define SOP_A 3
#define SOP_B 4

#define DECL_SOPUNI(T) 		T sop_uni(T A, T B) { return A.dist < B.dist ? A : B; }
#define DECL_SOPSUB(T) 		T sop_sub(T A, T B) { A.dist = sop_sub(A.dist, B.dist); return A; }
#define DECL_SOPINT(T) 		T sop_int(T A, T B) { return A.dist > B.dist ? A : B; }
#define DECL_SOPUNI_SM(T) 	T sop_uni_sm(T A, T B, float k) {float d = sop_uni_sm(A.dist,B.dist,k);if(A.dist<B.dist){A.dist=d;return A;}else{B.dist=d;return B;}}
#define DECL_SOPINT_SM(T) 	T sop_int_sm(T A, T B, float k) {float d = sop_int_sm(A.dist,B.dist,k);if(A.dist>B.dist){A.dist=d;return A;}else{B.dist=d;return B;}}
#define DECL_SOPSUB_SM(T) 	T sop_sub_sm(T A, T B, float k) {float d = sop_sub_sm(A.dist,B.dist,k);A.dist=d;return A;}
#define DECL_MULTIOP_SM(T) T sop_multiop_sm(T A, T B, int sop_type, float K){	\
	if 		(sop_type == SOP_ADD) return sop_uni_sm(A,B,K);						\
	else if (sop_type == SOP_SUB) return sop_sub_sm(A,B,K);						\
	else if (sop_type == SOP_INT) return sop_int_sm(A,B,K);						\
	else if (sop_type == SOP_A)   return A;										\
	else 						  return B;}

#define DECL_SOPS(T) 		DECL_SOPUNI(T) DECL_SOPSUB(T) DECL_SOPINT(T) DECL_SOPUNI_SM(T) DECL_SOPINT_SM(T) DECL_SOPSUB_SM(T) DECL_MULTIOP_SM(T)

#define DECL_MATERIAL(T)  	M_ATCONSTR(T) DECL_SOPS(T)
#define M_ATCONSTR(T) 		T T ## _at(float dist){ T mat; mat.dist = dist; return mat;} 

#define DECL_MARCH(T, NAME)	T NAME##_march(Ray ray, float start, float end) {	\
	float depth = start;														\
    for (int i = 0; i < SDF_MAX_MARCH_STEPS; i++) {								\
        T mat = NAME(walkray(ray, depth));										\
        if (mat.dist < SDF_EPSILON) {mat.dist = depth;return mat;}				\
        depth += mat.dist;														\
        if (depth >= end) return T##_at(end);									\
    }																			\
    return T##_at(end);															\
}
#define DECL_NORMAL(NAME)	vec3 NAME##_normal(vec3 p){			\
    vec2 	e = vec2(1.0,-1.0)*SDF_EPSILON;						\
	float 	a = NAME(p + e.xyy).dist;							\
	float 	b = NAME(p + e.yyx).dist;							\
	float 	c = NAME(p + e.yxy).dist;							\
	float 	d = NAME(p + e.xxx).dist;							\
	return 	normalize(a*e.xyy + b*e.yyx + c*e.yxy + d*e.xxx);	\
}
#define DECL_NORM_MARCH(T, NAME) DECL_MARCH(T, NAME) DECL_NORMAL(NAME)

struct M1
{
	float dist;
};
DECL_MATERIAL(M1)

/*M1 UNUSED_example_march(Ray ray, float start, float end) {
	float depth = start;
    for (int i = 0; i < SDF_MAX_MARCH_STEPS; i++) {
        M1 mat = example(walkray(ray, depth));
        if (mat.dist < SDF_EPSILON) {mat.dist = depth;return mat;}
        depth += mat.dist;
        if (depth >= end) return M1_at(end);
    }
    return M1_at(end);
}
vec3 UNUSED_example_normal(vec3 p){
    vec2 	e = vec2(1.0,-1.0)*SDF_EPSILON;
	float 	a = example(p + e.xyy).dist;
	float 	b = example(p + e.yyx).dist;
	float 	c = example(p + e.yxy).dist;
	float 	d = example(p + e.xxx).dist;
	return 	normalize(a*e.xyy + b*e.yyx + c*e.yxy + d*e.xxx);
}*/
M1 example(vec3 p)
{
	p = sop_repl(p, vec3(2));
	
	M1 a = M1_at( sdf_box	(sop_repl(p, vec3(3)), vec3(0.8)) );
	M1 b = M1_at( sdf_sphere(sop_repl(p, vec3(3.85)), .28) );
	
	return sop_int(a, b);
}
DECL_NORM_MARCH(M1, example)

vec4 example_main(Ray ray, vec4 pix_ndc)
{
    M1    	mat     = example_march(ray, SDF_MIN_DIST, SDF_MAX_DIST);
    float   dist    = mat.dist;    
    vec3    p   	= walkray(ray, dist);
   
    if (dist > SDF_MAX_DIST - SDF_EPSILON)
    {
		return vec4(0);
    }
     
    vec3    n       = example_normal(p);
	
	return vec4(nsin01(n + p - n * p), 1);
}
/*vec4 example_master(vec4 pix_ndc)
{
	vec3    eye         = rmt_camera.xyz;
	vec3 	lookat		= vec3(0,0,0);
	vec3    dir         = ray_dir(45.0 * rmt_camera.w, agn_resolution(), pix_ndc.xy);
	vec3    dir_world   = ( m_view(eye,lookat,vec3(0,1,0)) * vec4(dir,0) ).xyz; //todo upvec?
	
	return example_main(Ray(eye, dir_world), pix_ndc);
}*/

//////////////////////////

mat4 m_persp(float fovy, float aspect, float zNear, float zFar)
{
	float tanHalfFovy = tan(fovy / 2.0);

	mat4 Result = mat4(0.0);
	
	Result[0][0] = 1.0 / (aspect * tanHalfFovy);
	Result[1][1] = 1.0 / (tanHalfFovy);
	Result[2][2] = - (zFar + zNear) / (zFar - zNear);
	Result[2][3] = - 1.0;
	Result[3][2] = - (2.0 * zFar * zNear) / (zFar - zNear);
		
	return Result;
}
mat4 iq_cam( in vec3 ro, in vec3 ta, float croll )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(croll), cos(croll),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat4( cu.x, cu.y, cu.z, 0.0,
                 cv.x, cv.y, cv.z, 0.0,
                 cw.x, cw.y, cw.z, 0.0,
                 ro.x, ro.y, ro.z, 1.0 );
}
mat4 m_viewproj(vec3 eye, vec3 lookat, float fovy, float aspect, float roll)
{
	mat4 	persp 		= m_persp(fovy, aspect, 0.01, 1000);
	vec3	invlookat 	= eye * 2.0 - lookat;
	mat4 	w2c 		= inverse( iq_cam(eye, invlookat, roll) );
	return 	persp * w2c;
}
mat4 m_viewproj(Ray ray, float fovy, float aspect, float roll)
{
	mat4 	persp 		= m_persp(fovy, aspect, 0.01, 1000);
	vec3	invlookat 	= ray.origin * 2.0 - ray.dir;
	mat4 	w2c 		= inverse( iq_cam(ray.origin, invlookat, roll) );
	return 	persp * w2c;
}
vec3 worldtoscreenndc(vec3 worldpos, mat4 viewproj) //.z = 1 if in frustum, else -1 (in this case .xy is likely garbage)
{
	vec4 	scr 		= viewproj * vec4(worldpos,1.0);
	float	absw 		= abs(scr.w);
	bool 	infrustum 	= abs(scr.x) < absw && abs(scr.y) < absw && abs(scr.z) < absw;
	vec2 	s			= scr.xy/scr.z;
	return 	vec3(scr.xy/scr.z, infrustum ? 1.0 : -1.0);
}
vec3 worlddir(vec2 px, float fov, vec3 eye, vec3 lookat)
{
	vec3    camdir		= ray_dir(fov, agn_resolution(), px);
	vec3    dir_world   = ( m_view(eye,lookat,vec3(0,1,0)) * vec4(camdir,0) ).xyz; //todo upvec?
	return 	dir_world;
}

