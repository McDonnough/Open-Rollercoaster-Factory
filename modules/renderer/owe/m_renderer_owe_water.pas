unit m_renderer_owe_water;

interface

uses
  SysUtils, Classes, m_renderer_owe_renderpass, m_renderer_owe_classes, u_arrays, m_shdmng_class, m_texmng_class, u_vectors, DGLOpenGL;

type
  TWaterLayer = class
    protected
      fHeight: Word;
      fRefractionPass, fReflectionPass: TRenderPass;
      fQuery: TOcclusionQuery;
      fVisible: Boolean;
    private
      fCount: Integer;
    public
      function Visible: Boolean;
      procedure CheckVisibility;
      procedure Render;
      procedure RenderBuffers;
      constructor Create;
      destructor Free;
    end;

  TRWater = class
    protected
      fWaterMap: TTable;
      fCheckShader, fRenderShader: TShader;
      fWaterLayers: Array of TWaterLayer;
    public
      property RenderShader: TShader read fRenderShader;
      property CheckShader: TShader read fCheckShader;
      procedure Update;
      procedure Check;
      procedure Render;
      procedure RenderBuffers;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist;

procedure TRWater.Update;
begin
end;

procedure TRWater.Check;
begin
end;

procedure TRWater.Render;
begin
end;

procedure TRWater.RenderBuffers;
begin
end;

constructor TRWater.Create;
begin
end;

destructor TRWater.Free;
begin
end;

function TWaterLayer.Visible: Boolean;
begin
  Result := fQuery.Result > 0;
end;

procedure TWaterLayer.CheckVisibility;
begin
  fQuery.StartCounter;

  fQuery.EndCounter;
end;

procedure TWaterLayer.Render;
begin
end;

procedure TWaterLayer.RenderBuffers;
begin
end;

constructor TWaterLayer.Create;
var
  ResX, ResY: Integer;
begin
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  fReflectionPass := TRenderPass.Create(Round(ResX * ModuleManager.ModRenderer.WaterReflectionBufferSamples), Round(ResY * ModuleManager.ModRenderer.WaterReflectionBufferSamples));
  fRefractionPass := TRenderPass.Create(Round(ResX * ModuleManager.ModRenderer.WaterReflectionBufferSamples), Round(ResY * ModuleManager.ModRenderer.WaterReflectionBufferSamples));
  fQuery := TOcclusionQuery.Create;
end;

destructor TWaterLayer.Free;
begin
  fQuery.Free;
  fRefractionPass.Free;
  fReflectionPass.Free;
end;

end.