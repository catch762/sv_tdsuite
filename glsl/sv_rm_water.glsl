float hashxxx( vec2 p )
{
    return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453123);
}

float noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( hashxxx( i + vec2(0.0,0.0) ), 
                     hashxxx( i + vec2(1.0,0.0) ), u.x),
                mix( hashxxx( i + vec2(0.0,1.0) ), 
                     hashxxx( i + vec2(1.0,1.0) ), u.x), u.y);
}

const mat2 mw = mat2(1.6,1.2,-1.2,1.6);

float thewater(vec3 p) {
    float d = p.y;
    
    float amp = .1;
    p.xz *= mw;
    float t = time*.3;
    
    // Add detail only if we are closed of the surface
    if (d < .2) {
        for(int i=0; i<6; i++)
        {
            d -= (1.-abs(sin(noise(p.xz-t)))) * amp;
            amp *= .5;
            p.xz *= mw;
        }
    }
    
    return d;
}