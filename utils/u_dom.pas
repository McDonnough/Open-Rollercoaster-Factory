unit u_dom;

interface

uses
  SysUtils, Classes;

type
  TDOMString = AnsiString;

  TDOMImplementation = class
    public
      function hasFeature(Name, Version: TDOMString): Boolean;
    end;

  TDOMDocument = class;
  TDOMNode = class;

  TDOMNodeList = Array of TDOMNode;

  TDOMNamedNodeMap = class
    private
      fItems: Array of TDOMNode;
    public
      function GetNamedItem(Name: TDOMString): TDOMNode;
      function SetNamedItem(Item: TDOMNode): TDOMNode;
      function RemoveNamedItem(Name: TDOMString): TDOMNode;
      function Item(Index: QWord): TDOMNode;
      function GetLength: QWord;
    end;

  TDOMNode = class
    private
      fNodeName: TDOMString;
      fNodeType: Word;
      fParentNode: TDOMNode;
      fChildNodes: TDOMNodeList;
      fAttributes: TDOMNamedNodeMap;
      fOwnerDocument: TDOMDocument;
      function _GetChildID(Child: TDOMNode): Integer;
    public
      NodeValue: TDOMString;
      property NodeName: TDOMString read fNodeName;
      property NodeType: Word read fNodeType;
      property ParentNode: TDOMNode read fParentNode;
      property ChildNodes: TDOMNodeList read fChildNodes;
      property Attributes: TDOMNamedNodeMap read fAttributes;
      property OwnerDocument: TDOMDocument read fOwnerDocument;
      function FirstChild: TDOMNode;
      function LastChild: TDOMNode;
      function PreviousSibling: TDOMNode;
      function NextSibling: TDOMNode;
      function InsertBefore(newChild, refChild: TDOMNode): TDOMNode;
      function ReplaceChild(newChild, oldChild: TDOMNode): TDOMNode;
      function RemoveChild(oldChild: TDOMNode): TDOMNode;
      function AppendChild(newChild: TDOMNode): TDOMNode;
      function HasChildNodes: Boolean;
      function CloneNode(Deep: Boolean): TDOMNode;
      destructor Free;
    end;

  TDOMCharacterData = class(TDOMNode)
    public
      property Data: TDOMString read NodeValue write NodeValue;
      function GetLength: QWord;
      function SubstringData(Offset, Count: QWord): TDOMString;
      procedure AppendData(Arg: TDOMString);
      procedure InsertData(Offset: QWord; Arg: TDOMString);
      procedure DeleteData(Offset, Count: QWord);
      procedure ReplaceData(Offset, Count: QWord; Arg: TDOMString);
    end;

  TDOMText = class(TDOMCharacterData)
    public
      function SplitText(Offset: QWord): TDOMText;
    end;

  TDOMComment = class(TDOMCharacterData);

  TDOMCDataSection = class(TDOMCharacterData);

  TDOMAttr = class(TDOMNode)
    protected
      fSpecified: Boolean;
    public
      property Value: TDOMString read NodeValue write NodeValue;
      property Name: TDOMString read fNodeName;
      property Specified: Boolean read fSpecified;
    end;

  TDOMElement = class(TDOMNode)
    public
      property TagName: TDOMString read fNodeName;
      function GetAttribute(Name: TDOMString): TDOMString;
      procedure SetAttribute(Name, Value: TDOMString);
      procedure RemoveAttribute(Name: TDOMString);
      function GetAttributeNode(Name: TDOMString): TDOMAttr;
      function SetAttributeNode(NewAttr: TDOMAttr): TDOMAttr;
      function RemoveAttributeNode(OldAttr: TDOMAttr): TDOMAttr;
      function GetElementsByTagName(Name: TDOMString): TDOMNodeList;
      procedure Normalize;
    end;

  TDOMDocumentFragment = class(TDOMNode);

  TDOMDocument = class(TDOMNode)
    private
      fDOMImplementation: TDOMImplementation;
      fItems: TDOMNodeList;
      procedure _AppendItem(Item: TDOMNode);
    public
      property DomImplementation: TDOMImplementation read fDOMImplementation;
      function CreateElement(TagName: TDOMString): TDOMElement;
      function CreateDocumentFragment: TDOMDocumentFragment;
      function CreateTextNode(Data: TDOMString): TDOMText;
      function CreateComment(Data: TDOMString): TDOMComment;
      function CreateCDATASection(Data: TDOMString): TDOMCDataSection;
      function CreateAttribute(Name: TDOMString): TDOMAttr;
      function GetElementsByTagName(TagName: TDOMString): TDOMNodeList;
      destructor Free;
    end;

procedure DOMException(Code: Word);

const
  DOM_INDEX_SIZE_ERR              = 1;
  DOM_DOMSTRING_SIZE_ERR          = 2;
  DOM_HIERARCHY_REQUEST_ERR       = 3;
  DOM_WRONG_DOCUMENT_ERR          = 4;
  DOM_INVALID_CHARACTER_ERR       = 5;
  DOM_NO_DATA_ALLOWED_ERR         = 6;
  DOM_NO_MODIFICATION_ALLOWED_ERR = 7;
  DOM_NOT_FOUND_ERR               = 8;
  DOM_NOT_SUPPORTED_ERR           = 9;
  DOM_INUSE_ATTRIBUTE_ERR         = 10;

  DOM_ELEMENT_NODE                = 1;
  DOM_ATTRIBUTE_NODE              = 2;
  DOM_TEXT_NODE                   = 3;
  DOM_CDATA_SECTION_NODE          = 4;
  DOM_ENTITY_REFERENCE_NODE       = 5;
  DOM_ENTITY_NODE                 = 6;
  DOM_PROCESSING_INSTRUCTION_NODE = 7;
  DOM_COMMENT_NODE                = 8;
  DOM_DOCUMENT_NODE               = 9;
  DOM_DOCUMENT_TYPE_NODE          = 10;
  DOM_DOCUMENT_FRAGMENT_NODE      = 11;
  DOM_NOTATION_NODE               = 12;

implementation

procedure DOMException(Code: Word);
begin
  writeln(Code);
end;

/// TDOMImplementation

function TDOMImplementation.hasFeature(Name, Version: TDOMString): Boolean;
begin
  Result := Version = '1.0';
end;

/// TDOMNamedNodeMap

function TDOMNamedNodeMap.GetNamedItem(Name: TDOMString): TDOMNode;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to high(fItems) do
    if fItems[i].NodeName = Name then
      Exit(fItems[i]);
end;

function TDOMNamedNodeMap.SetNamedItem(Item: TDOMNode): TDOMNode;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to high(fItems) do
    if fItems[i].NodeName = Item.NodeName then
      begin
      Result := fItems[i];
      fItems[i] := Item;
      Exit;
      end;
  SetLength(fItems, length(fItems) + 1);
  fItems[high(fItems)] := Item;
end;

function TDOMNamedNodeMap.RemoveNamedItem(Name: TDOMString): TDOMNode;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to high(fItems) do
    if fItems[i].NodeName = Name then
      begin
      Result := fItems[i];
      fItems[i] := fItems[high(fItems)];
      setLength(fItems, length(fItems) - 1);
      end;
end;

function TDOMNamedNodeMap.Item(Index: QWord): TDOMNode;
begin
  Result := nil;
  if Index <= high(fItems) then
    Result := fItems[Index];
end;

function TDOMNamedNodeMap.GetLength: QWord;
begin
  Result := Length(fItems);
end;

/// TDOMNode

function TDOMNode._GetChildID(Child: TDOMNode): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to high(fChildNodes) do
    if fChildNodes[i] = Child then
      exit(i);
end;

function TDOMNode.FirstChild: TDOMNode;
begin
  Result := nil;
  if HasChildNodes then
    Result := fChildNodes[0];
end;

function TDOMNode.LastChild: TDOMNode;
begin
  Result := nil;
  if HasChildNodes then
    Result := fChildNodes[high(fChildNodes)];
end;

function TDOMNode.PreviousSibling: TDOMNode;
var
  id: Integer;
begin
  Result := nil;
  if fParentNode = nil then exit;
  id := fParentNode._GetChildID(self);
  if id > 0 then
    Result := fParentNode.ChildNodes[id - 1];
end;

function TDOMNode.NextSibling: TDOMNode;
var
  id: Integer;
begin
  Result := nil;
  if fParentNode = nil then exit;
  id := fParentNode._GetChildID(self);
  if (id < high(fParentNode.ChildNodes)) and (id > -1) then
     Result := fParentNode.ChildNodes[id + 1];
end;

function TDOMNode.InsertBefore(newChild, refChild: TDOMNode): TDOMNode;
var
  i, id: Integer;
begin
  Result := newChild;
  RemoveChild(newChild);
  newChild.fParentNode := self;
  id := _GetChildID(refChild);
  if id = -1 then
    AppendChild(newChild)
  else
    begin
    setLength(fChildNodes, length(fChildNodes) + 1);
    for i := high(fChildNodes) downto id + 1 do
      fChildNodes[i] := fChildNodes[i - 1];
    fChildNodes[id] := newChild;
    end;
end;

function TDOMNode.ReplaceChild(newChild, oldChild: TDOMNode): TDOMNode;
var
  id: Integer;
begin
  Result := oldChild;
  RemoveChild(newChild);
  id := _GetChildID(oldChild);
  if id = -1 then
    exit;
  fChildNodes[id] := newChild;
  newChild.fParentNode := self;
end;

function TDOMNode.RemoveChild(oldChild: TDOMNode): TDOMNode;
var
  id, i: Integer;
begin
  Result := oldChild;
  id := _GetChildID(OldChild);
  if id = -1 then
    exit;
  for i := id + 1 to high(fChildNodes) do
    fChildNodes[i - 1] := fChildNodes[i];
  setLength(fChildNodes, length(fChildNodes) - 1);
  oldChild.fParentNode := nil;
end;

function TDOMNode.AppendChild(newChild: TDOMNode): TDOMNode;
begin
  Result := newChild;
  RemoveChild(newChild);
  setLength(fChildNodes, length(fChildNodes) + 1);
  fChildNodes[high(fChildNodes)] := newChild;
  newChild.fParentNode := self;
end;

function TDOMNode.HasChildNodes: Boolean;
begin
  Result := Length(fChildNodes) > 0;
end;

function TDOMNode.CloneNode(Deep: Boolean): TDOMNode;
var
  i: Integer;
begin
  Result := TDOMNode.Create;
  Result.fNodeName := fNodeName;
  Result.fNodeType := fNodeType;
  Result.fOwnerDocument := fOwnerDocument;
  Result.NodeValue := NodeValue;
  Result.fAttributes := TDOMNamedNodeMap.Create;
  if fNodeType = DOM_ELEMENT_NODE then
    for i := 0 to fAttributes.GetLength - 1 do
      TDOMElement(Result).setAttribute(fAttributes.Item(i).NodeName, TDOMElement(Self).getAttribute(fAttributes.Item(i).NodeName));
  if Deep then
    Result.AppendChild(fChildNodes[i].CloneNode(True));
  fOwnerDocument._AppendItem(Result);
end;

destructor TDOMNode.Free;
begin
  fAttributes.Free;
end;

/// TDOMCharacterData

function TDOMCharacterData.GetLength: QWord;
begin
  Result := Length(Data);
end;

function TDOMCharacterData.SubstringData(Offset, Count: QWord): TDOMString;
var
  i: Integer;
begin
  Result := '';
  for i := Offset + 1 to Offset + Count do
    if i < length(Data) then
      Result += Data[i];
end;

procedure TDOMCharacterData.AppendData(Arg: TDOMString);
begin
  Data := Data + Arg;
end;

procedure TDOMCharacterData.InsertData(Offset: QWord; Arg: TDOMString);
begin
  Data := SubstringData(0, Offset) + Arg + SubstringData(Offset, GetLength - Offset);
end;

procedure TDOMCharacterData.deleteData(Offset, Count: QWord);
begin
  Data := SubstringData(0, Offset) + SubstringData(Offset + Count, GetLength - Offset - Count);
end;

procedure TDOMCharacterData.ReplaceData(Offset, Count: QWord; Arg: TDOMString);
begin
  Data := SubstringData(0, Offset) + Arg + SubstringData(Offset + Count, GetLength - Offset - Count);
end;


/// TDOMText

function TDOMText.SplitText(Offset: QWord): TDOMText;
begin
  Result := fOwnerDocument.CreateTextNode(SubstringData(Offset, GetLength - Offset));
  Data := SubstringData(0, Offset);
  if fParentNode <> nil then
    if NextSibling = nil then
      fParentNode.AppendChild(Result)
    else
      fParentNode.InsertBefore(NextSibling, self);
end;

/// TDOMElement

function TDOMElement.GetAttribute(Name: TDOMString): TDOMString;
var
  id: TDOMAttr;
begin
  Result := '';
  id := TDOMAttr(fAttributes.GetNamedItem(Name));
  if id <> nil then
    Result := id.NodeValue;
end;

procedure TDOMElement.SetAttribute(Name, Value: TDOMString);
var
  id: TDOMAttr;
begin
  id := fOwnerDocument.CreateAttribute(Name);
  id.Value := Value;
  fAttributes.SetNamedItem(id);
end;

procedure TDOMElement.RemoveAttribute(Name: TDOMString);
begin
  fAttributes.RemoveNamedItem(Name);
end;

function TDOMElement.GetAttributeNode(Name: TDOMString): TDOMAttr;
begin
  Result := TDOMAttr(fAttributes.GetNamedItem(Name));
end;

function TDOMElement.SetAttributeNode(NewAttr: TDOMAttr): TDOMAttr;
begin
  Result := TDOMAttr(fAttributes.SetNamedItem(NewAttr));
end;

function TDOMElement.RemoveAttributeNode(OldAttr: TDOMAttr): TDOMAttr;
begin
  Result := TDOMAttr(fAttributes.RemoveNamedItem(OldAttr.Name));
end;

function TDOMElement.GetElementsByTagName(Name: TDOMString): TDOMNodeList;
var
  tmpList: TDOMNodeList;
  i, j: integer;
begin
  for i := 0 to high(fChildNodes) do
    if ChildNodes[i].NodeType = DOM_ELEMENT_NODE then
      if TDOMElement(ChildNodes[i]).TagName = Name then
        begin
        setLength(Result, length(Result) + 1);
        Result[high(Result)] := ChildNodes[i];
        tmpList := TDOMElement(ChildNodes[i]).GetElementsByTagName(Name);
        for j := 0 to high(tmpList) do
          begin
          setLength(Result, length(Result) + 1);
          Result[high(Result)] := tmpList[j];
          end;
        end;
end;

procedure TDOMElement.Normalize;
begin
end;

/// TDOMDocument

procedure TDOMDocument._AppendItem(Item: TDOMNode);
begin
  Setlength(fItems, length(fItems) + 1);
  fItems[high(fItems)] := Item;
end;

function TDOMDocument.CreateElement(TagName: TDOMString): TDOMElement;
begin
  Result := TDOMElement.Create;
  Result.fOwnerDocument := Self;
  Result.fParentNode := nil;
  Result.fNodeType := DOM_ELEMENT_NODE;
  Result.fNodeName := TagName;
  Result.fAttributes := TDOMNamedNodeMap.Create;
  _AppendItem(Result);
end;

function TDOMDocument.CreateDocumentFragment: TDOMDocumentFragment;
begin
  Result := TDOMDocumentFragment.Create;
  Result.fOwnerDocument := Self;
  Result.fParentNode := nil;
  Result.fNodeType := DOM_DOCUMENT_FRAGMENT_NODE;
  Result.fNodeName := '#document-fragment';
  _AppendItem(Result);
end;

function TDOMDocument.CreateTextNode(Data: TDOMString): TDOMText;
begin
  Result := TDOMText.Create;
  Result.fOwnerDocument := Self;
  Result.fParentNode := nil;
  Result.fNodeType := DOM_TEXT_NODE;
  Result.Data := Data;
  Result.fNodeName := '#text';
  _AppendItem(Result);
end;

function TDOMDocument.CreateComment(Data: TDOMString): TDOMComment;
begin
  Result := TDOMComment.Create;
  Result.fOwnerDocument := Self;
  Result.fParentNode := nil;
  Result.fNodeType := DOM_COMMENT_NODE;
  Result.fNodeName := '#comment';
  Result.NodeValue := Data;
  _AppendItem(Result);
end;

function TDOMDocument.CreateCDATASection(Data: TDOMString): TDOMCDataSection;
begin
  Result := TDOMCDataSection.Create;
  Result.fOwnerDocument := Self;
  Result.fParentNode := nil;
  Result.fNodeType := DOM_CDATA_SECTION_NODE;
  Result.fNodeName := '#cdata-section';
  Result.NodeValue := Data;
  _AppendItem(Result);
end;

function TDOMDocument.CreateAttribute(Name: TDOMString): TDOMAttr;
begin
  Result := TDOMAttr.Create;
  Result.fOwnerDocument := Self;
  Result.fParentNode := nil;
  Result.fNodeType := DOM_ATTRIBUTE_NODE;
  Result.fNodeName := Name;
  _AppendItem(Result);
end;

function TDOMDocument.GetElementsByTagName(TagName: TDOMString): TDOMNodeList;
var
  tmpList: TDOMNodeList;
  i, j: integer;
begin
  for i := 0 to high(fChildNodes) do
    if ChildNodes[i].NodeType = DOM_ELEMENT_NODE then
      if TDOMElement(ChildNodes[i]).TagName = TagName then
        begin
        setLength(Result, length(Result) + 1);
        Result[high(Result)] := ChildNodes[i];
        tmpList := TDOMElement(ChildNodes[i]).GetElementsByTagName(TagName);
        for j := 0 to high(tmpList) do
          begin
          setLength(Result, length(Result) + 1);
          Result[high(Result)] := tmpList[j];
          end;
        end;
end;

destructor TDOMDocument.Free;
var
  i: Integer;
begin
  for i := 0 to high(fItems) do
    fItems[i].Free;
end;

end.