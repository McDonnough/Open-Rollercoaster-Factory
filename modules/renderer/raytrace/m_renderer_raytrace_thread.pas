unit m_renderer_raytrace_thread;

interface

uses
  SysUtils, Classes, u_arrays, u_functions, u_geometry, u_vectors, u_math;

type
  TRendererRaytraceThread = class(TThread)
    protected
      fWorking, fCanWork: Boolean;
      procedure Execute; override;
      procedure DrawChunk(SX, SY: Integer);
      function GetColorAtPixel(i, j: Integer): DWord;
      function ColorFromRay(Ray: TRay): TVector4D;
    public
      ID: Integer;
      ChunkCount, ResX, ResY, Samples: Integer;
      ChunkMap, PixelMap: Pointer;
      property Working: Boolean read fWorking write fCanWork;
      constructor Create;
      procedure Unload;
      end;

implementation

uses
  m_varlist, m_renderer_raytrace_sky, math;

function TRendererRaytraceThread.ColorFromRay(Ray: TRay): TVector4D;
var
  i: Integer;
begin
  Result := Vector(0, 0, 0, 1);
  Result := RTSkyColor(Ray);
end;

function TRendererRaytraceThread.GetColorAtPixel(i, j: Integer): DWord;
var
  Ray: TRay;
  Color: TVector4D;
  a, b: Integer;
begin
  Color := Vector(0, 0, 0, 0);
  for a := 0 to Samples - 1 do
    for b := 0 to Samples - 1 do
      begin
      Ray[0] := ModuleManager.ModCamera.ActiveCamera.Position;
      Ray[1] := Vector(((-ResX + 2 * (i + a / Samples)) / ResX), ((-ResY + 2 * (j + b / Samples)) / ResX), 1);
      Ray[1] := Rotate(ModuleManager.ModCamera.ActiveCamera.Rotation.Z, Ray[1], Vector(0, 0, 1));
      Ray[1] := Rotate(ModuleManager.ModCamera.ActiveCamera.Rotation.X, Ray[1], Vector(1, 0, 0));
      Ray[1] := Rotate(ModuleManager.ModCamera.ActiveCamera.Rotation.Y, Ray[1], Vector(0, 1, 0));
      Ray[1] := normalize(Ray[1]);
      Color := Color + ColorFromRay(Ray);
      end;
  Color := Color / Samples / Samples;
  Result := Round(255 * Clamp(Color.X, 0, 1));
  Result := Result or (Round(255 * Clamp(Color.Y, 0, 1))) shl 8;
  Result := Result or (Round(255 * Clamp(Color.Z, 0, 1))) shl 16;
  Result := Result or $FF000000;
end;

procedure TRendererRaytraceThread.DrawChunk(SX, SY: Integer);
var
  i, j: Integer;
begin
  for i := SX to SX + 19 do
    for j := SY to SY + 19 do
      begin
      if (i mod 2 <> 0) or (j mod 2 <> 0) then continue;
      DWord(Pointer(PixelMap + SizeOf(Integer) * (ResX * j + i))^) := GetColorAtPixel(i, j);
      DWord(Pointer(PixelMap + SizeOf(Integer) * (ResX * j + i + 1))^) := DWord(Pointer(PixelMap + SizeOf(Integer) * (ResX * j + i))^);
      DWord(Pointer(PixelMap + SizeOf(Integer) * (ResX * (j + 1) + i + 1))^) := DWord(Pointer(PixelMap + SizeOf(Integer) * (ResX * j + i))^);
      DWord(Pointer(PixelMap + SizeOf(Integer) * (ResX * (j + 1) + i))^) := DWord(Pointer(PixelMap + SizeOf(Integer) * (ResX * j + i))^);
      end;
end;

procedure TRendererRaytraceThread.Execute;
var
  i, x, y: Integer;
begin
  fWorking := false;
  fCanWork := false;
  while not Terminated do
    begin
    try
      if fCanWork then
        begin
        fWorking := true;
        fCanWork := false;
        x := 0;
        y := 0;
        for i := 0 to ChunkCount - 1 do
          begin
          if Integer((ChunkMap + SizeOf(Integer) * i)^) = 0 then
            begin
            Integer((ChunkMap + SizeOf(Integer) * i)^) := 1;
            DrawChunk(x, y);
            end;
          inc(x, 20);
          if x >= ResX then
            begin
            inc(y, 20);
            x := 0;
            end;
          end;
        end
      else
        sleep(1);
      fWorking := false;
    except
      ModuleManager.ModLog.AddError('Exception in raytracer thread ' + IntToStr(ID));
    end;
    end;
  writeln('Hint: Terminated raytracer thread ', ID);
end;

constructor TRendererRaytraceThread.Create;
begin
  inherited Create(false);
end;

procedure TRendererRaytraceThread.Unload;
begin
end;

end.