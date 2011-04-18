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
      procedure Advance;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  Main;

procedure TSky.Advance;
begin
  Time := Time + FPSDisplay.MS / 50;
end;

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
  fTime := 86400 / 4 * 1.3;
end;

constructor TSky.Create;
begin
  writeln('Hint: Creating Sky object');
  LoadDefaults;
end;

destructor TSky.Free;
begin
  writeln('Hint: Deleting Sky object');
end;

end.