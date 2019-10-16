Shader "Unlit/Baker"
{
    Properties
    {
        _Input ("Input", 2D) = "white"
    }
    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            Name "Update"

            CGPROGRAM
            
            #include "UnityCustomRenderTexture.cginc"
#define _BakedMap _SelfTexture2D
            #include "Util.cginc"
#undef _BakedMap

            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            
            float4 frag (v2f_customrendertexture i) : SV_Target
            {
                float2 uv = i.globalTexcoord;
                float4 result = tex2D(_SelfTexture2D, uv);
                float3 seed = float3(uv,0) + frac(result.xyz*10);
                Scene scene = loadScene();
                Point u = pointFromUV(scene,uv,seed);
                float3 col = emission(u);
                float3 acc = 0;
                const int N = 4;
                float3 pos = u.worldPos;
                float3 normal = u.worldNormal;
                float4 fc; // Unused
                for(int i=0;i<N;i++) {
                    float3 d = sampleDir(normal, seed+i);
                    Point uc = rayCast(scene, pos, d, fc);
                    if(uc.type >= 0) {
                        float3 i = radiance(uc);
                        acc += i * abs(dot(d, normal));
                    }
                }
                float3 f = reflectance(u) / pi;
                col += f * acc / N * (2 * pi);

                result.xyz += col;
                result.w += 1;
                bool trigger = length(unpack(getUV(30,1))) < 0.75;
                if(trigger) result = 0;

                return result;
            }
            ENDCG
        }
    }
}
