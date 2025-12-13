#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform float u_time;
uniform vec2 u_resolution;

out vec4 fragColor;

// --- Constants ---
const vec3 BEAM_COLOR = vec3(0.0, 0.506, 0.969); // Cyan-Blue
const vec3 GRID_COLOR = vec3(0.0, 0.8, 1.0);     // Bright Cyan Grid

// --- Noise Functions ---
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439,
             -0.577350269189626, 0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i);
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
        + i.x + vec3(0.0, i1.x, 1.0 ));
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

// --- Beam Logic ---
vec3 drawExpandingRings(vec2 uv, vec2 center, float scale) {
    float aspect = u_resolution.x / u_resolution.y;
    
    // Apply Skew
    vec2 skew = vec2(0.82, 1.18); 
    
    vec2 p = uv - center;
    p.x *= aspect;
    p *= skew;
    
    float modulo = fract(u_time * 0.2); 
    
    float ringRadius = scale * 0.5 * modulo;
    float distFromCenter = length(p);
    float ringDist = abs(distFromCenter - ringRadius);
    
    float lineRadius = 0.5 * modulo; 
    float brightness = lineRadius / (1.0 - smoothstep(0.2, 0.002, ringDist + 0.02));
    brightness = brightness * max(0.0, 1.0 - modulo);
    
    vec3 ringColor = brightness * pow(max(0.0, 1.0 - ringDist), 3.0) * BEAM_COLOR;
    return ringColor;
}

// --- Border Logic ---
vec3 drawViewportEdges(vec2 uv) {
    float distToEdge = min(min(uv.x, uv.y), min(1.0 - uv.x, 1.0 - uv.y));
    float glowThickness = 0.02 * 0.8;
    
    float glow = glowThickness / (1.0 - smoothstep(0.12, 0.01, abs(distToEdge) + 0.02));
    
    vec3 borderColor = vec3(0.27, 0.60, 1.0);
    return glow * pow(1.0 - abs(distToEdge), 3.0) * borderColor;
}

// --- Main ---
void main() {
    // 1. Setup Coordinates
    vec2 pos = FlutterFragCoord().xy;
    vec2 uv = pos / u_resolution;
    float aspect = u_resolution.x / u_resolution.y;

    // 2. Pixel Grid Simulation
    float gridSize = 0.012; 
    vec2 cellRatio = vec2(gridSize/aspect, gridSize);
    
    vec2 cellID = floor(uv / cellRatio);
    vec2 cellUV = (cellID + 0.5) * cellRatio;
    
    // 3. Noise Distortion
    float noiseScale = 3.0;
    float noiseSpeed = u_time * 0.2;
    float n = snoise(cellUV * noiseScale + vec2(0.0, noiseSpeed)); 
    
    vec2 distortedUV = cellUV + vec2(n) * 0.05; 

    // 4. Draw Content
    vec3 beam = drawExpandingRings(distortedUV, vec2(0.5, 0.5), 2.238);
    vec3 border = drawViewportEdges(uv);
    
    vec3 color = beam + border;

    // 5. Grid Overlay Lines
    vec2 gridF = fract(uv / cellRatio);
    float lineWidth = 0.15; 
    float gridPattern = step(1.0 - lineWidth, gridF.x) + step(1.0 - lineWidth, gridF.y);
    gridPattern = clamp(gridPattern, 0.0, 1.0);
    
    // Calculate brightness to mask the grid
    float brightness = dot(color, vec3(0.333));
    float visibilityMask = smoothstep(0.0, 0.1, brightness);
    
    // Mix grid only where visible
    color = mix(color, GRID_COLOR, gridPattern * 0.4 * visibilityMask); 
    
    // 6. Dither
    float dither = fract(sin(dot(pos, vec2(12.9898,78.233))) * 43758.5453) / 255.0;
    color += dither;

    // 7. Transparency Calculation
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    float alpha = smoothstep(0.0, 0.1, luma);

    fragColor = vec4(color, alpha);
}