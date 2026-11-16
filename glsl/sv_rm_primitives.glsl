//***************************
//      SDF FUNCTIONS      //
//***************************
	//-----------------//
	// CORE PRIMITIVES //
	//-----------------//
float sdf_sphere(vec3 p, float radius) {
    return length(p) - radius;
}
float sdf_box   (vec3 p, vec3 dims) {
    vec3 q = abs(p) - dims;
    return length( max(q,0.0)) + min(max(q.x,max(q.y,q.z)), 0.0 );
}
float sdf_cylinder( vec3 p, vec2 dims ) //r, h
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - dims;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
float sdf_cylring( vec3 p, vec3 dims ) //r,h,w
{
  float cyl = sdf_cylinder(p, dims.xy);
  float cut = sdf_cylinder(p, vec2(dims.x - dims.z, dims.y * 20.0));
  return sop_sub(cyl, cut);
}
float sdf_wirebox(vec3 p, vec3 dims, float wiresize ) {
    p       = abs(p) - dims;
    vec3 q  = abs(p + wiresize) - wiresize;
    return min(min(
        length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
        length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
        length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}
float sdfc_wirebox(vec3 p, vec3 dims, float wiresize ) { return sdf_wirebox(p, dims * 0.5, wiresize); }
float sdf_torus( vec3 p, float skeleton_radius, float flesh_radius ) {
    vec2 q = vec2(length(p.xz)-skeleton_radius,p.y);
    return length(q)-flesh_radius;
}
float sdf_plane( vec3 p, vec3 normal, float height ) {
    //n must be normalized
    return dot(p,normal) + height;
}
float sdf_yPlane(vec3 p, float height)
{
	return p.y - height;
}

float sdf_quad( vec3 p, vec3 a, vec3 b, vec3 c, vec3 d ) {
    vec3 ba   = b - a; vec3 pa = p - a;
    vec3 cb   = c - b; vec3 pb = p - b;
    vec3 dc   = d - c; vec3 pc = p - c;
    vec3 ad   = a - d; vec3 pd = p - d;
    vec3 nor  = cross( ba, ad );
    
    return sqrt(
    (sign(dot(cross(ba,nor),pa)) +
     sign(dot(cross(cb,nor),pb)) +
     sign(dot(cross(dc,nor),pc)) +
     sign(dot(cross(ad,nor),pd))<3.0)
     ?
     min( min( min(
     dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
     dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
     dot2(dc*clamp(dot(dc,pc)/dot2(dc),0.0,1.0)-pc) ),
     dot2(ad*clamp(dot(ad,pd)/dot2(ad),0.0,1.0)-pd) )
     :
     dot(nor,pa)*dot(nor,pa)/dot2(nor) );
}
float sdf_triangle( vec3 p, vec3 a, vec3 b, vec3 c ) {
    vec3 ba = b - a; vec3 pa = p - a;
    vec3 cb = c - b; vec3 pb = p - b;
    vec3 ac = a - c; vec3 pc = p - c;
    vec3 nor = cross( ba, ac );

    return sqrt(
    (sign(dot(cross(ba,nor),pa)) +
     sign(dot(cross(cb,nor),pb)) +
     sign(dot(cross(ac,nor),pc))<2.0)
     ?
     min( min(
     dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
     dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
     dot2(ac*clamp(dot(ac,pc)/dot2(ac),0.0,1.0)-pc) )
     :
     dot(nor,pa)*dot(nor,pa)/dot2(nor) );
}
float sdf_pyramid( vec3 p, float scale, float h)
{
    p /= scale;

  float m2 = h*h + 0.25;
    
  p.xz = abs(p.xz);
  p.xz = (p.z>p.x) ? p.zx : p.xz;
  p.xz -= 0.5;

  vec3 q = vec3( p.z, h*p.y - 0.5*p.x, h*p.x + 0.5*p.y);
   
  float s = max(-q.x,0.0);
  float t = clamp( (q.y-0.5*p.z)/(m2+0.25), 0.0, 1.0 );
    
  float a = m2*(q.x+s)*(q.x+s) + q.y*q.y;
  float b = m2*(q.x+0.5*t)*(q.x+0.5*t) + (q.y-m2*t)*(q.y-m2*t);
    
  float d2 = min(q.y,-q.x*m2-q.y*0.5) > 0.0 ? 0.0 : min(a,b);
    
  float dist = sqrt( (d2+q.z*q.z)/m2 ) * sign(max(q.z,-p.y));
  return dist * scale;
}

	//--------------
	//2D PRIMITIVES:
	//--------------
float sdf2d_circle(vec2 xy, float radius)
{
    return length(xy) - radius;
}
float sdf2d_isotriangle(vec2 p, vec2 q )
{
    p.x = abs(p.x);
    vec2 a = p - q*clamp( dot(p,q)/dot(q,q), 0.0, 1.0 );
    vec2 b = p - q*vec2( clamp( p.x/q.x, 0.0, 1.0 ), 1.0 );
    float s = -sign( q.y );
    vec2 d = min( vec2( dot(a,a), s*(p.x*q.y-p.y*q.x) ),
                  vec2( dot(b,b), s*(p.y-q.y)  ));
    return -sqrt(d.x)*sign(d.y);
}

	//----------------
	//ADVANCED SHAPES:
	//----------------
	
float sdf_cappyramid(vec3 P, vec3 dim_ScaleHeightCap01)
{
    float   scale       = dim_ScaleHeightCap01.x;
    float   h           = dim_ScaleHeightCap01.y;
    float   cap01       = dim_ScaleHeightCap01.z;
    cap01               = clamp(cap01, 0, 1);
    float   pyr         = sdf_pyramid(P, scale, h);
    float   cuth        = scale * cap01 * h;
    vec3    lbox_dim    = vec3(scale, h, scale) * 2.5;
    float   limbox      = sdf_box(P - vec3(0,lbox_dim.y+cuth,0), lbox_dim);
    return sop_sub(pyr, limbox);
}
//float sop_extrude   (float dist2d,  float height, float pz)
float sdf_triprism(vec3 p, vec3 dim)
{
    p.y = -p.y + dim.y;
    float dist2d = sdf2d_isotriangle(p.xy, dim.xy);
    return sop_extrude(dist2d, dim.z, p.z);
}
float sdf_triprismroof(vec3 p, vec4 prm) //prism xyz, cutscale
{
    float cutscale = prm.w;
    float base = sdf_triprism(p, prm.xyz);
    float cut = sdf_triprism(p + vec3(0, prm.y * 0.01, 0), prm.xyz * vec3(cutscale,cutscale,2));
    return sop_sub(base, cut);
}
vec4 sdf_axes(vec3 p, float L, float S, float SM)
{
    //p               = inv_mdl_trans(p, temptr, temprot, tempscale);

    float   F       = L + SM * S;
    vec3    scale   = vec3(L, S, S);
    float   fix     = sdf_scalefix(scale);
    vec3    PX      = inv_mdl_trans(p, vec3(F,0,0), vec4(1,0,0, 0    ), scale);
    vec3    PY      = inv_mdl_trans(p, vec3(0,F,0), vec4(0,0,1, PI/2 ), scale);
    vec3    PZ      = inv_mdl_trans(p, vec3(0,0,F), vec4(0,1,0, PI/2 ), scale);
    
    float   X       = sdf_box(PX, vec3(1,1,1)) * fix;
    float   Y       = sdf_box(PY, vec3(1,1,1)) * fix;
    float   Z       = sdf_box(PZ, vec3(1,1,1)) * fix;
    
    if        (X < Y && X < Z)    return vec4(1,0,0,X);
    else if   (Y < X && Y < Z)    return vec4(0,1,0,Y);
    else                          return vec4(0,0,1,Z);
}
vec4 sdf_axes(vec3 p)
{
    return sdf_axes(p, 0.5, 0.015/2, 4);
}
float sdfc_box      (vec3 p, vec3 dims) {return sdf_box(p, dims/2);}
float sdfh_box      (vec3 p, vec3 dims) {return sdfc_box(p - vec3(0,dims.y/2,0), dims);}
float sdfh_wirebox  (vec3 p, vec3 dims, float wiresize ) {dims *= 0.5; return sdf_wirebox(p - vec3(0,dims.y,0), dims, wiresize);}

float sdfc_cubeToSphere(vec3 p, vec2 Size_Tosphere01, float SphereSizeMod)
{
	float Size 			= Size_Tosphere01.x * (1.0 - Size_Tosphere01.y);
	float Rounding 		= Size_Tosphere01.x * Size_Tosphere01.y * SphereSizeMod;
	return sdfc_box(p, vec3(Size)) - Rounding;
}
float sdfc_cubeToOuterSphere(vec3 p, vec2 Size_Tosphere01)
{
	return sdfc_cubeToSphere(p, Size_Tosphere01, 0.85);
}
float sdfc_cubeToInnerSphere(vec3 p, vec2 Size_Tosphere01)
{
	return sdfc_cubeToSphere(p, Size_Tosphere01, 0.5);
}		

float sdfc_boxToCylinder(vec3 p, vec4 dimsXYZ_toCylinder01 )
{
	vec3 	dims 			= dimsXYZ_toCylinder01.xyz;
	float 	toCylinder01 	= dimsXYZ_toCylinder01.w;
	
	vec3 	elongation 		= vec3(dims.x, 0, dims.z) * 0.5 * (1.0-toCylinder01);
	
	vec4 	elongP_Adddist 	= sop_elong(p, elongation);
	
	float 	radius 			= v_min(dims.xz) * 0.5 * toCylinder01;
	
	float 	cylinder 		= elongP_Adddist.w + sdf_cylinder(elongP_Adddist.xyz, vec2(radius, dims.y * 0.5));
	return 	cylinder;
}
float sdfh_boxToCylinder(vec3 p, vec4 dimsXYZ_toCylinder01 )
{
	p.y -= 0.5 * dimsXYZ_toCylinder01.y;
	return sdfc_boxToCylinder(p, dimsXYZ_toCylinder01);
}

float sdfh_cylinder (vec3 p, vec2 dims ) {dims *= 0.5; return sdf_cylinder(p - vec3(0,dims.y,0), dims);}
vec2  sdfh_cappyr   (vec3 P, vec3 dims_X_Y_YPRECAPMOD) //returns dist, topsurfacesize
{
    float   scale       = dims_X_Y_YPRECAPMOD.x; //also width
    float   h           = (dims_X_Y_YPRECAPMOD.y * dims_X_Y_YPRECAPMOD.z) / scale;
    float   cap01       = max(0, 1/dims_X_Y_YPRECAPMOD.z);
    float   topsurf     = scale * (1.0 - min(1.0, cap01)); 
    float   pyr         = sdf_pyramid(P, scale, h);
    if (cap01 > 1) return vec2(pyr, topsurf);
    float   cuth        = scale * cap01 * h;
    vec3    lbox_dim    = vec3(scale, h, scale) * 2.5;
    float   limbox      = sdf_box(P - vec3(0,lbox_dim.y+cuth,0), lbox_dim);
    return vec2(sop_sub(pyr, limbox), topsurf);
}
float sdfh_triprism(vec3 p, vec3 dim)
{
    dim.xz          *= 0.5;
    p.y             = -p.y + dim.y;
    float   dist2d  = sdf2d_isotriangle(p.xy, dim.xy);
    return  sop_extrude(dist2d, dim.z, p.z);
}
float sdfh_triprismroof(vec3 p, vec4 prm) //prism xyz, cutscale
{
    float   cutscale    = prm.w;
    float   base        = sdfh_triprism(p, prm.xyz);
    float   cut         = sdfh_triprism(p + vec3(0, prm.y * 0.001, 0), prm.xyz * vec3(cutscale,cutscale,2));
    return  cutscale > 0.0001 ? sop_sub(base, cut) : base;
}
float sdfc_rhombus(vec3 p, vec4 prm_xyz_rounding)
{
    float   la  = prm_xyz_rounding.x / 2;
    float   h   = prm_xyz_rounding.y / 2;
    float   lb  = prm_xyz_rounding.z / 2;
    float   ra  = prm_xyz_rounding.w;
    //p.y         -= h;
    p           = abs(p);
    vec2    b   = vec2(la,lb);
    float   f   = clamp( (ndot(b,b-2.0*p.xz))/dot(b,b), -1.0, 1.0 );
    vec2    q   = vec2(length(p.xz-0.5*b*vec2(1.0-f,1.0+f))*sign(p.x*b.y+p.z*b.x-b.x*b.y)-ra, p.y-h);
    return min(max(q.x,q.y),0.0) + length(max(q,0.0));
}
float sdfh_rhombus(vec3 p, vec4 prm_xyz_rounding)
{
    p.y -= prm_xyz_rounding.y / 2;
    return sdfc_rhombus(p, prm_xyz_rounding);
}
float sdf2d_stairs(vec2 p, vec2 wh, float n)
{
    vec2    ba  = wh*n;
    float   d   = min(dot2(p-vec2(clamp(p.x,0.0,ba.x),0.0)), 
                  dot2(p-vec2(ba.x,clamp(p.y,0.0,ba.y))) );
    float   s   = sign(max(-p.y,p.x-ba.x) );
    float   dia = length(wh);
    p           = mat2(wh.x,-wh.y, wh.y,wh.x)*p/dia;
    float   id  = clamp(round(p.x/dia),0.0,n-1.0);
    p.x         = p.x - id*dia;
    p           = mat2(wh.x, wh.y,-wh.y,wh.x)*p/dia;
    float   hh  = wh.y/2.0;
    p.y         -= hh;
    if(p.y > hh*sign(p.x)) s = 1.0;
    p           = (id<0.5 || p.x>0.0) ? p : -p;
    d           = min( d, dot2(p-vec2(0.0,clamp(p.y,-hh,hh))) );
    d           = min( d, dot2(p-vec2(clamp(p.x,0.0,wh.x),hh)) );
    return sqrt(d)*s;
}
float sdfh_stairs(vec3 P, vec3 dim, int count)
{
    P               =   P.zyx; 
    P.x             *=  -1;
    P.x             +=  dim.x;
    float  dist2d   =   sdf2d_stairs(P.xy, dim.xy / count, count);
    return sop_extrude(dist2d, dim.z/2, P.z);
}
float sdfh_stairswithcut(vec3 P, vec3 dim, int count, vec3 CUT_EXTT_EXTB)
{  
    float   ycut01          = CUT_EXTT_EXTB.x;
    float   topext01        = CUT_EXTT_EXTB.y;
    float   botext01        = CUT_EXTT_EXTB.z;
    float   base            = sdfh_stairs(P, dim.xyz, count);
    vec3    dim_prismcut    = vec3(dim.xyz) * vec3(vec2(2, 1) * 1, 2) * 3;
    
    vec3    PP              = move(P.zyx, dim_prismcut, vec3(0,-0.94,0));
    PP                      = move(PP, dim.xyz, vec3(0, ycut01, 0));
    float   prism           = sdfh_triprism(PP, dim_prismcut);
    
    float   ext_box         = 99999999;
    if (topext01 > 0.0001)
    {   
        vec3    dim_extbox      = vec3(topext01 * dim.x, (1 - ycut01) * dim.y, dim.z);
        vec3    EP              = move(P, dim.xyz, yid * ycut01);
        EP                      = EP.zyx;
        EP                      = move(EP, dim_extbox, vec3(-0.5,0,0));
        float   ext_box         = sdfh_box(EP, dim_extbox);
        base                    = min(base, ext_box);
    }
    
    if(botext01 > 0.0001)
    {
        vec3    dim_bp          = dim.zyx * vec3(1, botext01, 1);
        vec3    BP              = move(P, dim_bp, vec3(0, -1, 0.5));
        float   bot_ext_box     = sdfh_box(BP, dim_bp);
        base                    = min(base, bot_ext_box);
    }
    
    if (ycut01 > 0.0001) base = sop_sub(base, prism);
    
    return base;
}
float sdfc_box_cut(vec3 P, vec3 dim, vec2 A, vec2 B, vec2 C)
{
    float   box         = sdfc_box(P, dim);

    if (A.x > 0.00001)
    {
        vec3    dim_cut_A   = dim * 2;
        dim_cut_A.xy        = dim.xy * A.xy;
        float   cut_A       = sdfc_box(P, dim_cut_A);
        box                 = sop_sub(box, cut_A);
    }
    if (B.x > 0.00001)
    {
        vec3    dim_cut_B   = dim * 2;
        dim_cut_B.xz        = dim.xz * B.xy;
        float   cut_B       = sdfc_box(P, dim_cut_B);
        box                 = sop_sub(box, cut_B);
    }
    if (C.x > 0.00001)
    {
        vec3    dim_cut_C   = dim * 2;
        dim_cut_C.yz        = dim.yz * C.xy;
        float   cut_C       = sdfc_box(P, dim_cut_C);
        box                 = sop_sub(box, cut_C);
    }

    return box;
}
float sdfh_box_cut(vec3 P, vec3 dim, vec2 A, vec2 B, vec2 C){return sdfc_box_cut(P - yid * dim.y * 0.5, dim, A, B, C);}
float sdfh_capcone(vec3 p, vec3 D1_Y_D2 )
{
    float h = D1_Y_D2.y/2.;
    float r1 = D1_Y_D2.x/2.;
    float r2 = D1_Y_D2.z/2.;
    p.y -= h;
  vec2 q = vec2( length(p.xz), p.y );
  vec2 k1 = vec2(r2,h);
  vec2 k2 = vec2(r2-r1,2.0*h);
  vec2 ca = vec2(q.x-min(q.x,(q.y<0.0)?r1:r2), abs(q.y)-h);
  vec2 cb = q - k1 + k2*clamp( dot(k1-q,k2)/dot2(k2), 0.0, 1.0 );
  float s = (cb.x<0.0 && ca.y<0.0) ? -1.0 : 1.0;
  return s*sqrt( min(dot2(ca),dot2(cb)) );
}

//vec 2 A: xz-offset, yratio (both in relation to dims)
float sdfh_quadbox(vec3 p, vec3 dims, vec4 AB, vec4 CD)
{
	float sum_y_ratio = AB.y + AB.w + CD.y + CD.w;
	
	float a_h = (AB.y / sum_y_ratio) * dims.y;
	float b_h = (AB.w / sum_y_ratio) * dims.y;
	float c_h = (CD.y / sum_y_ratio) * dims.y;
	float d_h = (CD.w / sum_y_ratio) * dims.y;
	
	float W = dims.x;
	
	vec3 adims = vec3(W - W * AB.x, a_h, dims.z - W * AB.x);
	vec3 bdims = vec3(W - W * AB.z, b_h, dims.z - W * AB.z);
	vec3 cdims = vec3(W - W * CD.x, c_h, dims.z - W * CD.x);
	vec3 ddims = vec3(W - W * CD.z, d_h, dims.z - W * CD.z);
	
	float a = sdfh_box(p, adims);
	p.y -= a_h;
	float b = sdfh_box(p, bdims);
	p.y -= b_h;
	float c = sdfh_box(p, cdims);
	p.y -= c_h;
	float d = sdfh_box(p, ddims);
	
	return min(a, min(b, min(c, d)));
}

float zcut(vec3 P, float dist, float zoff)
{
    vec3 cutdim = vec3(10);
    return sop_sub(dist, sdfc_box(P - zid * (cutdim.z/2 + zoff), cutdim));
}
float sdf_arch(vec3 po, vec3 dim)
{
    vec3    p       = vec3(po.x, po.z, -po.y);
    float   w       = dim.x; float h = dim.y; float depth = dim.z;
    float   cyl     = sdf_cylinder(p,vec2(w/2.0,depth));
    float   boxh    = h - 0.5 * w;
    float   box     = sdf_box(p + vec3(0,0,-boxh/2.0), vec3(w/2.0,depth,boxh/2.0));
    return  sop_uni(cyl,box);
}

//sdf_srccross(P, 1, 0.05, 0.1, 0.5, 0.5);
float sdf_srccross(vec3 P, float span, float linewidthratio, float zdepthratio, float sub_lenmod, float sub_linewidthrmod)
{
    float   z           = zdepthratio * span;
    float   linew_main  = linewidthratio * span;
    vec3    dim_main    = vec3(span, linew_main, z) * 0.5;
    vec3    dim_sub     = dim_main * vec3(sub_lenmod, sub_linewidthrmod, 1);
    
    float   main_a      = sdf_box(P, dim_main);
    float   main_b      = sdf_box(P.yxz, dim_main);
    
    vec3    P45         = vec3(rotate(P.xy, PI/4), P.z);
    
    float   sub_a       = sdf_box(P45, dim_sub);
    float   sub_b       = sdf_box(P45.yxz, dim_sub);
    
    return min(main_a, min(main_b, min(sub_a, sub_b)));
}
float sdf_4cuts_irregprism(vec3 P, vec3 dim, vec4 cutangs)
{
    float   HP      = PI * 0.5;    
    float   basebox = sdf_box(P - yid * dim.y, dim.xyz);
    int     mul     = 50;
    vec3    dim_cut = dim * mul;
    
    vec3    off_a   = vec3(dim.x,dim.y, 0) * vec3(mul-1, mul, 0);
    vec3    off_b   = off_a * vec3(-1,1,1);
    vec3    off_c   = vec3(0, dim.y, dim.z) * vec3(0, mul, mul-1);
    vec3    off_d   = off_c * vec3(1,1,-1);
    vec3    RP_A    = P;
    vec3    RP_B    = P;
    vec3    RP_C    = P;
    vec3    RP_D    = P;
    RP_A.xy         = rotatearound(P.xy + off_a.xy, dim_cut.xy, PI - cutangs.x*HP);
    RP_B.xy         = rotatearound(P.xy + off_b.xy, dim_cut.xy * vec2(-1,1), cutangs.y*HP + PI);
    RP_C.yz         = rotatearound(P.yz + off_c.yz, dim_cut.yz,  cutangs.z*HP + PI);
    RP_D.yz         = rotatearound(P.yz + off_d.yz, dim_cut.yz * vec2(1,-1),  PI - cutangs.w*HP);

    vec3    centerh = yid * dim_cut.y;
    float   cut_a   = sdf_box(RP_A - centerh, dim_cut);
    float   cut_b   = sdf_box(RP_B - centerh, dim_cut);
    float   cut_c   = sdf_box(RP_C - centerh, dim_cut);
    float   cut_d   = sdf_box(RP_D - centerh, dim_cut);
    float   cuts    = min(cut_a, min(cut_b, min(cut_c, cut_d)));
    float   res     = sop_sub(basebox, cuts);
    return res;
}
// c is the sin/cos of the angle. r is the radius
float sdf2d_pie(vec2 p, float ang,float r )
{
    vec2 c = vec2(sin(ang), cos(ang));
    p.x = abs(p.x);
    float l = length(p) - r;
    float m = length(p - c*clamp(dot(p,c),0.0,r) );
    return max(l,m*sign(c.y*p.x-c.x*p.y));
}
float sdf_pie(vec3 P, float ang, float r, float h)
{
    float dist2d = sdf2d_pie(P.xy, ang, r);
    return sop_extrude(dist2d, h, P.z);
}
float sdf_pieplanes(vec3 P, float ang, float phase)
{
    ang = clamp(ang, 0.01, 2 * PI);
    ang -= PI;
    vec3 n1 = fromxz( rotate(vec2(1,0), -ang/2 + phase) );
    vec3 n2 = fromxz( rotate(vec2(1,0), ang/2 + phase) );
    float p1 = sdf_plane(P, n1, 0);
    float p2 = sdf_plane(P, n2, 0);
    
    return ang < 0 ? sop_int(p1,p2) : sop_uni(p1,p2);
    return p1;
    return min(p1, p2);
}
//float sdf_cylring( vec3 p, vec3 dims ) //r,h,w
float sdf_ringpie(vec3 P, vec3 R_H_W, vec2 ang_phase)
{
    float thering = sdf_cylring(P, R_H_W);
    float pie = sdf_pieplanes(P, ang_phase.x, ang_phase.y);
    
    return sop_int(thering, pie);
}
float sdfh_ringpie(vec3 P, vec3 RMIN_H_RWIDTH, vec2 ang_fromto_01)
{
    P.y -= RMIN_H_RWIDTH.y/2;
    
    float angspan = ang_fromto_01.y - ang_fromto_01.x;
    float phase = ang_fromto_01.x + angspan/2.0;
    vec3 std_RHW = vec3(RMIN_H_RWIDTH.x + RMIN_H_RWIDTH.z, RMIN_H_RWIDTH.y/2, RMIN_H_RWIDTH.z);
    return sdf_ringpie(P, std_RHW, vec2(angspan, phase) * 2 * PI);
}

float sdfh_arch(vec3 p, vec3 dim)
{
	vec3 	boxdim 	= vec3(dim.x, dim.y - 0.5 * dim.x, dim.z);	
	float 	box 	= sdfh_box(p, boxdim);
	
	vec3    p_cyl   = vec3(p.x, p.z, -p.y);
	p_cyl.z 		+= boxdim.y;
	float   cyl     = sdf_cylinder(p_cyl,vec2(dim.x,dim.z) * 0.5);
	
	return sop_uni(box, cyl);
}


//Various temp shit

float sdfh_halfprism(vec3 p, vec3 dims)
{
	float prism = sdfh_triprism(p - vec3(dims.x * 0.5,0,0), dims * vec3(2,1,1));
	float bound = sdfh_box(p, dims * vec3(1,2,2));
	return sop_int(bound, prism);
}

float sdfh_prismspike(vec3 p, vec4 dims_prismratio_h)
{
	float 	prismratio_h 	= clamp(dims_prismratio_h.w, 0, 10);
	
	
	float 	prism_h 		= (prismratio_h) * dims_prismratio_h.x;
	float 	box_h 			= dims_prismratio_h.y - prism_h;
	
	vec3 	box_dim 		= vec3(dims_prismratio_h.x, box_h, dims_prismratio_h.z);
	vec3 	prism_dim 		= vec3(dims_prismratio_h.x, prism_h, dims_prismratio_h.z);
	
	float 	box 			= sdfh_box(p, box_dim);
	p 						= climb(p, box_dim);
	float 	prism			= sdfh_halfprism(p, prism_dim);
	
	float 	prism2			= sdfh_halfprism(p + yid * 0.0001, prism_dim);
	
	prism = min(prism,prism2);
	
	return sop_uni(box,prism);
}

//retn dist + cut
vec2 sdfh_angled_window(vec3 p, vec3 dims, float angleratio, vec3 cutscalexy_yoff)
{
	vec2 cut_scale = cutscalexy_yoff.xy;
	float cut_yoff = cutscalexy_yoff.z;
	
	float basespike = sdfh_prismspike(p,vec4(dims, angleratio));
	
	vec3 innerspike_dim = dims * vec3(cut_scale.x, cut_scale.y, 1.1);
	
	float cut = sdfh_prismspike(p - yid * cut_yoff,vec4(innerspike_dim, angleratio));
	
	float cut_out = sdfh_prismspike(p - yid * cut_yoff + yid * innerspike_dim.y * 0.01,vec4(innerspike_dim * 1.02, angleratio));

	return vec2(sop_sub(basespike, cut), cut_out);	
}