unit u_xml;

interface

uses
  SysUtils, Classes, u_dom;

function LoadXMLFile(FName: String): TDOMDocument;
procedure WriteXMLFile(fDocument: TDOMDocument; FName: String);
function DOMFromXML(Source: String): TDOMDocument;
function XMLFromDOM(fDocument: TDOMDocument): String;

implementation

uses
  u_functions;

function LoadXMLFile(FName: String): TDOMDocument;
var
  Source: String;
begin
  if not FileExists(FName) then
    exit;
  with TFileStream.Create(FName, fmOpenRead) do
    begin
    SetLength(Source, Size);
    Read(Source[1], Size);
    Free;
    end;
  Result := DOMFromXML(Source);
end;

function DOMFromXML(Source: String): TDOMDocument;
var
  i, j: Integer;
  mode: Integer;
  tmpString: StrinG;
  SelfClose, HadCharacter: Boolean;
  ElementStack: array of TDOMNode;
  LastAttribute: String;
  Document: TDOMDocument;


  function IsWhitespace(C: Char): Boolean;
  begin
    Result := C in [' ', #10, #13, #9];
  end;

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
  setLength(ElementStack, 1);
  ElementStack[0] := Result;
  i := 1;
  SelfClose := false;
  tmpString := '';
  mode := M_NORMAL;
  for i := 1 to length(source) do
    begin
    if Mode <> M_NORMAL then
      HadCharacter := false;
    case Mode of
      M_NORMAL:
        begin
        if (IsWhitespace(Source[i])) and (tmpString = '') then
          continue;
        if Source[i] = '<' then
          begin
          for j := length(tmpString) downto 1 do
            begin
            if not IsWhitespace(tmpString[j]) then
              break;
            setLength(tmpString, length(tmpString) - 1);
            end;
          if length(tmpString) > 0 then
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
        if (IsWhitespace(Source[i])) then
          continue;
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
  a: String;
begin
  a := XMLFromDOM(fDocument);
  with TFileStream.Create(FName, fmOpenWrite or fmCreate) do
    begin
    Write(A[1], length(A));
    Free;
    end;
end;

function XMLFromDOM(fDocument: TDOMDocument): String;
var
  s: String;
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
        r := f.FirstChild;
        if (r = f.LastChild) and (r.NodeType = DOM_TEXT_NODE) then
          Result := Result + s + '<' + f.NodeName + getAttributes(f) + '>' + r.NodeValue + '</' + f.NodeName + '>' + #10
        else
          begin
          Result := Result + s + '<' + f.NodeName + getAttributes(f) + '>' + #10;
          s := s + #9;
          while r <> nil do
            begin
            AddChildrenRecursively(r);
            r := r.NextSibling;
            end;
          setLength(s, length(s) - 1);
          Result := Result + s + '</' + f.NodeName + '>' + #10;
          end;
        end;
      DOM_TEXT_NODE:
        Result := Result + s + f.NodeValue + #10;
      DOM_CDATA_SECTION_NODE:
        Result := Result + s + '<![CDATA[' + f.NodeValue + ']]>' + #10;
      end;
  end;
begin
  s := '';
  Result := Result + '<?xml version="1.0" encoding="UTF-8"?>' + #10;
  if fDocument.FirstChild <> nil then
    AddChildrenRecursively(fDocument.FirstChild);
end;

end.