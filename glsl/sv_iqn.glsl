//********************
// IQN NOISE BEGIN  //
//********************

#define IQN_ONLY_ADD 0
#define IQN_SWITCH_ADD_SUB 1
#define IQN_ONLY_SHROT 1

//Note: some functions use 'vec4 idx', where XYZ is 3d grid index and W is octavedepth01

//dont use it anymore
vec3 iqn_gethash(vec4 idx)
{
	vec3 	noisehash 	= vec3(	iq_hash3(idx.xyz),
								iq_hash3(idx.xyz + vec3(22.4,-5.73,111.7) * idx.w),
								iq_hash3(idx.xyz*4.762 + vec3(-1,-33.33 * idx.w,55)) );
	
	return noisehash;
}

float iqn_gethash_alt(vec4 idx)
{
	return iq_hash3(idx.xyz + vec3(22.4,-5.73,111.7) * idx.w);
}

struct ElemParams
{
#define IQN_ELEM_PARAM_LIST(F) 	F(Size)\
								F(Rot)\
								F(Trans)\
								F(Custom)\
								F(Extra)\
								F(Caleidrot)\
								F(Caleidtrans)\
								F(RoundClipformClipsizeNoisetodepth)\
								F(Pads)\
								F(PadsDelta)
								
#define ELEMPARAM_ADD(P) vec4 P;
IQN_ELEM_PARAM_LIST(ELEMPARAM_ADD)								
};


vec3 invertForOddIdx(vec3 p, vec3 idx)
{
	if ((int(idx.x)&1)==1) p.x *= -1;
	if ((int(idx.y)&1)==1) p.y *= -1;
	if ((int(idx.z)&1)==1) p.z *= -1;
	return p;
}

vec3 iqn_check8_transform(vec3 p, vec3 idx)
{
	p = invertForOddIdx(p, idx);
	
	return p;
}

//IQNEL means IQN individual Element, which is being instantiated in 3d grid.
//To add new iqnel:
//	- add iqnel_function (see iqnel_wirebox)
//	- call IQNEL_REGISTER(iqnel_register, %assign unique integer id yourself%)
//	- add it to IQN_ELEM_LIST below
//	- add the id to ui

#define IQNEL_ID(ELEM) 		ELEM ## _ID 
#define IQNEL_CHECK8(ELEM) 	ELEM ## _check8 

#define IQNEL_DEF_CHECK8(ELEM) float IQNEL_CHECK8(ELEM) 							\
(vec3 p, ElemParams prm_elem, float depth01)  				\
{																					\
	vec3 i = round(p);																\
	vec3 f = p-i;																	\
	vec3 off = sign(f);																\
	float RES = 99999;																\
	for (int y = 0; y <= 1; ++y)													\
	{																				\
		for (int x = 0; x <= 1; ++x)												\
		{																			\
			for (int z = 0; z <= 1; ++z)											\
			{																		\
				vec3 thisidx = i + vec3(x,y,z) * off;								\
				vec3 thiscoord = p - thisidx;										\
				thiscoord = iqn_check8_transform(thiscoord, thisidx);				\
				RES = min(RES, ELEM(thiscoord, vec4(thisidx, depth01), prm_elem));	\
			}																		\
		}																			\
	}																				\
	return RES;																		\
}



#define IQNEL_SET_ELEM_ID(ELEM, ID) const int IQNEL_ID(ELEM) = ID;

#define IQNEL_REGISTER(ELEM, ID)	IQNEL_DEF_CHECK8(ELEM) \
									IQNEL_SET_ELEM_ID(ELEM, ID)


//***[ IQNEL HELPER FUNCTIONS ]***
vec3 iqn_rot_trans(vec3 p, vec4 Rot, vec4 Trans)
{
	p = rot_y(p, Rot.y * Rot.w);
	p = rot_x(p, Rot.x * Rot.w);
	p = rot_z(p, Rot.z * Rot.w);

	p -= Trans.xyz * 0.5 * Trans.w;

	return p;
}

float iqn_finalclip(float dist, vec3 p_orig) //clips with 3d grid cell cube max area
{
	float clip = sdfc_box(p_orig, vec3(1));
	return sop_int(dist, clip);
}

vec3 iqn_Caleid(vec3 p, vec4 Caleidrot, vec4 Caleidtrans)
{
	vec3 finCaleidrot 	= mulw(Caleidrot);
	vec3 finCaleidtrans = mulw(Caleidtrans);
	
	p = mir_xyz(p, finCaleidtrans);
	
	p = rot_x(p, finCaleidrot.x);
	p = rot_y(p, finCaleidrot.y);
	p = rot_z(p, finCaleidrot.z);
	
	return p;
}

float iqn_RoundAndClip(float dist, vec3 pForClip, vec4 RoundClipformClipsizeNoisetodepth)
{
	float Rounding 	= RoundClipformClipsizeNoisetodepth.x;
	float SmK		= 0.1;
	
	dist -= Rounding;
	
	float clipObj = sdfc_cubeToOuterSphere(pForClip, RoundClipformClipsizeNoisetodepth.zy);		
	dist = sop_int_sm(dist, clipObj, SmK);
	
	return dist;
}

//returns values from [-2 to 2], unclamped
vec4 iqn_getPadsWithDelta(vec4 Pads, vec4 PadsDelta, vec4 idx, float Noisetodepth01)
{
	float 	idxhash 	= iqn_gethash_alt(idx);
	float   Diffsrc01	= mix(idxhash, idx.w, Noisetodepth01);
	vec4 	finPads 	= Pads + PadsDelta * Diffsrc01;
	return 	finPads;
}
//***[ / IQNEL HELPER FUNCTIONS ]***


float iqnel_sphere(vec3 p, vec4 idx, ElemParams prm)
{
	float radius = 0.5 * iq_hash3(idx.xyz);
	return sdf_sphere(p, radius);
}
IQNEL_REGISTER(iqnel_sphere, 0)

float iqnel_wirebox(vec3 p_orig, vec4 idx, ElemParams EP)
{
	vec3 p = p_orig;
	
	p = iqn_rot_trans(p, EP.Rot, EP.Trans);
	
	float res = sdf_wirebox(p, EP.Size.xyz/2.0, 0.25 * EP.Size.w);

	return iqn_finalclip(res, p_orig);
}
IQNEL_REGISTER(iqnel_wirebox, 1)

//wirebox with caleidoscope and onion
float iqnel_wbco(vec3 p_orig, vec4 idx, ElemParams EP)
{
	float 	RES 		= SDF_SURELY_OUTSIDE;
	vec3 	p 			= p_orig;	
	
	vec4 Pads = iqn_getPadsWithDelta(EP.Pads, EP.PadsDelta, idx, EP.RoundClipformClipsizeNoisetodepth.w);
	{
		addclamp11(EP.Caleidrot.w, 		Pads.x);
		addclamp11(EP.Caleidtrans.w, 	Pads.y);
		addclamp01(EP.Size.y, 			Pads.z);
		addclamp11(EP.Trans.y, 			Pads.w);
	}
	EP.Custom *= 0.125;
	
	p = iqn_rot_trans(p, EP.Rot, EP.Trans);
	
	{
		p = iqn_Caleid(p, EP.Caleidrot, EP.Caleidtrans);
		
		float obj = sdfc_wirebox(p, vec3(EP.Size.xyz), EP.Size.w);
		obj *= sign(EP.Extra.x);

		obj = sop_onion(obj, EP.Custom.x, EP.Custom.y);
		obj *= sign(EP.Extra.y);
		
		obj = sop_onion(obj, EP.Custom.z, EP.Custom.w);
		obj *= sign(EP.Extra.z);
		//obj += EP.Extra.w;

		obj = iqn_RoundAndClip(obj, p_orig, EP.RoundClipformClipsizeNoisetodepth);
		
		
		ADD(obj);
	}
	
	return iqn_finalclip(RES, p_orig);
}
IQNEL_REGISTER(iqnel_wbco, 2)

//Single list where you define all used IQNEL's
#define IQN_ELEM_LIST(F) 	F(iqnel_sphere)\
							F(iqnel_wirebox)\
							F(iqnel_wbco)
					
float iqn_sdf(vec3 p, int sdf_id, ElemParams prm_elem, float depth01)
{
#define IQN_SDF_ENTRY(ELEM) else if (sdf_id == IQNEL_ID(ELEM))\
							{return IQNEL_CHECK8(ELEM)(p, prm_elem, depth01);}	
							
	if(false){}
	IQN_ELEM_LIST(IQN_SDF_ENTRY)
	else return SDF_SURELY_OUTSIDE;
}

float iqn_sdf_single(vec3 p, int sdf_id, vec3 idx, ElemParams prm_elem, float depth01)
{
#define IQN_SDF_SINGLE_ENTRY(ELEM) 	else if (sdf_id == IQNEL_ID(ELEM))\
									{return ELEM (p, vec4(idx, depth01), prm_elem);}	
							
	if(false){}
	IQN_ELEM_LIST(IQN_SDF_SINGLE_ENTRY)
	else return SDF_SURELY_OUTSIDE;
}


#define IQN_NOP 0
#define IQN_IQROT 1
#define IQN_SHROT 2
vec3 iqn_OctaveTransformOperation(vec3 p, int octop_id, vec4 prm_octop, float octscale)
{
#if IQN_ONLY_SHROT == 0
	if (octop_id == IQN_SHROT)
#endif
	{
		p = rot_y(p, 0.125 * prm_octop.y);
		p = rot_x(p, 0.125 * prm_octop.x);
		
		p = rot_z(p, 0.125 * prm_octop.z);

		p /= octscale;
			
		p += vec3(1.231,0.761,2.54)*4.5*prm_octop.w;
	}
#if IQN_ONLY_SHROT == 0
	else if (octop_id == IQN_IQROT)
	{
		//this matrix is rot + x2 scale
		vec3 pBaseX2 = mat3( 0.00, 1.60, 1.20, -1.60, 0.72,-0.96,-1.20,-0.96, 1.28 ) * p;
		p = (pBaseX2 * 0.5) / octscale;
	}
	else
	{
		p /= octscale;
	}
#endif
	
	return p; //id 0
}

float depth01(int iter, int maxiters) //assumes iter within [0, maxiters)
{
	if (maxiters <= 1) return 0;
	return iter/float(maxiters-1);
}

vec2 iqn_master(	vec3 			p,
					float 			host_dist,
					int 			sdf_id,
					int 			octop_id,
					int 			mode,
					int 			numoct,
					vec2 			NeighbOctmod,
					vec4 			scale_smooth2_octscale,
					ElemParams 		prm_elem,
					vec4 			prm_octop)
{
	float		curdist			= host_dist;
    float 		curscale        = scale_smooth2_octscale.x;
    const float SM_K_PARENTING  = scale_smooth2_octscale.y;
    const float SM_K_MAINOP     = scale_smooth2_octscale.z;
	const float octscalemod		= scale_smooth2_octscale.w;
		
	float 		neighborhood 	= NeighbOctmod.x;
	
	int 		cur_octid 		= -1;
	int 		prev_octid 		= cur_octid;
	
    p = p / curscale;   
    for (int i = 0; i<numoct; i++ )
    {
		float 	depth01 = depth01(i, numoct);
		
        float   nextdist    	= curscale * iqn_sdf(p, sdf_id, prm_elem, depth01);
		
		//this makes object represented by 'curdist' to become slightly inflated
		float 	parentingdist 	= curdist - neighborhood * curscale;
		
		
		
		//and then we clip 'nextdist' with it using smooth intersection
        nextdist            	= sop_int_sm	(nextdist, parentingdist, curscale * SM_K_PARENTING);
		
		//if (abs(nextdist - parentingdist) < 0.01) return vec2(curdist, cur_octid);
		
		
        if (bool(IQN_ONLY_ADD) || mode == 1) //smooth union
		{
			cur_octid 	= nextdist < curdist ? i : prev_octid;
			prev_octid 	= cur_octid;
			
			curdist    	= sop_uni_sm  	(curdist, nextdist, curscale * SM_K_MAINOP);	
		}
        else //smooth subtraction
		{
			curdist    	= sop_sub_sm  	(curdist, nextdist, curscale * SM_K_MAINOP);
		}
		
        p               = iqn_OctaveTransformOperation(p, octop_id, prm_octop, octscalemod);
		
        curscale        *= octscalemod;		
		neighborhood 	*= NeighbOctmod.y;
		
		#if IQN_SWITCH_ADD_SUB
			mode = 1 - mode;
		#endif
    }
    return vec2(curdist, cur_octid);
}

//********************
// end-of IQN NOISE //
//********************