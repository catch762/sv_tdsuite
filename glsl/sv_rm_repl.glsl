//repl endlessly in all directions, quickest simplest version
vec3 	sop_repl	(vec3 p, vec3 size)
{
	return mod(p + 0.5 * size,size) - 0.5 * size;
}

//replicate endlessly along one axis
float 	sop_repl	(float p, float size)
{
    float idx = floor(to_cellspace(p, size));
	
	return p - idx * size;
}

//replicate in finite index range
float 	sop_repl	(float p, float size, int idxmin, int idxmax, out int idx)
{
    idx = int(floor(to_cellspace(p, size)));
	idx = clamp(idx, min(idxmin, idxmax), max(idxmin, idxmax));
	
	return p - idx * size;
}

//If objects in neighbor cells are not mirroring each other, we need multiple
//render calls to avoid artifacts; this function applies mirroring, so one call
//will be enough
float 	sop_repl_mir(float p, float size, int idxmin, int idxmax, out int idx)
{
    float repeated_p = sop_repl(p,size,idxmin,idxmax,idx);
	return repeated_p * even11(idx); //inverted for odd indexes
}

vec3 	sop_repl	(vec3 p, vec3 size, ivec3 idxfrom, ivec3 idxto, out ivec3 idx)
{
    int     x_idx;
    float   x_inner = sop_repl(p.x, size.x, idxfrom.x, idxto.x, x_idx);
    int     y_idx;
    float   y_inner = sop_repl(p.y, size.y, idxfrom.y, idxto.y, y_idx);
    int     z_idx;
    float   z_inner = sop_repl(p.z, size.z, idxfrom.z, idxto.z, z_idx);

    idx             = ivec3(x_idx, y_idx, z_idx);
    return vec3(x_inner,y_inner,z_inner);
}

vec3 	sop_repl_mir(vec3 p, vec3 size, ivec3 idxfrom, ivec3 idxto, out ivec3 idx)
{
    int     x_idx;
    float   x_inner = sop_repl_mir(p.x, size.x, idxfrom.x, idxto.x, x_idx);
    int     y_idx;
    float   y_inner = sop_repl_mir(p.y, size.y, idxfrom.y, idxto.y, y_idx);
    int     z_idx;
    float   z_inner = sop_repl_mir(p.z, size.z, idxfrom.z, idxto.z, z_idx);

    idx             = ivec3(x_idx, y_idx, z_idx);
    return vec3(x_inner,y_inner,z_inner);
}

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
    
	//thats the bilateral symmetry part; if u dont do this,
	//u might need to also calculate adjacent indexes objects
    angle = abs(angle);
    
    float radius = length(vec2(point.x, point.z));
    
    // Reconstruct the point in the folded sector
    vec3 result;
    result.x = radius * cos(angle);
    result.z = radius * sin(angle);
    result.y = point.y;
    
    return result;
}

