#define RES 32

float4 sampleVolume(uint atlasIndex, uint3 localCoord) {
    int3 ix = localCoord;

    float3 L0 = 0, L1r = 0, L1g = 0, L1b = 0;

    L0 = cos(dot(localCoord, 0.5) + float3(0,2,-2) + _Time.y * 2) * 0.5 + 0.5;

    if(ix.x == 0) L0 = 1;
    if(ix.y == 0) L0 = 1;
    if(ix.z == 0) L0 = 1;
    if(ix.x == RES-1) L0 = 1;
    if(ix.y == RES-1) L0 = 1;
    if(ix.z == RES-1) L0 = 1;

    float4 tex0 = float4(L0, L1r.z);
    float4 tex1 = float4(L1r.x, L1g.x, L1b.x, L1g.z);
    float4 tex2 = float4(L1r.y, L1g.y, L1b.y, L1b.z);
    return atlasIndex == 0 ? tex0 : atlasIndex == 1 ? tex1 : tex2;
}