// afl_ext 2017-2024
// MIT License


//So; the problem of time adding noise, and normal layer with different num octaves.





#define WSCALE (0.25 * 1.0)

#define DRAG_MULT (0.38 * WSCALE)  // changes how much waves pull on the water
#define WATER_DEPTH (1.0 * WSCALE) // how deep is the water

#define ITERATIONS_RAYMARCH 12  // waves iterations of raymarching
#define ITERATIONS_NORMAL 36 // waves iterations when calculating normals


// Calculates wave value and its derivative, 
// for the wave direction, position in space, wave frequency and time
vec2 wave01_dx(vec2 position, vec2 direction, float frequency, float timeshift)
{
	//Its not radial wave, its straight line wave going towards dir,
	//so dot(dir,pos) gives us sorta phase of the wave
	float phase = dot(direction, position) * frequency + timeshift;
	
	//exp adds exponential curve, which makes wave look more natural.
	//also, exp specifically, makes calculating derivative easier.
	//'wave' will be within [~0.1, 1.0] 
	float wave = exp(sin(phase) - 1.0);
	
	//So, the derivative. Do we REALLY need it? No. But i ll keep it.
	float dx = wave * cos(phase);
	return vec2(wave, -dx);
}

// Calculates waves by summing octaves of various waves with various parameters
float getwaves01(vec2 position, int iterations)
{
  float wavePhaseShift = length(position) * 0.1 * WSCALE; // this is to avoid every octave having exactly the same phase everywhere
  float rotationSeed = 0.0;
  float frequency = 0.5 / WSCALE;
  float timeMultiplier = 0.75;
  float weight = 1.0;
  float sumOfValues = 0.0;
  float sumOfWeights = 0.0;
  for(int i=0; i < iterations; i++)
  {
    // generate some wave direction that looks kind of random
    vec2 wavedir = vec2(sin(rotationSeed), cos(rotationSeed));
    
    //Very important line. If we dont constrain, large values will fuck up the sin() call. Conterintuitive, yes.
	float timeUsed = mod(time * timeMultiplier, 2.0 * PI);
	
	// calculate wave data
    vec2 res = wave01_dx(position, wavedir, frequency, timeUsed + wavePhaseShift);

    // shift position around according to wave drag and derivative of the wave
    position += wavedir * res.y * weight * DRAG_MULT;

    // add the results to sums
    sumOfValues += res.x * weight;
    sumOfWeights += weight;

    // modify next octave ;
    weight = mix(weight, 0.0, 0.2);
    frequency *= 1.18;
    timeMultiplier *= 1.07;

    // add some kind of random value to make next wave look random too
    rotationSeed += 17.387963;
  }
  // calculate and return
  return sumOfValues / sumOfWeights;
}

//Water will be in height range [waterSurfaceY - waterDepth, waterSurfaceY]
float waterHeightAt(vec2 xz, int iterations, float waterSurfaceY, float waterDepth)
{
	return waterSurfaceY + (getwaves01(xz, iterations) - 1.0) * waterDepth;
}

bool getCameraIsUnderwater(vec3 camera, float waterSurfaceY, float waterDepth)
{
	return camera.y < waterHeightAt(camera.xz, ITERATIONS_RAYMARCH, waterSurfaceY, waterDepth);
}
bool getCameraIsUnderwater(vec3 camera)
{
	return getCameraIsUnderwater(camera, 0.0, WATER_DEPTH);
}



float sdf_water(vec3 p, int iterations, float waterSurfaceY, float waterDepth, bool cameraIsUnderwater)
{
	//height goes from -WATER_DEPTH to 0.0
	
	float waterHeightHere = waterHeightAt(p.xz, iterations, waterSurfaceY, waterDepth);
	
	float underwaterSign = -boolean11(cameraIsUnderwater);
	
	float dist = p.y * underwaterSign - waterHeightHere * underwaterSign;
	
	return dist * 0.7;
}

float sdf_water(vec3 p, int iterations, bool cameraIsUnderwater)
{
	return sdf_water(p, iterations, 0.0, WATER_DEPTH, cameraIsUnderwater);
}



//Should work but i didnt test:


//orig had 0.01
#define SV_RM_WATER_EPSILON (0.01 * WSCALE)
//maybe experiment later
#define SV_RM_WATER_NORMAL_EPSILON_MOD 1.0

float water_march(Ray ray, float start, float end, bool cameraIsUnderwater)
{	
	float depth_reached = start;								
	for (int i = 0; i < 200; i++) 
	{		
		float dist_to_water = sdf_water(walkray(ray, depth_reached), ITERATIONS_RAYMARCH, cameraIsUnderwater);		
		if (dist_to_water < SV_RM_WATER_EPSILON) 					
		{
			return depth_reached;
		}					
		depth_reached += dist_to_water;								
		if (depth_reached >= end) break;						
	}				

	//ORIG HAD THIS:
	// if hit was not registered, just assume hit the top layer, 
	// this makes the raymarching faster and looks better at higher distances
	//return distance(start, camera);
	
	return SDF_OUTSIDE;								
}


vec3 water_normal(vec3 p, bool cameraIsUnderwater)
{
    vec2 	e = vec2(1.0,-1.0) * SV_RM_WATER_EPSILON * SV_RM_WATER_NORMAL_EPSILON_MOD;						
	float 	a = sdf_water(p + e.xyy, ITERATIONS_NORMAL, cameraIsUnderwater);					
	float 	b = sdf_water(p + e.yyx, ITERATIONS_NORMAL, cameraIsUnderwater);					
	float 	c = sdf_water(p + e.yxy, ITERATIONS_NORMAL, cameraIsUnderwater);					
	float 	d = sdf_water(p + e.xxx, ITERATIONS_NORMAL, cameraIsUnderwater);					
	return 	normalize(a*e.xyy + b*e.yyx + c*e.yxy + d*e.xxx);	
}
