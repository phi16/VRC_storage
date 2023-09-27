// Utilities 

// from https://www.shadertoy.com/view/4djSRW
float hash12(float2 p) {
    float3 p3  = frac(float3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}
float3 hash32(float2 p) {
    float3 p3 = frac(float3(p.xyx) * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return frac((p3.xxy+p3.yzz)*p3.zyx);
}

float3 sampleSphere(float2 seed) {
    const float pi = 3.1415926535;
    float th = hash12(seed) * pi * 2;
    float a = acos(1 - 2 * hash12(seed + 1));
    return float3(cos(th)*sin(a), cos(a), sin(th)*sin(a));
}

// https://gamedev.stackexchange.com/questions/28395/rotating-vector3-by-a-quaternion
float3 appQ(float4 q, float3 v) {
    // q v q*
    float3 u = q.xyz;
    float s = q.w;
    return 2 * dot(u,v) * u
        + (s*s - dot(u,u)) * v
        + 2 * s * cross(u,v);
}
float4 mulQ(float4 a, float4 b) {
    return float4(a.w*b.xyz + b.w*a.xyz + cross(a.xyz,b.xyz), a.w*b.w - dot(a.xyz,b.xyz));
}
float4 expQ(float3 rv) {
    float angle = length(rv);
    if(angle < 0.001) return float4(0,0,0,1);
    return float4(normalize(rv) * sin(angle/2), cos(angle/2));
}
float3 logQ(float4 q) {
    if (abs(q.w) > 1 - 0.00001f) return 0;
    float angle = 2 * acos(abs(q.w));
    return normalize(q.xyz) * angle * (q.w < 0 ? -1 : 1);
}

// Main

#define N 256
#define E uint2(2, 2)
#define F (N * E)

sampler2D _Store;

float _Init;

float4 pick(uint2 particleIndex, uint2 elementIndex) {
    return tex2Dlod(_Store, float4((particleIndex*E+elementIndex+0.5)/F, 0, 0));
}

float4 select(uint2 elementIndex, float4 d0, float4 d1, float4 d2, float4 d3) {
    return elementIndex.y == 0
        ? elementIndex.x == 0 ? d0 : d1
        : elementIndex.x == 0 ? d2 : d3;
}

float4 update(uint2 iuv) {
    uint2 ei = iuv % E;
    uint2 pi = iuv / E;
    float2 seed = float2(pi.x + pi.y * N, _Time.y);

    float4 d0 = pick(pi, uint2(0,0));
    float4 d1 = pick(pi, uint2(1,0));
    float4 d2 = pick(pi, uint2(0,1));
    float4 d3 = pick(pi, uint2(1,1));

    float3 p = d0.xyz;
    float t = d0.w;
    float4 q = d1.xyzw;
    float3 v = d2.xyz;
    float3 w = d3.xyz;
    float s = d2.w;
    float c = d3.w;

    if (_Init > 0.5) {
        p = 0;
        v = 0;
        q = float4(0, 0, 0, 1);
        w = 0;
        t = hash12(seed+0.1) * 0.4;
        s = 0;
        c = 0;
    } else {
        // Do any simulation
        float dt = unity_DeltaTime.z;
        t += dt;
        if (t > 0) {
            p += v * dt;
            q = mulQ(q, expQ(w * dt));
            v += float3(0, -10, 0) * dt;
        }
        if (t > 1) {
            p = 0;
            v = normalize(hash32(seed) - 0.5) * 5;
            v.y = abs(v.y) * 2;
            q = expQ(sampleSphere(seed+0.1) * 1);
            w = sampleSphere(seed+0.2) * 40 * (hash12(seed+0.25) * 0.5 + 0.5);
            s = exp(-hash12(seed+0.3)*40) * 0.1 + 0.01;
            t -= 1;
            c = s * 12 + _Time.y * 0.25;
        }
    }

    return select(ei, float4(p, t), q, float4(v, s), float4(w, c));
}
