float4x4 objectToWorldMatrix;
float4x4 worldToCameraMatrix;
float4x4 projMatrix;
float4x4 textureMatrix;

float2 center;
float radius;
float strength;
float bias;
float2 center2;
float radius2;
float strength2;
float bias2;


Texture2D txDiffuse;

SamplerState samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};

struct VS_IN
{
    float4 pos : POSITION;
    float3 normal: NORMAL;
    float4 col : COLOR;
    float2 texCoord : TEXCOORD;
    float3 tangent: TANGENT;
    float3 binormal: BINORMAL;
};

struct PS_IN
{
    float4 pos : SV_POSITION;
    float4 col : COLOR;
    float2 texCoord: TEXCOORD0;
};

PS_IN VS( VS_IN input )
{
    PS_IN output = (PS_IN)0;

    input.pos = mul(input.pos, objectToWorldMatrix);

    float4 d1 = input.pos - float4( center.x, center.y, 0,1);
    float distance1 = length(d1);    
    float4 offset1=  d1 * pow( smoothstep(1,0, distance1/radius),  bias) * strength;

    float4 d2 = input.pos - float4( center2.x, center2.y, 0,1);
    float distance2 = length(d2);
    float4 offset2=  d2 * pow( smoothstep(1,0, distance2/radius2),  bias2) * strength2;

    input.pos = input.pos + offset1 + offset2;

    output.pos = mul(input.pos, worldToCameraMatrix);
    output.pos = mul(output.pos, projMatrix);

    output.col = input.col;
    output.texCoord = mul(float4(input.texCoord.xy, 0, 1), textureMatrix).xy;

    return output;
}

float4 PS( PS_IN input ) : SV_Target
{
    return txDiffuse.Sample(samLinear, input.texCoord) * input.col;
}

technique10 Render
{
    pass P0
    {
        SetGeometryShader( 0 );
        SetVertexShader( CompileShader( vs_4_0, VS() ) );
        SetPixelShader( CompileShader( ps_4_0, PS() ) );
    }
}
