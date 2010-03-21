unit u_xml;

interface

uses
  SysUtils, Classes, u_dom;

function LoadXMLFile(FName: String): TDOMDocument;
procedure WriteXMLFile(fDocument: TDOMDocument; FName: String);

implementation

uses
  u_functions;

function LoadXMLFile(FName: String): TDOMDocument;
var
  Source: String;


  function IsWhitespace(C: Char): Boolean;
  begin
    Result := C in [' ', #10, #13, #9];
  end;
var
  i: Integer;
  mode: Integer;
  tmpString: StrinG;
  SelfClose: Boolean;
  ElementStack: array of TDOMNode;
  LastAttribute: String;
  Document: TDOMDocument;

  procedure AddTextNode;
  begin
    if (tmpString <> '') and (length(ElementStack) > 0) then
      ElementStack[high(ElementStack)].AppendChild(Document.CreateTextNode(tmpString));
  end;

  procedure CloseTag;
  begin
    if length(ElementStack) > 0 then
      setLength(ElementStack, length(ElementStack) - 1);
  end;

  procedure OpenTag;
  var
    a: TDOMNode;
  begin
    a := Document.CreateElement(tmpString);
    ElementStack[high(ElementStack)].AppendChild(a);
    setLength(ElementStack, length(ElementStack) + 1);
    ElementStack[high(ElementStack)] := a;
  end;

  procedure AddAttribute;
  begin
    LastAttribute := tmpString;
    TDOMElement(ElementStack[high(ElementStack)]).SetAttribute(tmpString, '');
  end;

  procedure SetAttributeValue;
  begin
    TDOMElement(ElementStack[high(ElementStack)]).SetAttribute(LastAttribute, tmpString);
  end;
const
  M_NORMAL = 0;
  M_TAGNAME = 1;
  M_ATTRIB_NAME = 2;
  M_ATTRIB_VALUE = 3;
  M_DOC_INFO = 4;
begin
  Document := TDOMDocument.Create;
  Result := Document;
  if not FileExists(FName) then
    exit;
  setLength(ElementStack, 1);
  ElementStack[0] := Result;
  tmpString := '';
  mode := M_NORMAL;
  with TFileStream.Create(FName, fmOpenRead) do
    begin
    SetLength(Source, Size);
    Read(Source[1], Size);
    Free;
    end;
  i := 1;
  SelfClose := false;
  for i := 1 to length(source) do
    begin
    case Mode of
      M_NORMAL:
        begin
        if IsWhitespace(Source[i]) then
          continue
        else if Source[i] = '<' then
          begin
          addTextNode;
          if i < length(Source) then
            begin
            if (Source[i + 1] <> '?') then
              Mode := M_TAGNAME
            else
              Mode := M_DOC_INFO;
            end;
          tmpString := '';
          end
        else
          tmpString := tmpString + Source[i];
        end;
      M_TAGNAME:
        begin
        SelfClose := false;
        if Source[i] = '>' then
          begin
          Mode := M_NORMAL;
          if tmpString[1] = '/' then
            CloseTag
          else
            OpenTag;
          tmpString := '';
          end
        else if isWhitespace(Source[i]) then
          if tmpString = '' then
            continue
          else
            begin
            OpenTag;
            tmpString := '';
            Mode := M_ATTRIB_NAME;
            end
        else
          tmpString := tmpString + Source[i];
        end;
      M_ATTRIB_NAME:
        begin
        if Source[i] = '/' then
          SelfClose := true
        else if Source[i] = '>' then
          begin
          if SelfClose then
            CloseTag;
          Mode := M_NORMAL;
          tmpString := '';
          end
        else if Source[i] = '=' then
          begin
          Mode := M_ATTRIB_VALUE;
          AddAttribute;
          tmpString := '';
          end
        else
          tmpString := tmpString + Source[i];
        end;
      M_ATTRIB_VALUE:
        begin
        if ((Source[i] = '"') or (IsWhitespace(Source[i]))) and (tmpString = '') then
          continue;
        if Source[i] = '"' then
          begin
          SetAttributeValue;
          tmpString := '';
          Mode := M_ATTRIB_NAME;
          end
        else
          tmpString := tmpString + Source[i];
        end;
      M_DOC_INFO:
        if Source[i] = '>' then
          Mode := M_NORMAL;
      end;
    end;
end;

procedure WriteXMLFile(fDocument: TDOMDocument; FName: String);
var
  s: String;
  a: TStringList;
  function getAttributes(f: TDOMNode): String;
  var
    i: Integer;
  begin
    Result := '';
    for i := 0 to f.Attributes.GetLength - 1 do
      begin
      Result := Result + ' ' + f.Attributes.Item(i).NodeName + '="' + f.Attributes.Item(i).NodeValue + '"';
      end;
  end;

  procedure AddChildrenRecursively(f: TDOMNode);
  var
    r: TDOMNode;
  begin
    case f.NodeType of
      DOM_ELEMENT_NODE:
        begin
        a.add(s + '<' + f.NodeName + getAttributes(f) + '>');
        s := s + #9;
        r := f.FirstChild;
        while r <> nil do
          begin
          AddChildrenRecursively(r);
          r := r.NextSibling;
          end;
        setLength(s, length(s) - 1);
        a.add(s + '</' + f.NodeName + '>');
        end;
      DOM_TEXT_NODE:
        a.add(s + f.NodeValue);
      DOM_CDATA_SECTION_NODE:
        a.add(s + '<![CDATA[' + f.NodeValue + ']]>');
      end;
  end;
begin
  s := '';
  a := TStringList.Create;
  with a do
    begin
    Add('<?xml version="1.0" encoding="UTF-8"?>');
    if fDocument.FirstChild <> nil then
      AddChildrenRecursively(fDocument.FirstChild);
    SaveToFile(FName);
    Free;
    end;
end;

end.