Shader "phi16/SSR"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue"="Geometry+490" }
        LOD 100
        Cull Off

        GrabPass { }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 worldPos : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            sampler2D _CameraDepthTexture;
            sampler2D _GrabTexture;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
                o.worldNormal = mul((float3x3)UNITY_MATRIX_M, v.normal);
                o.uv = v.uv;
                return o;
            }
            
            float getDepth(float3 p) {
                float4 clipPos = mul(UNITY_MATRIX_P, float4(p,1));
                float4 projPos = ComputeScreenPos(clipPos);
                projPos.z = - p.z;
                float depth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, projPos));
                return depth;
            }
            float3 getColor(float3 p) {
                float4 clipPos = mul(UNITY_MATRIX_P, float4(p,1));
                float4 grabPos = ComputeGrabScreenPos(clipPos);
                float3 color = tex2Dproj(_GrabTexture, grabPos);
                return color;
            }
            
            float rand(float3 co){
                return frac(co.z + sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.worldNormal = normalize(i.worldNormal);
                float3 viewDir = i.worldPos - _WorldSpaceCameraPos;
                float3 skyColor = DecodeHDR(UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflect(viewDir, i.worldNormal)), unity_SpecCube0_HDR);
                // view space
                float3 reflDir = normalize(mul((float3x3)UNITY_MATRIX_V, reflect(viewDir, i.worldNormal)));
                float3 reflPos = mul(UNITY_MATRIX_V, float4(i.worldPos,1)).xyz;
                float distDelta = 0.3;
                float dist = distDelta * rand(reflDir + sin(_Time.y));
                float thickness = distDelta * 2;
                float3 pos = reflPos;
                int j = 0;
                for(;j<50;j++) {
                    dist += distDelta;
                    pos = reflPos + reflDir * dist;
                    float cd = getDepth(pos);
                    float pd = - pos.z;
                    if(cd < pd && cd > pd - thickness) break;
                }
                if(j == 50) return float4(skyColor,1);

                dist -= distDelta / 2;
                distDelta /= 4;
                j = 0;
                for(;j<5;j++) {
                    pos = reflPos + reflDir * dist;
                    float cd = getDepth(pos);
                    float pd = - pos.z;
                    if(cd < pd && cd > pd - thickness) {
                        dist -= distDelta;
                    } else {
                        dist += distDelta;
                    }
                    distDelta /= 2;
                }
                pos = reflPos + reflDir * dist;
                float4 clipPos = mul(UNITY_MATRIX_P, float4(pos,1));
                float4 projPos = ComputeScreenPos(clipPos);
                float2 screenUV = abs(projPos.xy / projPos.w * 2 - 1); // [0,1]
                float ae = 9.0;
                float attenDist = pow(pow(screenUV.x, ae) + pow(screenUV.y, ae), 1/ae);
                float3 col = getColor(pos);
                col = lerp(skyColor, col, saturate(1 - attenDist));
                return float4(col, 1);
            }
            ENDCG
        }
    }
}
