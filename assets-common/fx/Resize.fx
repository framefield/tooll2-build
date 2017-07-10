float4x4 objectToWorldMatrix;
float4x4 worldToCameraMatrix;
float4x4 projMatrix;
Texture2D txDiffuse;
float4x4 textureMatrix;


SamplerState samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

struct VS_IN
{
    float4 pos : POSITION;
    float2 texCoord : TEXCOORD;
};

struct PS_IN
{
    float4 pos : SV_POSITION;
    float2 texCoord: TEXCOORD0;
};

PS_IN VS( VS_IN input )
{
    PS_IN output = (PS_IN)0;

    output.pos = mul(input.pos, worldToCameraMatrix);
    output.pos = mul(output.pos, projMatrix);
    output.texCoord = mul(float4(input.texCoord.xy, 0, 1), textureMatrix).xy;

    return output;
}

float4 PS( PS_IN input ) : SV_Target
{
    return txDiffuse.Sample(samLinear, input.texCoord);
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
