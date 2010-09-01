unit m_renderer_raytrace_sky;

interface

uses
  SysUtils, Classes, u_math, u_vectors, u_geometry, math;

function RTSkyColor(Ray: TRay): TVector4D;

implementation

uses
  g_park;

function RTSkyColor(Ray: TRay): TVector4D;
var
  Angle: Single;
  SunPosition, SunColor, SunAmbientColor: TVector3D;
  RW: TVector3D;
begin
  Result := Vector(1, 1, 1, 1);
  if Ray[1].Y <= 0 then
    exit;
  SunPosition := Vector(sin(2 * PI * Park.pSky.Time / 86400), -cos(2 * PI * Park.pSky.Time / 86400), cos(2 * PI * Park.pSky.Time / 86400));
  SunAmbientColor := Vector(0.05, 0.05, 0.05) + Vector(0.2, 0.25, 0.32) * Clamp(2 * SunPosition.Y, 0, 1) + Vector(0.00, 0.01, 0.05) * Clamp(-2 * SunPosition.Y, 0, 1);
  SunColor := Vector(1.0, 0.95, 0.88);
  SunColor := SunColor * Clamp(2.0 * SunPosition.Y, 0, 1);
  SunColor.Y := SunColor.Y * Clamp(0.6 + 1.0 * SunPosition.Y, 0, 1);
  SunColor.Z := SunColor.Z * Clamp(0.4 + 1.8 * SunPosition.Y, 0, 1);
  SunColor := SunColor + Vector(0.02, 0.04, 0.1) * Clamp(-2 * SunPosition.Y, 0, 1);
  Angle := Max(0.0, DotProduct(normalize(SunPosition), Ray[1]));
  RW := Mix(SunAmbientColor * SunAmbientColor,
                SunColor * SunColor * Power(VecLength(SunAmbientColor) / VecLength(SunColor), 2.0) * 2.0,
                Max(0.0, Power(Angle, 2.0)) * (1.0 - Power(DotProduct(Vector(0.0, 1.0, 0.0), Ray[1]), 0.5)))
                * 4.5 / (0.3 + 0.7 * (1.0 - Power(1.0 - DotProduct(Vector(0.0, 1.0, 0.0), Ray[1]), 4.0)));
  RW := RW + SunColor * 10.0 * Power(Angle, 2048.0);
  RW := RW + SunColor * 0.1 * Power(Angle, 20.0);
  Result := Vector(RW.X, RW.Y, RW.Z, 1.0);
end;

end.