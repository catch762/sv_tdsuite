//*****************************
// SDF COMMON STUFF          //
//*****************************

//******************************************************************
// Parameters for this module and derived modules.
// Default values are defined here. If you want to override them,
// create 'myParams.glsl' or something, define the paramaters there,
// and include that file before including this 'sv_rm.glsl' file.
//******************************************************************
#ifndef SV_RM_PARAMETERS

#ifndef SDF_MAX_MARCH_STEPS
#define SDF_MAX_MARCH_STEPS 700
#endif

#ifndef SDF_MIN_DIST
#define SDF_MIN_DIST 0.0001
#endif

#ifndef SDF_MAX_DIST
#define SDF_MAX_DIST 6.0
#endif


#ifndef SDF_EPSILON
#define SDF_EPSILON 0.000001
#endif

#endif


//no need to override this one
#define SDF_OUTSIDE (SDF_MAX_DIST + 1)


//bool sdf_beyondrange(float dist) {return dist > SDF_MAX_DIST - SDF_EPSILON;}



#ifndef CORE_OPERATIONS_ON_SDF_DISTANCES
//***************************************************************
// Uni is union, adds two objects together.
// Sub takes first object and subtracts second object from it.
// Int intersects two objects.
//
// Sm variant does it smoothly (objects melt into each other),
// with provided smooth coefficient.
//***************************************************************
float sop_uni     	(float distA, float distB) { return min(distA, distB); }
float sop_sub 		(float distA, float distB) { return max(-distB,distA); }
float sop_int 		(float distA, float distB) { return max(distA, distB); }
float sop_uni_sm  	(float d1, float d2, float k) {float h = clamp(0.5 + 0.5 * (d2-d1)/k, 0.0, 1.0);return mix(d2, d1, h) - k * h * (1.0-h); }
float sop_sub_sm	(float d2, float d1, float k) {float h = clamp(0.5 - 0.5 * (d2+d1)/k, 0.0, 1.0);return mix(d2, -d1,h) + k * h * (1.0-h); }
float sop_int_sm	(float d1, float d2, float k) {float h = clamp(0.5 - 0.5 * (d2-d1)/k, 0.0, 1.0);return mix(d2, d1, h) + k * h * (1.0-h); }
vec2  sop_uni_sm2	(float a,  float b,  float k)
{
    float h = max( k-abs(a-b), 0.0 )/k;
    float m = h*h*0.5;
    float s = m*k*(1.0/2.0);
    return (a<b) ? vec2(a-s,m) : vec2(b-s,1.0-m);
}
#endif


#ifndef	ADVANCED_OPERATIONS_ON_SDF_DISTANCES
	
vec3 	sop_repl	(vec3 p, vec3 c )			{return mod(p + 0.5 * c,c) - 0.5 * c;}
vec3 	sop_repl	(vec3 p, float c, vec3 l)	{vec3 q = p-c*clamp(round(p/c),-l,l);return q;}
float 	sop_repl	(float p, float size, int idxmin, int idxmax, out int idx)
{
    int     thesign = p > 0 ? 1 : -1;
    int     halfidx = int(p / (size * 0.5));
    int     theidx  = (halfidx + thesign) / 2;
    
    theidx = clamp(theidx, min(idxmin, idxmax), max(idxmin, idxmax));
    
    float   inner   = p - theidx * size;
    
    idx = theidx;
    return  inner;
}
float 	sop_repl	(float p, float size, int idxmin, int idxmax){int idx = 0; return sop_repl(p, size, idxmin, idxmax, idx);}
vec3 	sop_repl	(vec3 p, vec3 size, ivec3 idxfrom, ivec3 idxto, out ivec3 idx)
{
    int     x_idx   = 0;
    float   x_inner = sop_repl(p.x, size.x, idxfrom.x, idxto.x, x_idx);
    int     y_idx   = 0;
    float   y_inner = sop_repl(p.y, size.y, idxfrom.y, idxto.y, y_idx);
    int     z_idx   = 0;
    float   z_inner = sop_repl(p.z, size.z, idxfrom.z, idxto.z, z_idx);

    idx             = ivec3(x_idx, y_idx, z_idx);
    return vec3(x_inner,y_inner,z_inner);
}
vec3 	sop_repl	(vec3 p, vec3 size, ivec3 idxfrom, ivec3 idxto){ivec3 idx = ivec3(0); return sop_repl(p, size, idxfrom, idxto, idx);}
//result.xyz is transformed p, and result.w has to be added to sdf() result
vec4 	sop_elong	(vec3 p, vec3 h ) {
    vec3 q = abs(p)-h;
    return vec4( max(q,0.0), min(max(q.x,max(q.y,q.z)),0.0) );
}
float 	sop_round   (float dist,    float radius)       { return dist - radius; }
float 	sop_onion   (float dist,    float thickness)    { return abs(dist) - thickness; }
float 	sop_onion	(float dist, float rounding, float thickness){ return abs(dist - rounding) - thickness; }
float 	sop_extrude (float dist2d,  float height, float pz) {
    //assumes dist2d was obtained with p.xy
    vec2 w = vec2( dist2d, abs(pz) - height );
    return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}
//return xy coord to try
vec2 	sop_revolve	(vec3 p, float offset)  { return vec2( length(p.xz) - offset, p.y ); }

#endif

	//------------//
	// TRANSFORMS //
	//------------//
mat4 m_rot(vec3 axis, float angle) {
    vec3  a     = normalize(axis);
    float s     = sin(angle);
    float c     = cos(angle);
    float oc    = 1.0 - c;
    float sx    = s * a.x;
    float sy    = s * a.y;
    float sz    = s * a.z;
    float ocx   = oc * a.x;
    float ocy   = oc * a.y;
    float ocz   = oc * a.z;
    float ocxx  = ocx * a.x;
    float ocxy  = ocx * a.y;
    float ocxz  = ocx * a.z;
    float ocyy  = ocy * a.y;
    float ocyz  = ocy * a.z;
    float oczz  = ocz * a.z;
    return mat4(
        vec4(ocxx + c, ocxy - sz, ocxz + sy, 0.0),
        vec4(ocxy + sz, ocyy + c, ocyz - sx, 0.0),
        vec4(ocxz - sy, ocyz + sx, oczz + c, 0.0),
        vec4( 0.0, 0.0, 0.0, 1.0) );
}
mat4 m_trans(vec3 pos) {
    return mat4(
        vec4(1, 0, 0, pos.x),
        vec4(0, 1, 0, pos.y),
        vec4(0, 0, 1, pos.z),
        vec4(0, 0, 0, 1) );
}
mat4 m_scale(vec3 sc) {
    return mat4(
        vec4(sc.x, 0, 0, 0),
        vec4(0, sc.y, 0, 0),
        vec4(0, 0, sc.z, 0),
        vec4(0, 0, 0, 1) );
}

vec3 makeNonParallelUpvec(vec3 vec)
{
    bool cameraDirLooksKindaLikeYAxis = abs(vec.y) > 0.99999;
    return cameraDirLooksKindaLikeYAxis ? 	vec3(0, 0, 1) :
											vec3(0, 1, 0);
}

void makeUpAndRightVec(vec3 dir, float rollRad, out vec3 rolledRight, out vec3 rolledUp)
{
	vec3 worldUp 	= makeNonParallelUpvec(dir);
	
	// Initial right and up (no roll yet)
	vec3 right 		= normalize(cross(worldUp, dir));
	vec3 up 		= normalize(cross(dir, 	 right));

	// Apply roll: rotate (right, up) around 'dir' by 'rollRad'
	float c = cos(rollRad);
	float s = sin(rollRad);

	rolledRight 	= right * c + up 	* s;
	rolledUp 		= up 	* c - right * s;
}


mat4 m_view(vec3 eye, vec3 lookat, vec3 upvec)
{
    //assumes that the center of the camera (lookat) is aligned with the negative z axis in
    //view space. Based on gluLookAt man page
	
    vec3 forwardDir = normalize(lookat - eye);
    vec3 rightDir 	= normalize(cross(forwardDir, upvec));
    vec3 upDir 		= cross(rightDir, forwardDir);
	
    return mat4(
        vec4(rightDir, 		0.0),
        vec4(upDir, 		0.0),
        vec4(-forwardDir, 	0.0),
        vec4(0.0, 0.0, 0.0, 1.0)
    );
}

mat4 m_view(vec3 eye, vec3 lookat, float roll)
{
    //assumes that the center of the camera (lookat) is aligned with the negative z axis in
    //view space. Based on gluLookAt man page
	
    vec3 forwardDir = normalize(lookat - eye);
	
	vec3 rolledRight, rolledUp;
	makeUpAndRightVec(forwardDir, roll, rolledRight, rolledUp);
	
    return mat4(
        vec4(rolledRight, 	0.0),
        vec4(rolledUp, 		0.0),
        vec4(-forwardDir, 	0.0),
        vec4(0.0, 0.0, 0.0, 1.0)
    );
}
vec3 inv_mdl_trans(vec3 point, vec3 trans, vec4 rot, vec3 scale)
{
    mat4 invmodel = inverse(m_scale(scale) * m_rot(rot.xyz, rot.w) * m_trans(trans));
    return (vec4(point, 1.0) * invmodel).xyz;
}
vec3 inv_mdl_rotate(vec3 point, vec4 rot)
{
    mat4 invmodel = inverse(m_rot(rot.xyz, rot.w));
    return (vec4(point, 1.0) * invmodel).xyz;
}

	//---------------//
	// UNCATEGORIZED //
	//---------------//
	
struct Ray
{
	vec3 origin;
	vec3 dir;
};
vec3 walkray(Ray ray, float dist) {return ray.origin + ray.dir * dist;}
	
float 	dot2		( in vec2 v ) { return dot(v,v); }
float 	dot2		( in vec3 v ) { return dot(v,v); }
float 	ndot		( in vec2 a, in vec2 b ) { return a.x*b.x - a.y*b.y; }
float 	sdf_scalefix(vec3 scale){return min(scale.x, min(scale.y, scale.z));}
vec3 	ray_dir		(float Y_fov_degrees, vec2 resolution, vec2 pixel_coord) {
    vec2    xy  = pixel_coord - resolution / 2.0;
    float   z   = resolution.y / tan(radians(Y_fov_degrees) / 2.0);
    return 	normalize(vec3(xy, -z));
}

vec3 	ray_dir(float Y_fov_degrees)
{
	return ray_dir(Y_fov_degrees, agn_resolution(), gl_FragCoord.xy);
}

Ray worldray_for_pixel(vec2 pixCoord, vec2 resolution, vec3 eye, vec3 lookat, float fov)
{
	vec3    dir         = ray_dir(fov, resolution, pixCoord);
	vec3    dir_world   = ( m_view(eye,lookat,vec3(0,1,0)) * vec4(dir,0) ).xyz; //todo upvec?
	return 	Ray(eye, dir_world);
}
Ray worldray_for_pixel(vec2 pixCoord, vec2 resolution, vec3 eye, vec3 lookat, float fov, float roll)
{
	vec3    dir         = ray_dir(fov, resolution, pixCoord);
	vec3    dir_world   = ( m_view(eye,lookat,roll) * vec4(dir,0) ).xyz; //todo upvec?
	return 	Ray(eye, dir_world);
}



#define ADD(mat) RES = sop_uni(RES, (mat));
#define ADDSM(mat, SM_K) RES = sop_uni_sm(RES, (mat), SM_K);
#define SUB(mat) RES = sop_sub(RES, (mat));
#define ADD2(mat, R) R = sop_uni(R, (mat));




//This shit doesnt really work or maybe it does but im keeping it for legacy

float IQ_rep_kaleid_unl_getIdx(vec2 p_xz, int Subdivs)
{
    const float b = 6.283185/float(Subdivs);
    float a = atan(p_xz.y,p_xz.x);
    float i = floor(a/b);

	return i;
}

//can use unfixed idx fyi
vec2 IQ_rep_kaleid_unl_applyIdx(vec2 p_xz, int Subdivs, float idx)
{
	const float b = 6.283185/float(Subdivs);
	float c = b * idx;
	return mat2(cos(c),-sin(c),sin(c), cos(c))*p_xz;
}
vec3 IQ_rep_kaleid_unl_applyIdx(vec3 p, int Subdivs, float idx)
{
	p.xz = IQ_rep_kaleid_unl_applyIdx(p.xz, Subdivs, idx);
	return p;
}

//fix idx before using it to add difference in elems, or will have issues with wrapping, diff values for same idx
float IQ_rep_kaleid_unl_fixIdx(float idx, int subdivs)
{
	int wrappedidx 	= int(idx) + subdivs/2 + (subdivs%2==1 ? (1) : 0);
	wrappedidx 		= wrappedidx % subdivs;
	return float(wrappedidx);
}

//one sdf call works. bilateral means every copy left/right mirrored
vec3 sop_repl_radial_bilateral(vec3 point, int subdivisions)
{
    float angle = atan(point.z, point.x);
  
    float sectorAngle = 2.0 * PI / float(max(1, subdivisions));
    float halfSector = sectorAngle * 0.5;
    // Wrap angle to [-PI, PI] range
    angle = mod(angle + PI, 2.0 * PI) - PI;
    // Fold angle into the range [-halfSector, halfSector]
    angle = mod(angle + halfSector, sectorAngle) - halfSector;
    
    angle = abs(angle);
    
    float radius = length(vec2(point.x, point.z));
    
    // Reconstruct the point in the folded sector
    vec3 result;
    result.x = radius * cos(angle);
    result.z = radius * sin(angle);
    result.y = point.y;
    
    return result;
}


//**********************
//	MATERIAL SECTION
//**********************
#ifndef SDFINTERM_MATERIAL_SECTION

//*************************************************************************************
//
// The material struct is not defined here. It should be defined in the actual project.
// It should look like:
//
// 	struct MyProjectMaterial {
//		float dist; //the only mandatory field
//	}
//
// Then you just pass this type name to macros below to generate additional functions.
// All macros refer to this type as 'MT'.
//
// On additional note: macro parameter 'SDFFUNCNAME' implies function 
// which takes 'vec3 p' and returns 'MT'.
//
//*************************************************************************************

#define DECL_SOPUNI(MT) 		MT sop_uni(MT A, MT B) { return A.dist < B.dist ? A : B; }
#define DECL_SOPSUB(MT) 		MT sop_sub(MT A, MT B) { A.dist = sop_sub(A.dist, B.dist); return A; }
#define DECL_SOPINT(MT) 		MT sop_int(MT A, MT B) { return A.dist > B.dist ? A : B; }
#define DECL_SOPUNI_SM(MT) 		MT sop_uni_sm(MT A, MT B, float k) {		\
									float d = sop_uni_sm(A.dist,B.dist,k);	\
									if(A.dist<B.dist){A.dist=d;return A;}	\
									else			 {B.dist=d;return B;}	\
								}
#define DECL_SOPINT_SM(MT) 		MT sop_int_sm(MT A, MT B, float k) {		\
									float d = sop_int_sm(A.dist,B.dist,k);	\
									if(A.dist>B.dist){A.dist=d;return A;}	\
									else			 {B.dist=d;return B;}	\
								}
#define DECL_SOPSUB_SM(MT) 		MT sop_sub_sm(MT A, MT B, float k) {		\
									float d = sop_sub_sm(A.dist,B.dist,k);	\
									A.dist=d;								\
									return A;								\
								}

#define DECL_SOPS(MT) 		DECL_SOPUNI(MT) 	\
							DECL_SOPSUB(MT) 	\
							DECL_SOPINT(MT) 	\
							DECL_SOPUNI_SM(MT) 	\
							DECL_SOPSUB_SM(MT)	\
							DECL_SOPINT_SM(MT)

#define M_ATCONSTR(MT) 		MT MT ## _at(float dist){ MT mat; mat.dist = dist; return mat;} 
#define DECL_MATERIAL(MT)  	M_ATCONSTR(MT) DECL_SOPS(MT)

#define DECL_MARCH(MT, SDFFUNCNAME)							\
MT SDFFUNCNAME##_march(Ray ray, float start, float end) {	\
		float depth = start;								\
		for (int i = 0; i < SDF_MAX_MARCH_STEPS; i++) {		\
			MT mat = SDFFUNCNAME(walkray(ray, depth));		\
			if (mat.dist < SDF_EPSILON) 					\
			{mat.dist = depth;return mat;}					\
			depth += mat.dist;								\
			if (depth >= end) break;						\
		}													\
		return MT##_at(end);								\
	}

//step01: how many steps we travelled
#define DECL_MARCH_WITH_STEP01(MT, SDFFUNCNAME)											\
MT SDFFUNCNAME##_march(Ray ray, float start, float end, out float step01) {				\
		float depth = start;															\
		for (int i = 0; i < SDF_MAX_MARCH_STEPS; i++) {									\
			MT mat = SDFFUNCNAME(walkray(ray, depth));									\
			if (mat.dist < SDF_EPSILON)													\
			{step01 = i / float(SDF_MAX_MARCH_STEPS-1);mat.dist = depth;return mat;}	\
			depth += mat.dist;															\
			if (depth >= end) break;													\
		}																				\
		step01 = 1.0;																	\
		return MT##_at(end);															\
	}

#define GET_HIT11_FUNC_NAME(SDFFUNCNAME) SDFFUNCNAME ## _march_gethit11

//'hit11 value': if there is a hit, its [0.0 if was at start, 1.0 if was at end]. If no hit, then its -1.0
#define DECL_MARCH_GETHIT11(SDFFUNCNAME)									\
float GET_HIT11_FUNC_NAME(SDFFUNCNAME) (Ray ray, float start, float end){	\
	float depth = start;													\
    for (int i = 0; i < SDF_MAX_MARCH_STEPS; i++) {							\
        float dist = SDFFUNCNAME(walkray(ray, depth)).dist;					\
        if (dist < SDF_EPSILON) 											\
		{return clampphase(depth, start, end);}								\
        depth += dist;														\
        if (depth >= end) break;											\
    }																		\
    return -1.0;															\
}

#define DECL_NORMAL(SDFFUNCNAME)								\
vec3 SDFFUNCNAME##_normal(vec3 p){								\
    vec2 	e = vec2(1.0,-1.0)*SDF_EPSILON;						\
	float 	a = SDFFUNCNAME(p + e.xyy).dist;					\
	float 	b = SDFFUNCNAME(p + e.yyx).dist;					\
	float 	c = SDFFUNCNAME(p + e.yxy).dist;					\
	float 	d = SDFFUNCNAME(p + e.xxx).dist;					\
	return 	normalize(a*e.xyy + b*e.yyx + c*e.yxy + d*e.xxx);	\
}

#define DECL_NORM_MARCH(MT, SDFFUNCNAME) DECL_MARCH(MT, SDFFUNCNAME) DECL_NORMAL(SDFFUNCNAME)

#endif


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


//Uncategorized utils, idk

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