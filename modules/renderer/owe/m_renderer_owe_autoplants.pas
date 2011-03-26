unit m_renderer_owe_autoplants;

interface

uses
  SysUtils, Classes, DGLOpenGL, g_park, math, u_math, u_vectors, m_texmng_class, m_shdmng_class, m_renderer_owe_classes;

type
  TAutoplantGroup = class(TThread)
    private
      fWorking, fCanWork: Boolean;
      fCount: Integer;
      fVBO: TVBO;
      fMaterialID: Integer;
      fChanged: Array of Boolean;
      fPositions: Array of TVector3D;
      fTexture: TTexture;
      procedure Execute; override;
    public
      property Working: Boolean read fWorking write fCanWork;
      property Count: Integer read fCount;
      property Material: Integer read fMaterialID;
      property VBO: TVBO read fVBO;
      procedure Render;
      procedure Sync;
      procedure Update;
      constructor Create(MaterialID: Integer);
      destructor Free;
    end;

  TRAutoplants = class
    protected
      fAutoplantGroups: Array of TAutoplantGroup;
      fGeometryPassShader, fMaterialPassShader: TShader;
    public
      CurrentShader: TShader;
      property MaterialPassShader: TShader read fMaterialPassShader;
      property GeometryPassShader: TShader read fGeometryPassShader;
      procedure UpdateCollection(Event: String; Data, Result: Pointer);
      procedure Render;
      procedure Update;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  u_events, m_varlist;

procedure TAutoplantGroup.Execute;
var
  i: Integer;
  fAngle: Single;
begin
  fWorking := false;
  fCanWork := false;
  while not Terminated do
    begin
    if fCanWork then
      begin
      fCanWork := false;
      fWorking := true;
      for i := 0 to high(fPositions) do
        if (fPositions[i].Z = -1) or (VecLengthNoRoot(Vector2D(fPositions[i]) - Vector(ModuleManager.ModCamera.ActiveCamera.Position.X, ModuleManager.ModCamera.ActiveCamera.Position.Z)) > ModuleManager.ModRenderer.AutoplantDistance * ModuleManager.ModRenderer.AutoplantDistance) then
          begin
          fAngle := Random * 2 * 3.142;
          fPositions[i] := Vector(ModuleManager.ModCamera.ActiveCamera.Position.X + (0.9 + 0.1 * Random) * ModuleManager.ModRenderer.AutoplantDistance * sin(fAngle), ModuleManager.ModCamera.ActiveCamera.Position.Z + (0.9 + 0.1 * Random) * ModuleManager.ModRenderer.AutoplantDistance * cos(fAngle), 2 * 3.142 * Random);
          fChanged[i] := true;
          if (Park.pTerrain.TexMap[fPositions[i].X, fPositions[i].Y] <> fMaterialID) then
            fPositions[i].Z := -2;
          end;
      end;
    fWorking := false;
    sleep(10);
    end;
  writeln('Hint: Terminated autoplant renderer thread');
end;

procedure TAutoplantGroup.Render;
begin
  fTexture.Bind(0);
  fVBO.Bind;
  fVBO.Render;
  fVBO.Unbind;
end;

procedure TAutoplantGroup.Sync;
begin
  while fWorking do
    sleep(1);
end;

procedure TAutoplantGroup.Update;
var
  i: Integer;
begin
  fVBO.Bind;
  for i := 0 to fCount - 1 do
    if fChanged[i] then
      begin
      if (fPositions[i].z <> -2) and (Clamp(fPositions[i].x, 0, Park.pTerrain.SizeX / 5) = fPositions[i].x) and (Clamp(fPositions[i].y, 0, Park.pTerrain.SizeY / 5) = fPositions[i].y) then
        begin
        fVBO.Vertices[4 * i + 0] := Vector(fPositions[i].X, fPositions[i].Y, 0.0);
        fVBO.Vertices[4 * i + 1] := Vector(fPositions[i].X, fPositions[i].Y, 1.0);
        fVBO.Vertices[4 * i + 2] := Vector(fPositions[i].X + 1.6 * sin(fPositions[i].Z), fPositions[i].Y + 1.6 * cos(fPositions[i].Z), 1.0);
        fVBO.Vertices[4 * i + 3] := Vector(fPositions[i].X + 1.6 * sin(fPositions[i].Z), fPositions[i].Y + 1.6 * cos(fPositions[i].Z), 0.0);
        end
      else
        begin
        fVBO.Vertices[4 * i + 0] := Vector(0.0, 0.0, 0.0);
        fVBO.Vertices[4 * i + 1] := Vector(0.0, 0.0, 0.0);
        fVBO.Vertices[4 * i + 2] := Vector(0.0, 0.0, 0.0);
        fVBO.Vertices[4 * i + 3] := Vector(0.0, 0.0, 0.0);
        end;
      fChanged[i] := false;
      end;
  fVBO.Unbind;
end;

constructor TAutoplantGroup.Create(MaterialID: Integer);
var
  i: Integer;
begin
  inherited Create(false);

  fMaterialID := MaterialID;
  fCount := Round(ModuleManager.ModRenderer.AutoplantCount * Park.pTerrain.Collection.Materials[fMaterialID].AutoplantProperties.Factor);
  fTexture := Park.pTerrain.Collection.Materials[fMaterialID].AutoplantProperties.Texture;

  setLength(fChanged, fCount);
  setLength(fPositions, fCount);

  for i := 0 to fCount - 1 do
    begin
    fChanged[i] := true;
    fPositions[i] := Vector(0, 0, -1);
    end;

  fVBO := TVBO.Create(4 * fCount, GL_T2F_V3F, GL_QUADS);
  for i := 0 to fCount - 1 do
    begin
    fVBO.TexCoords[4 * i + 0] := Vector(0.0, 1.0);
    fVBO.TexCoords[4 * i + 1] := Vector(0.0, 0.0);
    fVBO.TexCoords[4 * i + 2] := Vector(1.0, 0.0);
    fVBO.TexCoords[4 * i + 3] := Vector(1.0, 1.0);
    fVBO.Vertices[4 * i + 0] := Vector(0.0, 0.0, 0.0);
    fVBO.Vertices[4 * i + 1] := Vector(0.0, 0.0, 0.0);
    fVBO.Vertices[4 * i + 2] := Vector(0.0, 0.0, 0.0);
    fVBO.Vertices[4 * i + 3] := Vector(0.0, 0.0, 0.0);
    end;
  fVBO.Unbind;
end;

destructor TAutoplantGroup.Free;
begin
  Terminate;
  fVBO.Free;
  Sync;
  sleep(100);
end;


procedure TRAutoplants.UpdateCollection(Event: String; Data, Result: Pointer);
var
  i: Integer;
begin
  for i := 0 to high(fAutoplantGroups) do
    fAutoplantGroups[i].Free;
  SetLength(fAutoplantGroups, 0);
  for i := 0 to high(Park.pTerrain.Collection.Materials) do
    if Park.pTerrain.Collection.Materials[i].AutoplantProperties.Available then
      begin
      SetLength(fAutoplantGroups, length(fAutoplantGroups) + 1);
      fAutoplantGroups[high(fAutoplantGroups)] := TAutoplantGroup.Create(i);
      end;
end;

procedure TRAutoplants.Render;
var
  i: Integer;
begin
  ModuleManager.ModRenderer.RTerrain.TerrainMap.Bind(1);
  ModuleManager.ModRenderer.RTerrain.TerrainMap.SetFilter(GL_LINEAR, GL_LINEAR);
  CurrentShader.Bind;
  CurrentShader.UniformF('BumpOffset', ModuleManager.ModRenderer.RWater.BumpOffset.X, ModuleManager.ModRenderer.RWater.BumpOffset.Y);
  CurrentShader.UniformF('TerrainSize', Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5);
  CurrentShader.UniformF('MaskOffset', Round(16 * Random) / 16, Round(16 * Random) / 16);
  if CurrentShader = MaterialPassShader then
    begin
    CurrentShader.UniformF('FogColor', ModuleManager.ModRenderer.FogColor);
    CurrentShader.UniformF('FogStrength', ModuleManager.ModRenderer.FogStrength);
    CurrentShader.UniformF('WaterHeight', ModuleManager.ModRenderer.RWater.CurrentHeight);
    CurrentShader.UniformF('WaterRefractionMode', ModuleManager.ModRenderer.FogRefractMode);
    end;
  for i := 0 to high(fAutoplantGroups) do
    fAutoplantGroups[i].Render;
  CurrentShader.Unbind;
end;

procedure TRAutoplants.Update;
var
  i: Integer;
begin
  for i := 0 to high(fAutoplantGroups) do
    if not fAutoplantGroups[i].Working then
      begin
      fAutoplantGroups[i].Update;
      fAutoplantGroups[i].Working := true;
      end;
end;

constructor TRAutoplants.Create;
begin
  writeln('Hint: Initializing autoplant renderer');

  CurrentShader := nil;

  fGeometryPassShader := TShader.Create('orcf-world-engine/scene/terrain/autoplants.vs', 'orcf-world-engine/scene/terrain/autoplantsGeometry.fs');
  fGeometryPassShader.UniformI('Texture', 0);
  fGeometryPassShader.UniformI('TerrainMap', 1);
  fGeometryPassShader.UniformI('TransparencyMask', 7);
  fGeometryPassShader.UniformF('MaskSize', ModuleManager.ModRenderer.TransparencyMask.Width, ModuleManager.ModRenderer.TransparencyMask.Height);
  fGeometryPassShader.UniformF('MaxDist', ModuleManager.ModRenderer.AutoplantDistance);

  fMaterialPassShader := TShader.Create('orcf-world-engine/scene/terrain/autoplants.vs', 'orcf-world-engine/scene/terrain/autoplantsMaterial.fs');
  fMaterialPassShader.UniformI('Texture', 0);
  fMaterialPassShader.UniformI('TerrainMap', 1);
  fMaterialPassShader.UniformI('LightTexture', 7);
  fMaterialPassShader.UniformF('MaxDist', ModuleManager.ModRenderer.AutoplantDistance);

  EventManager.AddCallback('TTerrain.ChangedCollection', @UpdateCollection);
end;

destructor TRAutoplants.Free;
var
  i: Integer;
begin
  EventManager.RemoveCallback(@UpdateCollection);

  for i := 0 to high(fAutoplantGroups) do
    fAutoplantGroups[i].Free;

  fGeometryPassShader.Free;
  fMaterialPassShader.Free;
end;

end.

