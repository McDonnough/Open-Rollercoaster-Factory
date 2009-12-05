unit u_functions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  AString = array of String;

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
  *return The number of words
  *)
function WordCount(s: String): Integer;

implementation

uses
  Math;

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

end.

