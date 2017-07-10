float4x4 worldToCameraMatrix;
float4x4 projMatrix;
Texture2D txDiffuse;

static const int MAX_NUM_SAMPLE_POINTS = 64;
float widthToHeight;
int numSamplePoints;
float2 samplePoints[MAX_NUM_SAMPLE_POINTS];
float intensity;
float size;
float glow;
float offset;
float threshold;

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
    output.texCoord = input.texCoord;

    return output;
}

float4 PS( PS_IN input ) : SV_Target
{
    float4 cTmp = float4(0, 0, 0, 0);
    float4 cAcc = float4(0, 0, 0, 0);
    float totalWeight = 0;
    float2 pos;
    float w;
    float b;

    for (int i = 0; i < numSamplePoints && i < MAX_NUM_SAMPLE_POINTS; ++i)
    {
        pos = 0.01*size*samplePoints[i];
        pos.y *= widthToHeight;
        cTmp = txDiffuse.Sample(samLinear, input.texCoord + pos);
      
        w = 1.0f;
        b = length(cTmp.rgb);
        if (b > threshold)
        {
          w = pow(b, intensity);;
        }
        cAcc += cTmp*w;
        totalWeight += w;
    }
    float4 c = cAcc/totalWeight;
    c.rgb = float3(offset, offset, offset) + c.rgb*glow;
    c.a = 1.0;

    return c;
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
