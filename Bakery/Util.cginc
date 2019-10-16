// Utility

#define pi 3.1415926535
float rand(float3 co){
    return frac(co.z + sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453);
}
float3 sampleDir(float3 n, float3 seed) {
	float r0 = rand(seed+_Time+0);
	float r1 = rand(seed+_Time+1);
	float r2 = rand(seed+_Time+2);
	float th = r0 * pi * 2 + r2;
	float u = r1 * 2 - 1;
	float3 pos = float3(sqrt(1-u*u)*float2(cos(th),sin(th)), u);
	float a = r2 * pi * 2;
	pos.yz = mul(float2x2(cos(a),sin(a),-sin(a),cos(a)), pos.yz);
	return dot(n,pos) > 0 ? pos : -pos;
}

sampler2D _Input;
static const float TexW = 256.0;

float3 unpack(float2 uv) {
    float3 e = float3(1.0/TexW/2, 3.0/TexW/2, 0);
    uint3 v0 = uint3(tex2Dlod(_Input, float4(uv - e.yz,0,0)).xyz * 255. + 0.5) << 0;
    uint3 v1 = uint3(tex2Dlod(_Input, float4(uv - e.xz,0,0)).xyz * 255. + 0.5) << 8;
    uint3 v2 = uint3(tex2Dlod(_Input, float4(uv + e.xz,0,0)).xyz * 255. + 0.5) << 16;
    uint3 v3 = uint3(tex2Dlod(_Input, float4(uv + e.yz,0,0)).xyz * 255. + 0.5) << 24;
    uint3 v = v0 + v1 + v2 + v3;
    return asfloat(v);
}
float2 getUV(uint n, uint m) {
	uint ix = (n * 16) % uint(TexW);
	uint iy = (n * 16) / uint(TexW);
	return float2(
		float(ix) + 2.0 + 4.0 * float(m),
		float(iy) + 0.5
	) / TexW;
}
float3 loadLocation(uint n) {
	return unpack(getUV(n,0));
}
void loadIsoMatrix(uint n, out float4x4 fm, out float4x4 im) {
    float3 loc = unpack(getUV(n,0));
    float3 mx = unpack(getUV(n,1));
    float3 my = unpack(getUV(n,2));
    float3 mz = unpack(getUV(n,3));
    float3x3 t = transpose(float3x3(mx, my, mz));
    fm = float4x4(mx, loc.x, my, loc.y, mz, loc.z, 0, 0, 0, 1);
    im = transpose(float4x4(mx, 0, my, 0, mz, 0, -mul(t, loc), 1));
}

// Coordinate definition

struct Scene {
	float4x4 shortBox, iShortBox;
	float4x4 tallBox, iTallBox;
	float4x4 smallBox, iSmallBox;
	float3 sphere;
	float3 emission;
	float3 glass;
	float4x4 mirror, iMirror;
};
struct Point {
	float2 localUV;
	float2 uvOffset;
	float3 worldPos;
	float3 worldNormal;
	int type;
	// -1: no collision
	// 0: outer
	// 1: short
	// 2: tall
};
float4 offsetFromUV(float2 uv) {
	// X index, Y index, Scale, OffsetY
	float h = uv.y * 7;
	if(h > 3) return float4(0,3,4,0);
	if(h > 1) return float4(floor(uv.x*2)*2,1,2,floor(uv.x*2)+1);
	return float4(floor(uv.x*4),0,1,floor(uv.x*4)+3);
}
float3 realOffset(float2 offset) {
	float2 base = 0;
	float scale = 0;
	if(offset.y < 0+0.5) base = float2(0,3), scale = 4;
	else if(offset.y < 2+0.5) base = float2((offset.y-1)*2,1), scale = 2;
	else base = float2(offset.y-3,0), scale = 1;
	return float3(base.x*6 + offset.x*scale, base.y, scale);
}
Point pointFromUV(Scene scene, float2 uv, float3 seed) {
	float4 o = offsetFromUV(uv);
	float2 mapUV = (uv*float2(4,7)-o.xy)/o.z*float2(6,1);
	uv = frac(mapUV)*2-1;
	float2 r = float2(rand(seed+_Time-1), rand(seed+_Time-2));
	uv += (r-0.5) / (o.z * 32);
	float3 p = 0, n = 0;
	if(mapUV.x < 1) {
		// Front
		p = float3(uv.xy,1);
		n = float3(0,0,1);
	} else if(mapUV.x < 2) {
		// Back
		p = float3(-uv.x,uv.y,-1);
		n = float3(0,0,-1);
	} else if(mapUV.x < 3) {
		// Left
		p = float3(1,uv.y,-uv.x);
		n = float3(1,0,0);
	} else if(mapUV.x < 4) {
		// Right
		p = float3(-1,uv.y,uv.x);
		n = float3(-1,0,0);
	} else if(mapUV.x < 5) {
		// Up
		p = float3(uv.x,1,-uv.y);
		n = float3(0,1,0);
	} else {
		// Down
		p = float3(uv.x,-1,uv.y);
		n = float3(0,-1,0);
	}
	Point u;
	u.localUV = uv * 0.5 + 0.5;
	u.uvOffset = float2(floor(mapUV.x), o.w);
	u.type = u.uvOffset.y;
	if(u.type == 0) {
		u.worldPos = p*0.5;
		u.worldNormal = -n;
	}
	if(u.type == 1) {
		u.worldPos = mul(scene.shortBox, float4(p*0.15,1)).xyz;
		u.worldNormal = mul((float3x3)scene.shortBox, n);
	}
	if(u.type == 2) {
		u.worldPos = mul(scene.tallBox, float4(p*float3(0.15,0.3,0.15),1)).xyz;
		u.worldNormal = mul((float3x3)scene.tallBox, n);
	}
	if(u.type == 3) {
		u.worldPos = mul(scene.smallBox, float4(p*0.08,1)).xyz;
		u.worldNormal = mul((float3x3)scene.smallBox, n);
	}
	if(u.type == 4) {
		p = normalize(p);
		u.worldPos = scene.sphere + p*0.1;
		u.worldNormal = p;
	}
	if(u.type == 5) {
		p = normalize(p);
		u.worldPos = scene.emission + p*0.05;
		u.worldNormal = p;
	}
	return u;
}

#ifndef _BakedMap
sampler2D _BakedMap;
#endif

float3 radiance(Point p) {
	float3 offsetScale = realOffset(p.uvOffset);
	float scale = offsetScale.z;
	float size = scale * 32;
	float2 uv = p.localUV * size - 0.5;
	float2 offset = offsetScale.xy;
	float2 e = float2(1/size,0);
	float2 f = frac(uv);
	float2 b = (floor(uv)+0.5) / size;
	float4 d = 0;
	float2 lb = e.xx/2, ub = 1 - e.xx/2;
	d += tex2D(_BakedMap, (clamp(b+e.yy,lb,ub)*scale+offset) / float2(24,7)) * (1-f.x) * (1-f.y);
	d += tex2D(_BakedMap, (clamp(b+e.xy,lb,ub)*scale+offset) / float2(24,7)) * f.x     * (1-f.y);
	d += tex2D(_BakedMap, (clamp(b+e.yx,lb,ub)*scale+offset) / float2(24,7)) * (1-f.x) * f.y;
	d += tex2D(_BakedMap, (clamp(b+e.xx,lb,ub)*scale+offset) / float2(24,7)) * f.x     * f.y;
	return d.w < 0.0001 ? 0 : d.xyz / d.w;
}

// Scene definition

// color data from https://www.shadertoy.com/view/4ssGzS
float3 emission(Point u) {
	float3 p = u.worldPos;
	if(u.type == 0 && p.y > 0.499 && abs(p.x) < 0.1 && abs(p.z) < 0.1) {
		return float3(16.86, 10.76, 3.7);
	}
	if(u.type == 5) {
		return float3(0.4,0.9,10.0);
	}
	return 0;
}
float3 reflectance(Point u) {
	float3 p = u.worldPos;
	if(u.type == 0) {
		if(p.x < -0.499) return float3(0.611, 0.0555, 0.062);
		if(p.x > 0.499) return float3(0.117, 0.4125, 0.115);
	}
	return float3(0.7295, 0.7355, 0.729);
}
Scene loadScene() {
	Scene s;
	loadIsoMatrix(0, s.shortBox, s.iShortBox);
	loadIsoMatrix(1, s.tallBox, s.iTallBox);
	loadIsoMatrix(2, s.smallBox, s.iSmallBox);
	s.sphere = loadLocation(3);
	s.emission = loadLocation(4);
	s.glass = loadLocation(5);
	loadIsoMatrix(6, s.mirror, s.iMirror);
	return s;
}
void rayCastBox(float3 p, float3 d, float4x4 m, float4x4 im, float3 s, float sign, int type, inout float minT, inout Point minU) {
	float3 plane[6] = {
		float3(0,0,+1),
		float3(0,0,-1),
		float3(+1,0,0),
		float3(-1,0,0),
		float3(0,+1,0),
		float3(0,-1,0)
	};
	for(int i=0;i<6;i++) {
		float3 o = mul(m, float4(plane[i]*s,1)).xyz;
		float3 n = mul((float3x3)m, plane[i]) * sign;
		if(dot(d,n) < 0) {
			// <p + d*t, n> = <o, n>
			// <p-o, n> + t * <d, n> = 0
			float t = - dot(p-o,n) / dot(d,n);
			float3 w = p + d * t;
			float3 l = mul(im, float4(w,1)).xyz / s;
			float3 c = abs(l) * (1 - abs(plane[i]));
			if(max(max(c.x,c.y),c.z) < 1 && 0 < t && t < minT) {
				minT = t;
				if(i == 0) minU.localUV = l.xy;
				if(i == 1) minU.localUV = l.xy * float2(-1,1);
				if(i == 2) minU.localUV = l.zy * float2(-1,1);
				if(i == 3) minU.localUV = l.zy;
				if(i == 4) minU.localUV = l.xz * float2(1,-1);
				if(i == 5) minU.localUV = l.xz;
				minU.localUV = minU.localUV * 0.5 + 0.5;
				minU.uvOffset = float2(i,type);
				minU.worldPos = w;
				minU.worldNormal = n;
				minU.type = type;
			}
		}
	}
}
float3 pmul(float3 a, float3 b) {
	return float3(a.y*b.y, a.z*b.y+a.y*b.z, a.z*b.z);
}
float3 sphereCollision(float3 p, float3 d, float3 o, float r) {
	float3 fx = float3(0,d.x,p.x-o.x);
	float3 fy = float3(0,d.y,p.y-o.y);
	float3 fz = float3(0,d.z,p.z-o.z);
	float3 s = pmul(fx,fx) + pmul(fy,fy) + pmul(fz,fz) - float3(0,0,r*r);
	float D = s.y*s.y - 4*s.x*s.z;
	if(D < 0) return 0;
	float s0 = (- s.y - sqrt(D)) / (2 * s.x);
	float s1 = (- s.y + sqrt(D)) / (2 * s.x);
	return float3(s0, s1, 1);
}
void rayCastSphere(float3 p, float3 d, float3 o, float r, float mode, int type, inout float minT, inout Point minU) {
	float3 col = sphereCollision(p, d, o, r);
	if(col.z > 0.5) {
		float t = mode < 0.5 ? col.x 
			                 : col.x > 0 ? col.x : col.y;
		if(0 < t && t < minT) {
			minT = t;
			float3 w = p + d * t;
			float3 l = normalize(w - o);
			float3 a = abs(l);
			float m = max(max(a.x,a.y),a.z);
			int i = 0;
			if(m == a.z) {
				if(l.z > 0) i = 0, minU.localUV = l.xy / l.z;
				else        i = 1, minU.localUV = - l.xy / l.z * float2(-1,1);
			} else if(m == a.x) {
				if(l.x > 0) i = 2, minU.localUV = l.zy / l.x * float2(-1,1);
				else        i = 3, minU.localUV = - l.zy / l.x;
			} else {
				if(l.y > 0) i = 4, minU.localUV = l.xz / l.y * float2(1,-1);
				else        i = 5, minU.localUV = - l.xz / l.y;
			}
			minU.localUV = minU.localUV * 0.5 + 0.5;
			minU.uvOffset = float2(i,type);
			minU.worldPos = w;
			minU.worldNormal = l * sign(distance(p,o)-r);
			minU.type = type;
		}
	}
}
void rayCastPlane(float3 p, float3 d, float4x4 m, float4x4 im, float2 s, int type, inout float minT, inout Point minU) {
	float3 plane = float3(0,0,1);
	float3 o = mul(m, float4(0,0,0,1)).xyz;
	float3 n = mul((float3x3)m, plane);
	// <p + d*t, n> = <o, n>
	// <p-o, n> + t * <d, n> = 0
	float t = - dot(p-o,n) / dot(d,n);
	float3 w = p + d * t;
	float2 l = mul(im, float4(w,1)).xy / s;
	float2 c = abs(l);
	if(max(c.x,c.y) < 1 && 0.001 < t && t < minT) {
		minT = t;
		minU.localUV = 0;
		minU.uvOffset = 0;
		minU.worldPos = w;
		minU.worldNormal = n;
		minU.type = type;
	}
}
Point singleRayCast(Scene s, float3 p, float3 d) {
	float minT = 1000;
	Point minU;
	minU.type = -1;
	float4x4 i = float4x4(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1);
	rayCastBox(p, d, i, i, float3(0.5,0.5,0.5), -1, 0, minT, minU);
	rayCastBox(p, d, s.shortBox, s.iShortBox, 0.15, 1, 1, minT, minU);
	rayCastBox(p, d, s.tallBox, s.iTallBox, float3(0.15,0.3,0.15), 1, 2, minT, minU);
	rayCastBox(p, d, s.smallBox, s.iSmallBox, 0.08, 1, 3, minT, minU);
	rayCastSphere(p, d, s.sphere, 0.1, 0, 4, minT, minU);
	rayCastSphere(p, d, s.emission, 0.05, 0, 5, minT, minU);
	rayCastSphere(p, d, s.glass, 0.1, 1, 6, minT, minU);
	rayCastPlane(p, d, s.mirror, s.iMirror, 0.15, 7, minT, minU);
	return minU;
}
Point rayCast(Scene s, float3 p, float3 d, out float4 firstCollision) {
	// Available Light Transport:
	// diffuse - diffuse
	// diffuse - mirror - diffuse
	// diffuse - glass - diffuse
	// diffuse - mirror - glass - diffuse
	// diffuse - glass - mirror - diffuse
	// diffuse - glass - mirror - glass - diffuse
	Point u = singleRayCast(s, p, d);
	firstCollision = u.type == -1 ? 0 : float4(u.worldPos, 1);
	float baseEta = 1.5;
	for(int i=0;i<4;i++) {
		if(u.type == 6) { // Glass
			float eta = 1 / baseEta;
			if(distance(p, s.glass) < 0.1) eta = 1 / eta;
			d = refract(d, u.worldNormal, eta);
			p = u.worldPos + d * 0.001;
			if(length(d) < 0.001) { // total reflection
				u.type = -1;
			} else {
				u = singleRayCast(s, p, d);
			}
		}
		if(u.type < 6) return u;
		if(u.type == 7) { // Mirror
			d = reflect(d, u.worldNormal);
			p = u.worldPos;
			u = singleRayCast(s, p, d);
		}
		if(u.type < 6) return u;
	}
	
	// should never occur
	u.type = -1;
	return u;
}