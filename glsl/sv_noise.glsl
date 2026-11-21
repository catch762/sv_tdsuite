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

float gyroid (vec3 seed) { return dot(sin(seed),cos(seed.yzx)); }
float fbm_gyr (vec3 seed)
{
    float result = 0., a = .5;
    for (int i = 0; i < 8; ++i, a/=2.)
    {
        result += abs(gyroid(seed/a))*a;
    }
    return result;
}

float fbm_gyr (vec3 seed, int oct)
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
    float x = fbm_gyr(posx);
    float y = fbm_gyr(posy);
    float z = fbm_gyr(posz);
    return vec3(x,y,z);
}

vec3 multinoiseraw(vec3 coord, vec3 yseed, vec3 densities, vec2 feedback)
{
    vec3 posx = (coord + vec3(0, yseed.x, 0)) * densities.x;
	float x = fbm_gyr(posx);
	
    vec3 posy = (coord + vec3(0, yseed.y + x * feedback.x, 0)) * densities.y;
	float y = fbm_gyr(posy);
	
    vec3 posz = (coord + vec3(0, yseed.z + y * feedback.y, 0)) * densities.z;
    float z = fbm_gyr(posz);
    
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