// afl_ext 2017-2024
// MIT License

// Use your mouse to move the camera around! Press the Left Mouse Button on the image to look around!

#define DRAG_MULT 0.38 // changes how much waves pull on the water
#define WATER_DEPTH 0.5 // how deep is the water
#define CAMERA_HEIGHT 1.5 // how high the camera should be
#define ITERATIONS_RAYMARCH 12 // waves iterations of raymarching
#define ITERATIONS_NORMAL 36 // waves iterations when calculating normals

#define NormalizedMouse (iMouse.xy / iResolution.xy) // normalize mouse coords

// Calculates wave value and its derivative, 
// for the wave direction, position in space, wave frequency and time
vec2 wavedx(vec2 position, vec2 direction, float frequency, float timeshift) {
  float x = dot(direction, position) * frequency + timeshift;
  float wave = exp(sin(x) - 1.0);
  float dx = wave * cos(x);
  return vec2(wave, -dx);
}

// Calculates waves by summing octaves of various waves with various parameters
float getwaves(vec2 position, int iterations) {
  float wavePhaseShift = length(position) * 0.1; // this is to avoid every octave having exactly the same phase everywhere
  float iter = 0.0; // this will help generating well distributed wave directions
  float frequency = 2.0; // frequency of the wave, this will change every iteration
  float timeMultiplier = 0.5; // time multiplier for the wave, this will change every iteration
  float weight = 1.0;// weight in final sum for the wave, this will change every iteration
  float sumOfValues = 0.0; // will store final sum of values
  float sumOfWeights = 0.0; // will store final sum of weights
  for(int i=0; i < iterations; i++) {
    // generate some wave direction that looks kind of random
    vec2 p = vec2(sin(iter), cos(iter));
    
    // calculate wave data
    vec2 res = wavedx(position, p, frequency, time * timeMultiplier + wavePhaseShift);

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
    iter += 1232.399963;
  }
  // calculate and return
  return sumOfValues / sumOfWeights;
}

float sdf_water(vec3 p)
{
	//height goes from -WATER_DEPTH to 0.0
	float waterSurface = (getwaves(p.xz, ITERATIONS_RAYMARCH) - 1.0) * WATER_DEPTH;
	return p.y - waterSurface;
}