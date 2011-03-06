unit m_language_textfile;

interface

uses
  SysUtils, Classes, m_language_class;

type
  TLanguageString = record
    Key, Value: String;
  end;

  ALanguageString = array of TLanguageString;

  TModuleLanguageTextfile = class(TModuleLanguageClass)
    protected
      fLang: String;
      fStrings: ALanguageString;
    public
      constructor Create;
      procedure CheckModConf;
      function ChangeLanguage(Language: String): Boolean;
      function GetLanguage: String;
      function Translate(Source: String): String;
    end;

implementation

uses
  u_functions, m_varlist;

constructor TModuleLanguageTextfile.Create;
begin
  fModName := 'LanguageTextfile';
  fModType := 'Language';

  fLang := 'en';

  CheckModConf;

  fLang := GetConfVal('lang');

  ChangeLanguage(fLang);
end;

procedure TModuleLanguageTextfile.CheckModConf;
begin
  if GetConfVal('used') <> '1' then
    begin
    SetConfVal('used', '1');
    SetConfVal('lang', 'en');
    end;
end;

function TModuleLanguageTextfile.ChangeLanguage(Language: String): Boolean;
var
  FileName: String;
  i: Integer;
  CurrString: AString;
begin
  if fLang <> 'en' then
    begin
    FileName := '';
    if FileExists(ModuleManager.ModPathes.DataPath + 'langtextfile/' + fLang + '.lang') then
      FileName := ModuleManager.ModPathes.DataPath + 'langtextfile/' + fLang + '.lang'
    else if FileExists(ModuleManager.ModPathes.PersonalDataPath + 'langtextfile/' + fLang + '.lang') then
      FileName := ModuleManager.ModPathes.PersonalDataPath + 'langtextfile/' + fLang + '.lang';
    if FileName = '' then
      begin
      ModuleManager.ModLog.AddWarning('Language file for ' + fLang + ' not found');
      exit(false);
      end
    else
      with TStringList.Create do
        begin
        LoadFromFile(FileName);
        SetLength(fStrings, Count);
        for i := 0 to Count - 1 do
          begin
          CurrString := Explode('=', Strings[i]);
          fStrings[i].Key := CurrString[0];
          fStrings[i].Value := CurrString[1];
          end;
        Free;
        end;
    end;
  Result := True;
end;

function TModuleLanguageTextfile.GetLanguage: String;
begin
  exit(fLang);
end;

function TModuleLanguageTextfile.Translate(Source: String): String;
var
  i: integer;
begin
  Result := Source;
  Exit;
  if fLang = 'en' then
    exit;
  for i := 0 to high(fStrings) do
    if Lowercase(fStrings[i].Key) = Lowercase(Source) then
      exit(fStrings[i].Value);
  // TODO: Translate substrings by relevance
end;

end.