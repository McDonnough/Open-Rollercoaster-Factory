unit g_sky;

interface

uses
  SysUtils, Classes, u_vectors, m_texmng_class, dglOpenGL, g_loader_ocf, u_dom;

type
  TSky = class
    protected
      fTime: Single;
      procedure SetTime(T: Single);
    public
      property Time: Single read fTime write setTime;
      procedure LoadDefaults;
      constructor Create;
      destructor Free;
    end;

implementation

procedure TSky.SetTime(T: Single);
begin
  if T > 86400 then
    T := T - 86400
  else if T < 0 then
    T := T + 86400;
  fTime := T;
end;

procedure TSky.LoadDefaults;
begin
  fTime := 86400 / 4 * 1.5;
end;

constructor TSky.Create;
begin
  LoadDefaults;
end;

destructor TSky.Free;
begin
end;

end.