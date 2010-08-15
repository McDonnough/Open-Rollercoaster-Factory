unit u_functions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  AString = array of String;

  TDictionaryItem = record
    Name, Value: String;
    end;

  TDictionary = class
    private
      fItems: Array of TDictionaryItem;
      function getID(S: String): Integer;
      function getValue(S: String): String;
      function getItemStrings: AString;
      procedure setValue(S, T: String);
    public
      property ItemStrings: AString read getItemStrings;
      property Items[S: String]: String read getValue write setValue;
      property ItemID[S: String]: Integer read getID;
      procedure Assign(D: TDictionary);
    end;

(** Return part of a string
  *@param The string
  *@param first char to return
  *@param number of chars to return
  *)
function SubString(s: String; Start, Len: Integer): String;

(** Split a string into pieces with a char as delimited
  *@param the delimiter
  *@param string to split
  *@return Array with Strings
  *)
function Explode(d: Char; s: String): AString;

(** Find a char in a string
  *@param String to search in
  *@param Char to search
  *@param Offset where searching should be started
  *@return position of char
  *)
function StrPos(s: String; c: Char; Ofs: Integer = 1): Integer;

(** Count the words in a string
  *@param String to process
  *@return The number of words
  *)
function WordCount(s: String): Integer;

(** Get all files in one directory with subdirectories
  *@param Directory to search im
  *@param File mask
  *@param The list to write strings to
  *@param true = search in subdirs too
  *@param false = append to list
  *)
procedure GetFilesInDirectory(Directory: string; const Mask: string; List: TStringList; WithSubDirs, ClearList: Boolean);

(** Convert string into a number. Use default if the string is not a number.
  *@param String to convert
  *@param Default value
  *@return Number or default
  *)
function StrToIntWD(A: String; Default: Integer): Integer;
function StrToFloatWD(A: String; Default: Single): Single;

implementation

uses
  Math, m_varlist;

function TDictionary.getID(S: String): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to high(fItems) do
    if fItems[i].Name = S then
      exit(i);
end;

function TDictionary.getValue(S: String): String;
var
  i: Integer;
begin
  Result := '';
  i := ItemID[S];
  if i >= 0 then
    Result := fItems[i].Value;
end;

function TDictionary.getItemStrings: AString;
var
  i: Integer;
begin
  setLength(Result, length(fItems));
  for i := 0 to high(fItems) do
    Result[i] := fItems[i].Name;
end;

procedure TDictionary.setValue(S, T: String);
var
  i: Integer;
begin
  i := ItemID[S];
  if i < 0 then
    begin
    setLength(fItems, length(fItems) + 1);
    i := high(fItems);
    end;
  fItems[i].Name := S;
  fItems[i].Value := T;
end;

procedure TDictionary.Assign(D: TDictionary);
var
  i: Integer;
begin
  for i := 0 to high(D.fItems) do
    Items[D.fItems[i].Name] := D.fItems[i].Value;
end;



function SubString(s: String; Start, Len: Integer): String;
var
  i: integer;
begin
  setLength(Result, Len);
  if Start < 0 then
    Start := length(s) + Start;
  for i := 1 to Len do
    begin
    Result[i] := s[Start];
    inc(Start);
    if Start > length(s) then
      begin
      setLength(Result, i);
      exit;
      end;
    end;
end;

function Explode(d: Char; s: String): AString;
var
  i, DPos, OPos, LOcc: integer;
begin
  SetLength(Result, 0);
  if s = '' then
    exit;
  s := s + d;
  DPos := 0;
  repeat
    OPos := DPos + 1;
    DPos := StrPos(s, d, DPos + 1);
    setlength(Result, Length(Result) + 1);
    Result[high(Result)] := SubString(s, OPos, DPos - OPos);
  until
    DPos = Length(s);
end;

function StrPos(s: String; c: Char; Ofs: Integer = 1): Integer;
var
  i: integer;
begin
  for i := Ofs to length(s) do
    if s[i] = c then
      exit(i);
  result := -1;
end;

function WordCount(s: String): Integer;
var
  i: Integer;
  lastCharWasWhitespace: Boolean;
begin
  lastCharWasWhitespace := true;
  Result := 0;
  for i := 1 to length(s) do
    if s[i] in [' ', #9, #10, #13, #0] then
      lastCharWasWhitespace := true
    else
      if lastCharWasWhitespace then
        begin
        lastCharWasWhitespace := false;
        inc(Result);
        end;
end;

procedure GetFilesInDirectory(Directory: string; const Mask: string; List: TStringList; WithSubDirs, ClearList: Boolean);

  procedure ScanDir(Directory: string);
  var
    SR: TSearchRec;
  begin
    Directory := ModuleManager.ModPathes.Convert(Directory);
    if FindFirst(Directory + Mask, faAnyFile and not faDirectory, SR) = 0 then try
      repeat
        List.Add(Directory + SR.Name)
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;

    if WithSubDirs then begin
      if FindFirst(Directory + '*', faAnyFile, SR) = 0 then try
        repeat
          if ((SR.attr and faDirectory) = faDirectory) and
            (SR.Name <> '.') and (SR.Name <> '..') then
            ScanDir(Directory + SR.Name + '/');
        until FindNext(SR) <> 0;
      finally
        FindClose(SR);
      end;
    end;
  end;

begin
  Directory := ModuleManager.ModPathes.ConvertToUnix(Directory);
  List.BeginUpdate;
  try
    if ClearList then
      List.Clear;
    if Directory = '' then
      exit;
    if Directory[Length(Directory)] <> '/' then
      Directory := Directory + '/';
    ScanDir(Directory);
  finally
    List.EndUpdate;
  end;
end;

function StrToIntWD(A: String; Default: Integer): Integer;
begin
  try
    Result := StrToInt(A);
  except
    Result := Default;
  end;
end;

function StrToFloatWD(A: String; Default: Single): Single;
begin
  try
    Result := StrToFloat(A);
  except
    Result := Default;
  end;
end;

end.

