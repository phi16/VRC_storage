Shader "Custom/surface" {
	Properties {
		_BaseColor ("Base Color", 2D) = "white" {}
		_Detail1 ("Detail1", 2D) = "white" {}
		_Detail2 ("Detail2", 2D) = "white" {}
		_Normal ("Normal", 2D) = "bump" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" "DisableBatching"="True" }
		LOD 200
		Cull Off
		
		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows vertex:vert
		#pragma target 3.0

		sampler2D _BaseColor, _Detail1, _Detail2, _Normal;

		struct Input {
			float2 uv_BaseColor;
			float3 vertexNormal;
			float3 vertexTangent;
			float3 worldNormal;
			float3 viewDir;
			INTERNAL_DATA
		};

		UNITY_INSTANCING_CBUFFER_START(Props)
		UNITY_INSTANCING_CBUFFER_END

		float rand(float2 co){
			return frac(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453);
		}

		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);
			
			fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
			fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
			fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
			fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;

			float3 normal = tex2Dlod(_Normal, float4(v.texcoord.xy,0,0)).xyz;
			normal = normalize(pow(normal.rgb,1/2.2) * 2 - 1);
			float3 tangent = float3(1,0,0);
			
			float4 detail2 = tex2Dlod(_Detail2, float4(v.texcoord.xy,0,0));
			float flatness = detail2.r;
			
			float3 vNormal   = normalize(v.normal);
			float3 vTangent  = normalize(v.tangent.xyz);
			float3 vBinormal = normalize(cross(vTangent, vNormal));
			float3 wT = normalize(worldTangent);
			float3 wB = normalize(worldBinormal);
			float3 wN = normalize(worldNormal);
			float flipped = dot(cross(wT, wN), wB);
			if(flipped < 0.0) vBinormal *= -1.0;
			float3x3 vertexRot = float3x3(vTangent, vBinormal, vNormal);
			float3 targetN = float3(0,0,1);
			float3 targetT = tangent;
			float3 mappedN = mul(vertexRot, targetN);
			float3 mappedT = mul(vertexRot, targetT);
			float3 modNormal  = normalize(lerp(normal,  mappedN, flatness));
			float3 modTangent = normalize(lerp(tangent, mappedT, flatness));

			vNormal  = mul(transpose(vertexRot), modNormal);
			vTangent = mul(transpose(vertexRot), modTangent);
			
			v.normal      = o.vertexNormal  = normalize(lerp(v.normal,      vNormal,  flatness));
			v.tangent.xyz = o.vertexTangent = normalize(lerp(v.tangent.xyz, vTangent, flatness));
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			float4 baseColor = tex2D(_BaseColor, IN.uv_BaseColor);
			float4 detail1 = tex2D(_Detail1, IN.uv_BaseColor);
			float4 detail2 = tex2D(_Detail2, IN.uv_BaseColor);
			float3 normal = tex2D(_Normal, IN.uv_BaseColor).xyz;
			float roughness = detail1.r;
			float metalic = detail1.g;
			float thickness = detail1.b;
			float flatness = detail2.r;
			float2 anisotropic = detail2.gb;
			float anisotropicStrength;
			normal = normalize(pow(normal.rgb,1/2.2) * 2 - 1);
			anisotropic = pow(anisotropic,1/2.2) * 2 - 1;
			anisotropicStrength = length(anisotropic);
			anisotropic = normalize(anisotropic);
			
			float3 vNormal   = normalize(IN.vertexNormal);
			float3 vTangent  = normalize(IN.vertexTangent);
			float3 vBinormal = normalize(cross(vTangent, vNormal));
			float3 wT = normalize(WorldNormalVector(IN, float3(1,0,0)));
			float3 wB = normalize(WorldNormalVector(IN, float3(0,1,0)));
			float3 wN = normalize(WorldNormalVector(IN, float3(0,0,1)));
			float flipped = dot(cross(wT, wN), wB);
			if(flipped < 0.0) vBinormal *= -1.0;
			float3x3 vertexRot = float3x3(vTangent, vBinormal, vNormal);
			float3 target = float3(0,0,1);
			float3 mapped = mul(vertexRot, target);
			normal = normalize(lerp(normal, mapped, flatness));
			float a = atan2(anisotropic.y, anisotropic.x);
			a = (a * 6 + cos(a*16) * 4 + sin(a*7) * 3) * 4;
			normal += mul(vertexRot, cross(wN, float3(0,1,0))) * 0.3 * sin(a) * smoothstep(0,1,anisotropicStrength);
			normal = normalize(normal);

			float3 wNormal = normalize(WorldNormalVector(IN, normal));
			float3 backGI  = ShadeSH9(half4(-wNormal,1));
			float3 frontGI = ShadeSH9(half4(wNormal,1));
			float3 gi = lerp(frontGI, backGI, 0.7);

			o.Albedo = baseColor.rgb;
			o.Normal = normal;
			o.Metallic = metalic;
			o.Smoothness = (1.0 - roughness) * 0.8;
			float sss = 1.0 - thickness;
			sss += sss * (1.0 - dot(IN.viewDir, float3(0,0,1)));
			o.Emission = gi * float3(1,0.5,0.5) * baseColor.rgb * sss * 0.5;

			// o.Albedo = o.Metallic = o.Smoothness = 0.0;
			// o.Emission = WorldNormalVector(IN, normal) * 0.5 + 0.5;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
