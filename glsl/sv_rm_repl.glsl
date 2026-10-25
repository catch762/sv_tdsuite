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


//This shit doesnt really work or maybe it does but im keeping it for legacy
/*
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
*/

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

