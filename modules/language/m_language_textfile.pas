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
  fLang := Language;
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
  i, j, k, c, m, n, sa, se: integer;
  mode: Boolean;
  a, e, tmp: String;
  CurrString1, CurrString2, Parameters: AString;
  function IsNoLetter(c: Char): Boolean;
  const
    a: String = ' .:-_,;#''*/-+/!"§%&/()=?[]{}\/¯^<>|@';
  var
    i: Integer;
  begin
    for i := 1 to length(a) do
      if a[i] = c then
        exit(true);
    Result := false;
  end;
begin
  Result := Source;
//   Exit;
  if fLang = 'en' then
    begin
    Result := '';
    for i := 1 to length(Source) do
      if Source[i] <> '$' then
        Result := Result + Source[i];
    end;
  CurrString1 := Explode(' ', Source);
  if length(CurrString1) = 0 then
    exit;
  sa := 0;
  a := ' ';
  while IsNoLetter(Source[sa + 1]) do
    begin
    a := a + Source[sa + 1];
    inc(sa);
    end;
  se := 0;
  e := ' ';
  while IsNoLetter(Source[length(Source) - se]) do
    begin
    e := Source[length(Source) - se] + e;
    inc(se);
    end;
  mode := false;
  for i := 1 to Length(Source) do
    begin
    if Source[i] = '$' then
      begin
      Source[i] := ' ';
      mode := not mode;
      if mode then
        begin
        setLength(Parameters, length(Parameters) + 1);
        Parameters[high(Parameters)] := '';
        end;
      end
    else if mode then
      begin
      Parameters[high(Parameters)] := Parameters[high(Parameters)] + Source[i];
      Source[i] := ' ';
      end;
    end;
  CurrString1 := Explode(' ', SubString(Source, sa + 1, Length(source) - se - sa));
  m := 9;
  n := -1;
  for i := 0 to high(fStrings) do
    begin
    CurrString2 := Explode(' ', fStrings[i].Key);
    c := 0;
    for j := 0 to high(CurrString1) do
      for k := 0 to high(CurrString2) do
        if Lowercase(CurrString1[j]) = Lowercase(CurrString2[k]) then
          inc(c, 10);
    if c = 10 * length(CurrString1) then
      inc(c, 50);
    if length(CurrString2) = length(CurrString1) then
      inc(c, 5);
    if c > m then
      begin
      n := i;
      m := c;
      end;
    end;
  if n > -1 then
    begin
    Result := '';
    tmp := fStrings[n].Value;
    mode := false;
    for i := 1 to Length(tmp) do
      begin
      if Mode then
        begin
        if (ord(tmp[i]) >= ord('0')) and (ord(tmp[i]) <= ord('9')) and (ord(tmp[i]) - ord(tmp[i]) <= high(Parameters)) then
          Result := Result + Parameters[ord(tmp[i]) - ord('0')];
        Mode := false;
        end
      else if tmp[i] = '$' then
        Mode := true
      else
        Result := Result + tmp[i];
      end;
    Result := a + Result + e;
    end;
  // TODO: Translate substrings by relevance
end;

end.