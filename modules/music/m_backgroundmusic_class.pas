unit m_backgroundmusic_class;

interface

uses
  SysUtils, Classes, m_module, g_music;

type
  TModuleBackgroundMusicClass = class(TBasicModule)
    public
      procedure Advance; virtual abstract;
      procedure SetVolume(V: Single); virtual abstract;
    end;

implementation

end.