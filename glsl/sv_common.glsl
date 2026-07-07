//The only two uniforms here
uniform float  time;
//below: uniform int ds_chselector;

//**********************
// PREPROCESSOR STUFF //
//**********************
#define PI 3.14159265359
#define SV_SHOWAXES
#define VECTORIZE_V2(f) vec2 f(vec2 v){ return vec2(f(v.x), f(v.y)); 					}
#define VECTORIZE_V3(f) vec3 f(vec3 v){ return vec3(f(v.x), f(v.y), f(v.z)); 			}
#define VECTORIZE_V4(f) vec4 f(vec4 v){ return vec4(f(v.x), f(v.y), f(v.z), f(v.w)); 	}
#define VECTORIZE(f) 	VECTORIZE_V2(f) VECTORIZE_V3(f) VECTORIZE_V4(f)

//********************
// COMMON FUNCTIONS //
//********************
vec2    agn_resolution  (){return uTDOutputInfo.res.zw;}
vec2    agn_uv          (){return vUV.st;}

float   aspect          (){return float(agn_resolution().x) / float(agn_resolution().y);}
float   myfractpart     (float f){return f - int(f);}
float   lim_fold        (float from, float to, float arg)
{
    bool closer2from = arg - from < arg - to;
    float outside = closer2from ? arg - from : arg - to;

    float arg_in_01space = outside / (to - from);
    bool even = int(arg_in_01space) % 2 == 0;
    float place01 = !even ? abs(myfractpart(arg_in_01space)) : 1.0 - abs(myfractpart(arg_in_01space));
    return from + (to - from) * place01;
}
float   lim_tor         (float from, float to, float arg)
{
    float arg_in_01space = arg / (to - from);
    float fract01 = myfractpart(arg_in_01space);
    if (fract01 < 0) fract01 += 1.0;
    return from + (to - from) * fract01;
}
float   remap_ff        (float A_from, float A_to, float B_from, float B_to, float A_arg)
{
    float arg01 = (A_arg - A_from) / float(A_to - A_from);
    return B_from + (B_to - B_from) * arg01;
}
vec2    remap_ff        (vec2 A_from, vec2 A_to, vec2 B_from, vec2 B_to, vec2 A_arg)
{
    float x = remap_ff(A_from.x, A_to.x, B_from.x, B_to.x, A_arg.x);
    float y = remap_ff(A_from.y, A_to.y, B_from.y, B_to.y, A_arg.y);
    return vec2(x,y);
}
float   remap_if        (int A_from, int A_to, float B_from, float B_to, int A_arg)
{
    float arg01 = (A_arg - A_from) / float(A_to - A_from);
    return B_from + (B_to - B_from) * arg01;
}
int     remap_fi        (float A_from, float A_to, int B_from, int B_to, float A_arg)
{
    float arg01 = (A_arg - A_from) / float(A_to - A_from);
    return int(B_from + (B_to - B_from) * arg01);
}



float   n11_to_01   (float  num){return (num + 1.0) * 0.5;			} VECTORIZE(n11_to_01)
float   n01_to_11   (float  num){return num * 2.0 - 1.0;			} VECTORIZE(n01_to_11)
float   lim_fold01  (float 	num){return lim_fold(0.0, 1.0, num);	} VECTORIZE(lim_fold01)
float   lim_fold11  (float 	num){return lim_fold(-1.0, 1.0, num);	} VECTORIZE(lim_fold11)
//'viewport' = {scale, yaspect, xoffset, yoffset}
vec2 apply_viewport(vec2 basendc, vec4 viewport)
{
    basendc.x *= viewport.x;
    basendc.y *= (viewport.x * viewport.y);
    basendc.x += viewport.z;
    basendc.y += viewport.w;
    return basendc;
}
//assumes {0,0} is top left
vec4 getpixel(sampler2D tex, int xres, int yres, int x, int y)
{
    y = yres - 1 - y;
    float x_px_size = 1.0 / float(xres);
    float y_px_size = 1.0 / float(yres);
    float x_pos01   = (float(x) + 0.5) * x_px_size;
    float y_pos01   = (float(y) + 0.5) * y_px_size;
    return texture(tex, vec2(x_pos01, y_pos01));
}
vec2 rotate(vec2 vec, float ang_rad)
{
    float cs = cos(ang_rad);
    float sn = sin(ang_rad);
    return vec2(vec.x * cs - vec.y * sn, vec.x * sn + vec.y * cs);
}
vec2 rotate01(vec2 vec, float ang01)
{
    return rotate(vec, ang01 * 2 * PI);
}
vec2 rotatearound(vec2 vec, vec2 around, float ang_rad){return rotate(vec - around, ang_rad) + around;}
//Normalized sine: full cycle passes every 1.0 of val, as opposed to 2 * PI of normal sin.
float nsin(float val, float from, float to, float phase01)
{
    return remap_ff(-1.0, 1.0, from, to, sin( (val + phase01) * PI * 2.0 ));
}
float nsin(float val, float from, float to)
{
    return remap_ff(-1.0, 1.0, from, to, sin( val * PI * 2.0 ));
}
float nsin(float val, float phase01)
{
    return sin( (val + phase01) * PI * 2.0 );
}
float nsin01(float val)
{
    return n11_to_01( sin(val * PI * 2.0) );
}VECTORIZE(nsin01)
float nsin01(float val, float phase01)
{
    return n11_to_01( sin((val + phase01) * PI * 2.0) );
}
float ang_between(vec2 a, vec2 b)
{
    return atan(b.y * a.x - b.x * a.y, b.x * a.x + b.y * a.y);
}
float ang_between(vec3 a, vec3 b)
{
    a = normalize(a);
    b = normalize(b);
    
    return acos(a.x * b.x + a.y * b.y + a.z * b.z);
}
float ang01_between(vec3 a, vec3 b){return ang_between(a,b) / PI;}
float ang(vec2 a){return atan(a.y, a.x);}
float ang01(vec2 vec)
{
    return n11_to_01( atan(-vec.y, -vec.x) / PI );
}
bool pt_in_rect_ft(vec2 p, vec2 from, vec2 to)
{
    from.x  = min(from.x, to.x);
    from.y  = min(from.y, to.y);
    to.x    = max(from.x, to.x);
    to.y    = max(from.y, to.y);
    return p.x >= from.x && p.x <= to.x && p.y >= from.y && p.y <= to.y;
}
bool pt_in_01(vec2 p)
{
    return pt_in_rect_ft(p, vec2(0,0), vec2(1,1));
}
bool pt_in_11(vec2 p)
{
    return pt_in_rect_ft(p, vec2(-1,-1), vec2(1,1));
}
float clamp01(float v){return clamp(v,0,1);} VECTORIZE(clamp01)
float clamp11(float v){return clamp(v,-1,1);} VECTORIZE(clamp11)
//*** end of COMMON FUNCTIONS ***

//*****************************
// UNSTABLE COMMON FUNCTIONS //
//*****************************
vec3 	mulw		(vec4 v){return v.xyz * v.w;}
vec4 	get_pix_ndc	() { return vec4( agn_resolution() * agn_uv(), n01_to_11(agn_uv()) ); }
vec2    agn_ndc     (){return n01_to_11(agn_uv());}

void addclamp01(inout float val, float add){val = clamp01(val + add);}	
void addclamp11(inout float val, float add){val = clamp11(val + add);}	

//with StdPhasesInThisPhase = 1, peak will be at phase01u = 0.5
float nsinimpulse(float phase01u, float StdPhasesInThisPhase)
{
	float phase01 = phase01u - floor(phase01u);
	float stdphase = min(1.0, phase01 * StdPhasesInThisPhase);
	return nsin01(stdphase - 0.25);
}
float phasepeak_at(float phase01, float x_peak01)
{
	if (phase01 < x_peak01) return phase01 / x_peak01;
	else return 1.0 - (phase01 - x_peak01) / (1.0 - x_peak01);
}

vec2 cx_mul(vec2 a, vec2 b) { return vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x); }
vec2 cx_div(vec2 a, vec2 b) { return vec2(((a.x*b.x+a.y*b.y)/(b.x*b.x+b.y*b.y)),((a.y*b.x-a.x*b.y)/(b.x*b.x+b.y*b.y))); }
vec2 cx_pow(vec2 a, float n) {
    float 	angle 	= atan(a.y, a.x);
    float 	r 		= length(a);
    float 	real 	= pow(r, n) * cos(n*angle);
    float 	im 		= pow(r, n) * sin(n*angle);
    return 	vec2(real, im);
}
vec4 samplefold_11(sampler2D tex, vec2 ndc11)
{
    ndc11.x = lim_fold(-1.0, 1.0, ndc11.x);
    ndc11.y = lim_fold(-1.0, 1.0, ndc11.y);
    return texture(tex, vec2(ndc11.x * 0.5 + 0.5, ndc11.y * 0.5 + 0.5));
}
float clampphase(float val, float begin, float end)
{
    if (val < begin)   return 0;
    if (val > end)     return 1;
    return (val - begin) / (end - begin);
}
float cyclephase(float val, float cyclesize, int cycleidx)
{
    float rbegin    = cycleidx * cyclesize;
    float rend      = (cycleidx + 1) * cyclesize;
    
    return clampphase(val, rbegin, rend);
}
vec3 bezier(vec3 a0, vec3 a1, vec3 a2, vec3 a3, float phase01)
{
    vec3 b0 = mix(a0, a1, phase01);
    vec3 b1 = mix(a1, a2, phase01);
    vec3 b2 = mix(a2, a3, phase01);
    vec3 c0 = mix(b0, b1, phase01);
    vec3 c1 = mix(b1, b2, phase01);
    vec3 d0 = mix(c0, c1, phase01);
    return d0;
}
vec3 bezier(vec3 a0, vec3 a1, vec3 a2, vec3 a3, vec3 a4,vec3 a5,vec3 a6,vec3 a7, float phase01)
{
    vec3 b0 = mix(a0, a1, phase01);
    vec3 b1 = mix(a1, a2, phase01);
    vec3 b2 = mix(a2, a3, phase01);
    vec3 b3 = mix(a3, a4, phase01);
    vec3 b4 = mix(a4, a5, phase01);
    vec3 b5 = mix(a5, a6, phase01);
    vec3 b6 = mix(a6, a7, phase01);
    vec3 c0 = mix(b0, b1, phase01);
    vec3 c1 = mix(b1, b2, phase01);
    vec3 c2 = mix(b2, b3, phase01);
    vec3 c3 = mix(b3, b4, phase01);
    vec3 c4 = mix(b4, b5, phase01);
    vec3 c5 = mix(b5, b6, phase01);
    vec3 d0 = mix(c0, c1, phase01);
    vec3 d1 = mix(c1, c2, phase01);
    vec3 d2 = mix(c2, c3, phase01);
    vec3 d3 = mix(c3, c4, phase01);
    vec3 d4 = mix(c4, c5, phase01);
    vec3 e0 = mix(d0, d1, phase01);
    vec3 e1 = mix(d1, d2, phase01);
    vec3 e2 = mix(d2, d3, phase01);
    vec3 e3 = mix(d3, d4, phase01);
    vec3 f0 = mix(e0, e1, phase01);
    vec3 f1 = mix(e1, e2, phase01);
    vec3 f2 = mix(e2, e3, phase01);
    vec3 g0 = mix(f0, f1, phase01);
    vec3 g1 = mix(f1, f2, phase01);
    vec3 h0 = mix(g0, g1, phase01);
    return h0;
}
vec2 kaleid(vec2 p, int subdivs, float phase01)
{
    float   seg_ang = PI / float(subdivs);
    float   ang     = ang(p) + phase01 * 2.0 * PI;
    float   consang = lim_fold(0.0, seg_ang, ang);
    vec2    p2      = rotate(vec2(1.0, 0.0), consang) * length(p);
    return  p2;
}
float kaleid(float val, float MAX, int subdivs, float phase01)
{
    float fullval = val * subdivs * 2 + phase01 * MAX;
    float foldedval = lim_fold(0.0, MAX, fullval);
    return foldedval;
}

bool pt_in_triangle(vec2 t0, vec2 t1, vec2 t2, vec2 pt)
{
    float a = ang_between(t0 - pt, t1 - pt);
    float b = ang_between(t1 - pt, t2 - pt);
    float c = ang_between(t2 - pt, t0 - pt);  
    return abs(a+b+c - 2 * PI) < 0.00001;
}
vec4 rainbow(int idx)
{
    idx = clamp(idx, 0, 6);
    
    if      (idx == 0) return vec4(1, 0.1, 0, 1);
    else if (idx == 1) return vec4(1, 0.5, 0, 1);
    else if (idx == 2) return vec4(1, 1, 0, 1);
    else if (idx == 3) return vec4(0, 1, 0, 1);
    else if (idx == 4) return vec4(0, 0.45, 1, 1);
    else if (idx == 5) return vec4(0, 0.1, 1, 1);
    else if (idx == 6) return vec4(0.9, 0.1, 1, 1);
}
float rand(vec2 co){return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);}
float hash(float p){ p = fract(p * 0.011); p *= p + 7.5; p *= p + p; return fract(p);}
float hash(vec2 p){vec3 p3 = fract(vec3(p.xyx) * 0.13);p3 += dot(p3, p3.yzx + 3.333);return fract((p3.x + p3.y) * p3.z);}
float iq_hash3(vec3 i)
{
    vec3  p = 17.0*fract( i*0.3183099+vec3(0.11,0.17,0.13) );
    float w = fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
    return w*w;
}
vec3 iq_hash3_b( vec2 p )
{
    vec3 q = vec3( dot(p,vec2(127.1,311.7)), 
				   dot(p,vec2(269.5,183.3)), 
				   dot(p,vec2(419.2,371.9)) );
	return fract(sin(q)*43758.5453);
}

//assumes {0,0} is top left
vec4 getpoint(sampler2D tex, int xres, int yres, int x, int y)
{
    y = yres - 1 - y;

    float x_px_size = 1.0 / float(xres);
    float y_px_size = 1.0 / float(yres);
    
    float x_pos01   = (float(x) + 0.5) * x_px_size;
    float y_pos01   = (float(y) + 0.5) * y_px_size;
    
    return texture(tex, vec2(x_pos01, y_pos01));
}
const vec3 xzid     = vec3(1,0,1);
const vec3 xid      = vec3(1,0,0);
const vec3 yid      = vec3(0,1,0);
const vec3 zid      = vec3(0,0,1);
vec3 yscale			(vec3 dim, float yscale){return vec3(dim.x, dim.y*yscale, dim.z);}
vec3 move           (vec3 p, vec3 dim, vec3 norm_coord){return p - dim * norm_coord;}
vec3 climb          (vec3 p, vec3 dim){p.y -= dim.y;return p;}
vec3 climb          (vec3 p, float h){p.y -= h;return p;}
vec3 descend        (vec3 p, vec3 dim){p.y += dim.y;return p;}
vec3 rot_x          (vec3 p, float a01)             {p.yz = rotate(p.yz, a01 * 2 * PI); return p;}
vec3 rot_y          (vec3 p, float a01)             {p.xz = rotate(p.xz, a01 * 2 * PI); return p;}
vec3 rot_z          (vec3 p, float a01)             {p.xy = rotate(p.xy, a01 * 2 * PI); return p;}
vec3 rot_x_around   (vec3 p, vec3 around, float a01){p.yz = rotatearound(p.yz, around.yz, a01 * 2 * PI); return p;}
vec3 rot_y_around   (vec3 p, vec3 around, float a01){p.xz = rotatearound(p.xz, around.xz, a01 * 2 * PI); return p;}
vec3 rot_z_around   (vec3 p, vec3 around, float a01){p.xy = rotatearound(p.xy, around.xy, a01 * 2 * PI); return p;}
vec3 mir_x          (vec3 p, float  off){p.x    = abs(p.x)  - off;return p;}
vec3 mir_y          (vec3 p, float  off){p.y    = abs(p.y)  - off;return p;}
vec3 mir_z          (vec3 p, float  off){p.z    = abs(p.z)  - off;return p;}
vec3 mir_xz         (vec3 p, vec2   off){p.xz   = abs(p.xz) - off;return p;}
vec3 mir_xy         (vec3 p, vec2   off){p.xy   = abs(p.xy) - off;return p;}
vec3 mir_yz         (vec3 p, vec2   off){p.yz   = abs(p.yz) - off;return p;}
vec3 mir_xyz        (vec3 p, vec3   off){p      = abs(p)    - off;return p;}
vec3 fromxz         (vec2 xz) { return vec3(xz.x, 0, xz.y); }
vec4 repeat_polar   (vec3 p,float radius,float sectors) {
    float   TAU     = PI*2;
    float   angle   = TAU/sectors;
    float   at      = atan(p.z,p.x); 
    //if sectors even, there is a split of the sector at the opposite side because of the atan function
    if (mod(sectors,2.) == 0. && at < -PI+angle*.5) at = at+TAU; 
    float   sector  = round((at)/angle);
    p.xz            = rotate(p.xz, -angle*sector);
    p.x             -= radius;
    if (sector < 0.0) sector += sectors;
    return vec4(p,sector);
}
vec2 cart2polar		(vec2 cart){return vec2(ang(cart), length(cart));}
vec2 polar2cart		(vec2 polar){return rotate(vec2(1,0), polar.x) * polar.y;}

float v_min(vec2 v){ return min(v.x, v.y); } 
float v_min(vec3 v){ return min(min(v.x, v.y), v.z); } 
float v_min(vec4 v){ return min(min(min(v.x, v.y), v.z), v.w); } 
float v_max(vec2 v){ return max(v.x, v.y); } 
float v_max(vec3 v){ return max(max(v.x, v.y), v.z); } 
float v_max(vec4 v){ return max(max(max(v.x, v.y), v.z), v.w); } 
float powmul(float v, vec2 pow_mul){return pow(v, pow_mul.x) * pow_mul.y;}

//*** end of UNSTABLE COMMON FUNCTIONS ***

//****************
// DEBUG SYSTEM //
//****************

uniform ivec2 ds_chselector; //x is ds - debug value, y is multisampling

vec4    ds_ca = vec4(1,0,1,0)/10;
/*vec4    ds_c1 = vec4(1,0,0,0)/10;
vec4    ds_c2 = vec4(0,1,0,0)/10;
vec4    ds_c3 = vec4(0,0,1,0)/10;
vec4    ds_c4 = vec4(0,1,1,0)/10;
vec4    ds_getc(int idx)
{
    idx = clamp(idx, 1, 4);
    if      (idx == 1)  return ds_c1;
    else if (idx == 2)  return ds_c2;
    else if (idx == 3)  return ds_c3;
    else                return ds_c4;
}
void ds_setc(int idx, vec4 c)
{
    if      (idx == 1) ds_c1 = c;
    else if (idx == 2) ds_c2 = c;
    else if (idx == 3) ds_c3 = c;
    else if (idx == 4) ds_c4 = c;
}
*/
const struct DS_Params
{
    int     cells_w;
    int     cells_h;
    float   linew;
    float   border;
    vec4    clr_border;
    vec4    clr_clear;
}ds_params = DS_Params(8,8, 0.004, 0.01, vec4(0.5), vec4(0.2));
struct DS_Disp
{
    ivec2 cell_coord;
    ivec2 cell_wh;    
    vec4  fromto; //xy is TOPELFT, zw is BOTRIGHT
};
vec2 ds_cell_to_01(ivec2 cell) //y from top 0 to bottom 1
{
    float x = float(cell.x) / float(ds_params.cells_w);
    float y = float(cell.y) / float(ds_params.cells_h);
    return vec2(x,y);
}
vec4 ds_vp_q1(float max_x, float max_y)
{
    return vec4(0, max_y, max_x, 0);
}
vec4 ds_vp_q4(float max_x, float min_y)
{
    return vec4(0, 0, max_x, min_y);
}
vec4 ds_vp_q12(float max_x, float max_y)
{
    return vec4(-max_x, max_y, max_x, 0);
}
vec4 ds_vp_q1234(float max_x, float max_y)
{
    return vec4(-max_x, max_y, max_x, -max_y);
}
vec4 ds_rect01(DS_Disp disp) //y from top 0 to bottom 1
{
    vec2    from    = ds_cell_to_01(disp.cell_coord);
    vec2    to      = ds_cell_to_01(disp.cell_coord + max(ivec2(1), disp.cell_wh));
    return  vec4(from,to);
}
vec2 ds_dispcoord01(DS_Disp disp)
{
    vec2    uv          = agn_uv();
    vec2    myuv        = vec2(uv.x, 1.0 - uv.y); 
    vec4    rect        = ds_rect01(disp);
    vec2    dispcoord01 = remap_ff(rect.xy, rect.zw, vec2(0,0), vec2(1,1), myuv);
    return  dispcoord01;
}
vec2 ds_dsp(DS_Disp disp)
{
    vec2    uv              = agn_uv();
    vec2    dispcoord01     = ds_dispcoord01(disp);
    vec2    dispspace_pt    = remap_ff(vec2(0,0), vec2(1,1), disp.fromto.xy, disp.fromto.zw, dispcoord01);
    return  dispspace_pt;
}
float ds_dspx(DS_Disp disp)
{
    return ds_dsp(disp).x;
}
vec2 ds_dsp_to_dispcoord01(DS_Disp disp, vec2 dispspace)
{
    vec2 dc01 = remap_ff(disp.fromto.xy, disp.fromto.zw, vec2(0,0), vec2(1,1), dispspace);
    return dc01;
}
vec2 ds_dispcoord01_to_uv(DS_Disp disp, vec2 dc01)
{
    vec4    rect        = ds_rect01(disp);
    vec2    myuv        = remap_ff(vec2(0,0), vec2(1,1), rect.xy, rect.zw, dc01);
    return  vec2(myuv.x, 1.0 - myuv.y);
}
vec2 ds_dsp_to_uv(DS_Disp disp, vec2 dispspace)
{
    return ds_dispcoord01_to_uv(disp, ds_dsp_to_dispcoord01(disp, dispspace));
}
bool inborder(vec2 p)
{
    return pt_in_01(p) && !pt_in_rect_ft(p, vec2(ds_params.border), vec2(1-ds_params.border));
}

void ds_ploty(DS_Disp disp, float dsp_y)
{
    vec2    dc01 = ds_dispcoord01(disp);    
    if      (!pt_in_01(dc01))   return;    

    float   y_in_uv = ds_dsp_to_uv(disp, vec2(dsp_y)).y;
    
    if (abs(agn_uv().y - y_in_uv) < ds_params.linew)
    {
        ds_ca = vec4(vec3(1,0,0), 0.75);
    }
    else ds_ca = inborder(dc01) ? ds_params.clr_border : ds_params.clr_clear;
}
void ds_plotc(DS_Disp disp, vec4 clr)
{
    vec2    dc01 = ds_dispcoord01(disp);    
    if      (!pt_in_01(dc01))   return;    
    
    ds_ca = clr;
    if (inborder(dc01)) ds_ca = ds_params.clr_border;
}
vec4 ds_apply(vec4 color)
{
    color   = mix(color, ds_ca, ds_ca.a);
    //color   = mix(color, ds_ca, 0.99);
    color.a = 1;
    return color;
}
bool ds_in_disp(DS_Disp disp)
{
	return pt_in_01(ds_dispcoord01(disp));
}
//********* DEBUG SYSTEM USAGE: DISPLAYS **********
//DS_Disp dc1  = DS_Disp(ivec2(0,0), ivec2(1,1), ds_vp_q1(1,1));
//DS_Disp dn2  = DS_Disp(ivec2(0,0), ivec2(2,2), ds_vp_q1234(1,1));
//*** end of DEBUG SYSTEM ***

//******************************
// TEXT SYSTEM 
//      depends on: DEBUG SYSTEM
//******************************
//DS_Disp     dnum                    = DS_Disp(ivec2(3,0), ivec2(1,1),ds_vp_q4(1,1));
const int   ts_symcount             = 15;
//0123456789 .-!x
const int   ts_symbols[ts_symcount] = {33080895, 17318416, 32570911, 33061407, 17333809, 33061951, 33094719,
                                        17318431, 33095231, 33062463, 0, 4194304, 31744, 4198532, 18157905};
const float ts_NODRAW   = 67675753.324;
vec4        ts_num      = vec4(ts_NODRAW);
bool ts_num_nodraw(){return abs((ts_num.x + ts_num.y + ts_num.z + ts_num.w) / 4.0 - ts_NODRAW) < 0.01;}

bool ts_sym_pixel(int ts_sym, vec2 coord01)
{
    if (!pt_in_01(coord01)) return false;
    float   r       = 1/5.0;
    int     celly   = int(coord01.y / r);
    int     cellx   = int(coord01.x / r);
    int     bitidx  = celly * 5 + cellx;    
    int     bit     = bitfieldExtract(ts_sym, bitidx, 1);
    return  bit != 0;
}
float ts_win(float x)
{
    float slope = 0.34;
    float base  = 0.16;
    float k     = pow(1.0-x, slope);
    return base + k * (1.0-base);
}
int ts_charcode_of_num(float n, int charidx, int strlen, int MAXFRACTDIGITS)
{
    // ' ' : '-'
    if (charidx == 0) return n >= 0 ? 10 : 12;
	
	n=abs(n);
	
    int MAXWHOLEDIGITS  = 10;

    int wholedigits     = 1;
    int i               = int(n);
    for (int k = 0; k < MAXWHOLEDIGITS; ++k)
    {
        i /= 10;        
        if (i == 0) break;
        else wholedigits++;
    } 
    //too big num
    if (i != 0) return 13; //!    
    //even if we cut fractional part, wont fit
    if (wholedigits + 1 > strlen) return 13; //!
    
    i = int(n);
    for (int k = 0; k < wholedigits; ++k)
    {
        int k_as_idx = wholedigits - k;
        int curlastdigit = abs(i % 10);
        if (k_as_idx == charidx) return curlastdigit;
        i /= 10;
    }
    
    if (MAXFRACTDIGITS == 0) return 10;
    if (charidx == wholedigits + 1) return charidx < strlen ? 11 : 10; //.
    
    int     remaining_chars = strlen - (1 + wholedigits + 1);
    int     digitstoprint   = min(remaining_chars, MAXFRACTDIGITS);
    float   fr              = abs(n) - abs(int(n));
    for (int k = 0; k < digitstoprint; ++k)
    {
        fr *= 10;
        int digit = int(fr) % 10;
        int k_as_idx = wholedigits + 2 + k;
        if (k_as_idx == charidx) return digit;
    }
    return 10;
}
vec4 ts_render_field(vec2 coord01)
{
    ivec2   wh          = ivec2(12,4);
    int     fractdigits = 6;
    float   border      = 1.22;
    
    vec2    cellsize    = vec2(1.0 / float(wh.x), 1.0 / float(wh.y));    
    int     cellx       = int(coord01.x / cellsize.x);
    int     celly       = int(coord01.y / cellsize.y);
    vec2    symcoord01  = mod(coord01, cellsize) / cellsize;
    symcoord01          = symcoord01 * border - vec2((border-1)/2);
    
    float   comp        = 0;
    if      (celly == 0) comp = ts_num.x;
    else if (celly == 1) comp = ts_num.y;
    else if (celly == 2) comp = ts_num.z;
    else if (celly == 3) comp = ts_num.w;
    
    if (abs(comp - ts_NODRAW) < 0.001) return vec4(0);
    
    int     charcode    = ts_charcode_of_num(comp, cellx, wh.x, fractdigits);
    
    float   val         = ts_sym_pixel(ts_symbols[charcode], symcoord01) ? 1 : 0;

    return vec4(vec3(val), val);
}
void ts_ds_printnums(DS_Disp disp)
{
    if (ts_num_nodraw()) return;

    vec2    dc01 = ds_dispcoord01(disp);    
    if      (!pt_in_01(dc01))   return;
    
    vec2 coord = agn_uv(); coord.y = 1.0 - coord.y;
    ds_ca = ts_render_field(dc01);
    
    if (ds_ca.a < 0.1)
    {
        vec4 clear = ds_params.clr_clear; clear.a *= 3;
        ds_ca = inborder(dc01) ? ds_params.clr_border : clear;
    }
}
/*void ts_ds_examples()
{
    ds_ploty(dc1, pow(ds_dspx(dc1), 2));
    ds_ploty(dn1, sin(ds_dspx(dn1)*PI));        
    ts_num.x = -1357.446;
    //ts_num.w = time;
}*/

//*** end of TEXT SYSTEM ***


//****************************
// NOISES COLLECTION		//
//****************************

float gyroid (vec3 seed) { return dot(sin(seed),cos(seed.yzx)); }
float fbm (vec3 seed)
{
    float result = 0., a = .5;
    for (int i = 0; i < 8; ++i, a/=2.)
    {
        result += abs(gyroid(seed/a))*a;
    }
    return result;
}

float fbm (vec3 seed, int oct)
{
    float result = 0., a = .5;
    for (int i = 0; i < oct; ++i, a/=2.)
    {
        result += abs(gyroid(seed/a))*a;
    }
    return result;
}

vec3 multinoiseraw(vec3 coord, vec3 yseed, vec3 densities)
{
    vec3 posx = (coord + vec3(0, yseed.x, 0)) * densities.x;
    vec3 posy = (coord + vec3(0, yseed.y, 0)) * densities.y;
    vec3 posz = (coord + vec3(0, yseed.z, 0)) * densities.z;
    float x = fbm(posx);
    float y = fbm(posy);
    float z = fbm(posz);
    return vec3(x,y,z);
}

float voronoise(vec2 p, vec2 uv )
{
	float u = uv.x;
	float v = uv.y;
	float k = 1.0+63.0*pow(1.0-v,6.0);

    vec2 i = floor(p);
    vec2 f = fract(p);
    
	vec2 a = vec2(0.0,0.0);
    for( int y=-2; y<=2; y++ )
    for( int x=-2; x<=2; x++ )
    {
        vec2  g = vec2( x, y );
		vec3  o = iq_hash3_b( i + g )*vec3(u,u,1.0);
		vec2  d = g - f + o.xy;
		float w = pow( 1.0-smoothstep(0.0,1.414,length(d)), k );
		a += vec2(o.z*w,w);
    }
	
    return a.x/a.y;
}

float voronoise3(vec3 p, vec2 uv )
{
	float u = uv.x;
	float v = uv.y;
	float k = 1.0+63.0*pow(1.0-v,6.0);

    vec3 i = floor(p);
    vec3 f = fract(p);
    
	const int R = 1;
	
	vec2 a = vec2(0.0,0.0);
    for( int y=-R; y<=R; y++ )
    for( int x=-R; x<=R; x++ )
	for( int z=-R; z<=R; z++ )
    {
        vec3  g = vec3( x, y, z );
		vec3  o = iq_hash3( i + g )*vec3(u,u,1.0);
		vec3  d = g - f + o;
		float w = pow( 1.0-smoothstep(0.0,1.414,length(d)), k );
		a += vec2(o.z*w,w);
    }
	
    return a.x/a.y;
}

//Rest

int f2i(float f)
{
	return int(f + 0.5*sign(f));
}

//returns id of cell, assuming center of cell with idx 0 is at origin
//cellcoord01: 0 at left border, 1 at right, for all indexes
int to_cellspace(float p, float cellsize, out float cellcoord01)
{
	p += cellsize * 0.5;
	float cs = p / cellsize;
	
	int index = cs > 0 ? int(cs) : int(cs-1);
	cellcoord01 = cs - float(index);
	return index;
}
ivec2 to_cellspace(vec2 p, vec2 cellsize, out vec2 cellcoord01)
{
	float 	x_coord01 	= 0;
	int 	x_idx 		= to_cellspace(p.x, cellsize.x, x_coord01);
	float 	y_coord01 	= 0;
	int 	y_idx 		= to_cellspace(p.y, cellsize.y, y_coord01);
	
	cellcoord01 = vec2(x_coord01, y_coord01);
	return ivec2(x_idx, y_idx);
}
ivec3 to_cellspace(vec3 p, vec3 cellsize, out vec3 cellcoord01)
{
    float   x_coord01   = 0;
    int     x_idx       = to_cellspace(p.x, cellsize.x, x_coord01);
    float   y_coord01   = 0;
    int     y_idx       = to_cellspace(p.y, cellsize.y, y_coord01);
    float   z_coord01   = 0;
    int     z_idx       = to_cellspace(p.z, cellsize.z, z_coord01);
    
    cellcoord01 = vec3(x_coord01, y_coord01, z_coord01);
    return ivec3(x_idx, y_idx, z_idx);
}