// Based on https://www.shadertoy.com/view/XtBXzD
Shader "Unlit/ArcSegment"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		iMouse("mouse pos", Vector) = (0.0, 0.0, 0.0, 0.0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

			float4 iMouse;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

			float sq(float a) { return a * a; }
			float clampUnit(float a) { return clamp(a, 0.0, 1.0); }
			float2 orthoCloc(float2 b) { return float2(b.y, -b.x); }
			float2 orthoCoun(float2 b) { return float2(-b.y, b.x); }

			float circleOpacity(float2 uv, float pixelSize, float innerRadius, float2 angleUnit) {
				float2 relToCenter = (uv - float2(0.5, 0.5)) * 2.0;
				float distSquared = dot(relToCenter, relToCenter);
				float fringeSpan = 2.8*pixelSize;
				float halfFringeSpan = fringeSpan / 2.0;
				float outerInnerEdge = sq(1.0 - halfFringeSpan);
				float innerFade = (max(distSquared, sq(fringeSpan)) - sq(innerRadius - halfFringeSpan)) / (sq(innerRadius + halfFringeSpan) - sq(innerRadius - halfFringeSpan));
				float outerFade = 1.0 - (distSquared - outerInnerEdge) / ((1.0 + halfFringeSpan) - outerInnerEdge);
				float angleFade;
				float distFromAngleUnit = 1.0 - dot(orthoCloc(relToCenter), angleUnit) / fringeSpan;
				float distFromXAxis = (relToCenter.y + fringeSpan) / fringeSpan;
				if (angleUnit.y > 0.0) {
					angleFade = min(distFromAngleUnit, distFromXAxis);
				}
				else {
					angleFade = max(distFromAngleUnit, distFromXAxis);
				}
				return clampUnit(min(min(innerFade, outerFade), angleFade));
			}

            fixed4 frag (v2f i) : SV_Target
            {
                
				float2 uv = i.uv.xy;
				float pixelSize = 1.0 / max(_ScreenParams.x, _ScreenParams.y);
				float mouseLen;
				float2 mouseNormal;

				// mousing in lower left corner gets you presets
				if (iMouse.x < 10.0 && iMouse.y < 10.0)
				{
					mouseLen = 0.8;
					mouseNormal = float2(-0.5, -0.5);
				}
				else if (iMouse.x < 10.0 && iMouse.y < 20.0) {
					mouseLen = 0.0;
					mouseNormal = float2(1.0, 0.0);
				}
				else {
					float2 mouseRelCenter = (iMouse.xy / _ScreenParams.xy - float2(0.5, 0.5)) * 2.0;
					mouseLen = length(mouseRelCenter);
					mouseNormal = normalize(mouseRelCenter);
				}

				float4 col = float4(1.0, 1.0, 1.0, circleOpacity(uv, pixelSize, mouseLen, mouseNormal));
				col = float4(lerp(float3(0.0, 0.0, 0.0), col.rgb, col.a), 1.0);
				return col;
            }
            ENDCG
        }
    }
}
