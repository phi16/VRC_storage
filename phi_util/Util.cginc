#define pi 3.1415926535

float rand(float2 co){
    return frac(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453);
}

float2x2 ei(float a) {
    return float2x2(cos(a),-sin(a),sin(a),cos(a));
}

float mod(float x, float m) {
    return x - floor(x/m)*m;
}

float2 s1(float a) {
    return float2(cos(a), sin(a));
}

float2 pmod(float2 p, int m) {
    float a = atan2(p.y, p.x);
    float s = pi / m;
    a = mod(a + s, 2 * s) - s;
    return length(p) * s1(a);
}

float ts1(float x, float y, float m) {
    float d = (y - x) / m;
    d = frac(d + 0.5) - 0.5;
    return x + d * m;
}

float3 pack(float3 xyz, uint ix) {
    uint3 xyzI = asuint(xyz);
    xyzI = (xyzI >> (ix * 8)) % 256;
    return (float3(xyzI) + 0.5) / 255.0;
}

/* Useful Snippets

float3x3 R = (float3x3)unity_ObjectToWorld;

float2 uvs[4] = { float2(-1,-1), float2(-1,1), float2(1,-1), float2(1,1) };

o.grabPos = ComputeGrabScreenPos(o.vertex);
o.projPos = ComputeScreenPos(o.vertex);
o.projPos.z = - o.vertex.z;

float3 n = UnpackNormal(tex2D(_Normal, uv));

float3 forward = normalize(mul(transpose((float3x3)UNITY_MATRIX_V), float3(0,0,-1)));

float3 refl = DecodeHDR(UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflDir), unity_SpecCube0_HDR);

float3 unpack(int2 iuv) {
    float2 uv = (iuv + 0.5) / float2(IW/4, IH);
    float texWidth = IW;
    float3 e = float3(1.0 / texWidth / 2, 3.0 / texWidth / 2, 0);
    uint3 v0 = uint3(tex2Dlod(_Input, float4(uv - e.yz, 0, 0)).xyz * 255.) << 0;
    uint3 v1 = uint3(tex2Dlod(_Input, float4(uv - e.xz, 0, 0)).xyz * 255.) << 8;
    uint3 v2 = uint3(tex2Dlod(_Input, float4(uv + e.xz, 0, 0)).xyz * 255.) << 16;
    uint3 v3 = uint3(tex2Dlod(_Input, float4(uv + e.yz, 0, 0)).xyz * 255.) << 24;
    uint3 v = v0 + v1 + v2 + v3;
    return asfloat(v);
}

*/

// Quaternion

float4 mulQ(float4 a, float4 b) {
    return float4(a.w*b.xyz + b.w*a.xyz + cross(a.xyz,b.xyz), a.w*b.w - dot(a.xyz,b.xyz));
}
float4 conjQ(float4 q) {
    return float4(-q.xyz,q.w);
}
float4 invQ(float4 q) {
    return conjQ(q) / dot(q,q);
}
float4 axisQ(float3 rv) {
    float angle = length(rv);
    if(angle < 0.001) return float4(0,0,0,1);
    return float4(normalize(rv) * sin(angle/2), cos(angle/2));
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

// Distance Field

float sdBox(float2 p, float2 s) {
    float2 d = abs(p) - s;
    return length(max(d,0)) + min(max(d.x,d.y),0);
}
