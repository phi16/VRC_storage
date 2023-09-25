Shader "Im/Template/Particles/Visual"
{
    Properties
    {
		_Store ("Store", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
		AlphaToMask On
		Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "Particles.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float3 color : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o = (v2f) 0;

				uint index = floor(v.vertex.z+0.5);
				v.vertex.z = 0;

				if (index >= N * N) {
					return o;
				}

				float4 d0 = pick(uint2(index%N, index/N), uint2(0,0));
				float4 d1 = pick(uint2(index%N, index/N), uint2(1,0));
				float4 d2 = pick(uint2(index%N, index/N), uint2(0,1));
				float4 d3 = pick(uint2(index%N, index/N), uint2(1,1));
				float3 p = d0.xyz;
				float4 q = d1.xyzw;
				float t = d0.w;
				float s = d2.w;
				float c = d3.w;
				float size = s;
				size *= 1 - exp(-(1 - t) * 8);

				if (t < 0) {
					return o;
				}
				v.vertex.xyz *= size;
				v.vertex.xyz = appQ(q, v.vertex.xyz);
				v.vertex.xyz += p;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv * 2 - 1;
				o.color = cos(float3(0,2,-2) + c * 3) * 0.5 + 0.5;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float d = length(i.uv) - 1;
				float dd = fwidth(d);
				float a = saturate(- d / dd + 0.5);
				float b = saturate(-(d + 0.2) / dd + 0.5);
				float3 c = lerp(i.color, i.color*0.8+0.2, b);
                return float4(c, a);
            }
            ENDCG
        }
    }
}
