// afl_ext 2017-2024
// MIT License


//So; the problem of time adding noise, and normal layer with different num octaves.





#define WSCALE (0.25 * 1.0)

#define DRAG_MULT (0.38 * WSCALE)  // changes how much waves pull on the water
#define WATER_DEPTH (2.0 * WSCALE) // how deep is the water

#define ITERATIONS_RAYMARCH 44 // waves iterations of raymarching
#define ITERATIONS_NORMAL 36 // waves iterations when calculating normals

#define NormalizedMouse (iMouse.xy / iResolution.xy) // normalize mouse coords

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
  float wavePhaseShift = length(position) * 0.1; // this is to avoid every octave having exactly the same phase everywhere
  float rotationSeed = 0.0;
  float frequency = 0.5 / WSCALE;
  float timeMultiplier = 0.5;
  float weight = 1.0;
  float sumOfValues = 0.0;
  float sumOfWeights = 0.0;
  for(int i=0; i < iterations; i++)
  {
    // generate some wave direction that looks kind of random
    vec2 p = vec2(sin(rotationSeed), cos(rotationSeed));
    
    // calculate wave data
    vec2 res = wave01_dx(position, p, frequency, (time) * timeMultiplier + wavePhaseShift);

    // shift position around according to wave drag and derivative of the wave
    position += p * res.y * weight * DRAG_MULT;

    // add the results to sums
    sumOfValues += res.x * weight;
    sumOfWeights += weight;

    // modify next octave ;
    weight = mix(weight, 0.0, 0.2);
    frequency *= 1.18;
    timeMultiplier *= 1.07;

    // add some kind of random value to make next wave look random too
    rotationSeed += 17.397963;
  }
  // calculate and return
  return sumOfValues / sumOfWeights;
}

//Water will be in height range [waterSurfaceY - waterDepth, waterSurfaceY]
float sdf_water(vec3 p, int iterations, float waterSurfaceY, float waterDepth)
{
	//height goes from -WATER_DEPTH to 0.0
	
	float waterHeightHere = waterSurfaceY + (getwaves01(p.xz, iterations) - 1.0) * waterDepth;
	
	float dist = p.y - waterHeightHere;
	
	return dist * 0.97;
}