unit DSE_List;

interface

uses
  SysUtils, Classes, vcl.Graphics, windows, DSE_misc;

type
  SE_List = class
  private
    fCapacity: integer;
    fCount: integer;
  protected
    fItemSize: integer;
    procedure SetCount(NewCount: integer); virtual;
    function AddItem(value: pointer): integer;
    procedure InsertItem(index: integer; value: pointer);
    function IndexOfItem(value: pointer): integer;
    function LowLevelGetItem(index: integer): pointer;
    procedure LowLevelSetItem(index: integer; value: pointer);
  public
    fData: pointer;
    constructor Create(); virtual;
    destructor Destroy; override;
    procedure Delete(index: integer); virtual;
    property Count: integer read fCount write SetCount;
    procedure Clear; virtual;
    procedure Assign(Source: SE_List); virtual;

    property data: pointer read fData write fData;
  end;

  SE_DoubleList = class(SE_List)
  private
    function GetItem(index: integer): double;
    procedure SetItem(index: integer; dValue: double);
  public
    function Add(dValue: double): integer;
    procedure Insert(index: integer; dValue: double);
    procedure Clear; override;
    function IndexOf(dValue: double): integer;
    property Items[idx: integer]: double read GetItem write SetItem; default;
    procedure Assign(Source: SE_List); override;
  end;

  SE_IntegerList = class(SE_List)
  private
    function GetItem(index: integer): integer;
    procedure SetItem(index: integer; iValue: integer);
  public
    function Add(iValue: integer): integer;
    procedure Insert(index: integer; iValue: integer);
    procedure Clear; override;
    function IndexOf(iValue: integer): integer;
    property Items[idx: integer]: integer read GetItem write SetItem; default;
    procedure Assign(Source: SE_List); override;
  end;

  SE_RecordList = class(SE_List)
  private
    function GetItem(index: integer): pointer;
    procedure SetItem(index: integer; rPtr: pointer);
  public
    function Add(rPtr: pointer): integer;
    procedure Insert(index: integer; rPtr: pointer);
    function IndexOf(rPtr: pointer): integer;
    property Items[idx: integer]: pointer read GetItem write SetItem; default;

    constructor CreateList(RecordSize: integer);
  end;

type
  TPointList = class(TList)
  private
    function GetPoints(n: integer): TPoint;
    procedure SetPoints(n: integer; const value: TPoint);
  protected
  public
    procedure Add(APoint: TPoint);
    procedure Clear; override;
    procedure Delete(n: integer);
    procedure Insert(index: integer; APoint: TPoint);
    property Points[n: integer]: TPoint read GetPoints write SetPoints;
  end;

type

  SE_Array = class(TPersistent)
  protected
    FRecordSize: integer;
    fCount: Longint;
    data: pointer;

    procedure SetCount(Records: Longint);
    function GetItem(index: integer ): pointer;
    procedure SetItem(index: integer; value: pointer);
  public
    constructor Create(Records: Longint; rSize: Cardinal);
    destructor Destroy; override;
    procedure Clear;
    procedure Fill(const value);
    property Items[idx: integer]: pointer read GetItem write SetItem; default;
    procedure Write(aRecord: Longint; const value);
    procedure Read(aRecord: Longint; var value);
    procedure Exchange(Record1, Record2: Longint);
    property Count: Longint read fCount write SetCount;
    property RecordSize: integer read FRecordSize;

  end;

type
  SE_Matrix = class(TPersistent)
  protected
    fx: integer;
    fy: integer;
    FRecordSize: integer;
    FCols: Cardinal;
    FRows: Cardinal;
    fCount: integer;
    data: pointer;
    RowSize: Longint;
    procedure SetRows(Rows: Cardinal);
    procedure SetCols(Cols: Cardinal);

  public
    constructor Create(Rows, Cols, rSize: Cardinal);
    destructor Destroy; override;

    procedure Clear;
    procedure Fill(const value);
    procedure Write(aRow, aCol: Cardinal; const value);
    procedure Read(aRow, aCol: Cardinal; var value);
    procedure WriteRow(aRow: Cardinal; const RowValue);
    procedure ReadRow(aRow: Cardinal; var RowValue);
    procedure ExchangeRows(aRow1, aRow2: Cardinal);
    property Rows: Cardinal read FRows write SetRows;
    property Cols: Cardinal read FCols write SetCols;
    property RecordSize: integer read FRecordSize;
    property X: integer read fx write fx;
    property Y: integer read fy write fy;

  end;

procedure FillStruc(var Dest; Count: Longint; const value; aRecordSize: Cardinal);

Type
  SE_ByteArray = class
  private
    fSize: integer;
    fBlockSize: integer;
    fBufferSize: integer;
    procedure SetSize(NewSize: integer);
  public
    data: pbytearray;
    constructor Create(aBlockSize: integer = 1024);
    destructor Destroy; override;
    procedure AddByte(aByte: byte);
    property Size: integer read fSize write SetSize;
    property BlockSize: integer read fBlockSize write fBlockSize;
    procedure Clear;
  end;

implementation

constructor SE_List.Create();
begin
  inherited Create;
  fData := nil;
  Clear;
end;

destructor SE_List.Destroy;
begin
  freemem(fData);
  inherited Destroy;
end;

procedure SE_List.Clear;
begin
  fCapacity := 0;
  fCount := 0;
  if assigned(fData) then
    freemem(fData);
  fData := nil;
end;

procedure SE_List.SetCount(NewCount: integer);
var
  tmpData: pointer;
begin
  if fCapacity < NewCount then
  begin
    fCapacity := imax(fCapacity * 2, NewCount);
    getmem(tmpData, fCapacity * fItemSize);
    if assigned(fData) then
    begin
      move(pbyte(fData)^, pbyte(tmpData)^, imin(fCount, NewCount) * fItemSize);
      freemem(fData);
    end;
    fData := tmpData;
  end;
  fCount := NewCount;
end;

procedure SE_List.Delete(index: integer);
var
  tmpData: pointer;
  i: integer;
  psrc, pdst: pbyte;
begin
  if (index >= 0) and (index < fCount) then
  begin
    getmem(tmpData, (fCount - 1) * fItemSize);
    psrc := fData;
    pdst := tmpData;
    for i := 0 to fCount - 1 do
    begin
      if i <> index then
      begin
        move(psrc^, pdst^, fItemSize);
        inc(pdst, fItemSize);
      end;
      inc(psrc, fItemSize);
    end;
    freemem(fData);
    fData := tmpData;
    dec(fCount);
    fCapacity := fCount;
  end;
end;

procedure SE_List.InsertItem(index: integer; value: pointer);
var
  tmpData: pointer;
  i: integer;
  Source, Dest: pbyte;
begin
  if index < fCount then
  begin
    inc(fCount);
    fCapacity := fCount;
    getmem(tmpData, fCount * fItemSize);
    Source := fData;
    Dest := tmpData;
    for i := 0 to fCount - 1 do
    begin
      if i <> index then
      begin
        move(Source^, Dest^, fItemSize);
        inc(Source, fItemSize);
      end
      else
        move(pbyte(value)^, Dest^, fItemSize);
      inc(Dest, fItemSize);
    end;
    freemem(fData);
    fData := tmpData;
  end
  else
    AddItem(value);
end;

function SE_List.IndexOfItem(value: pointer): integer;
var
  pb: pbyte;
begin
  pb := fData;
  for result := 0 to fCount - 1 do
  begin
    if CompareMem(pb, value, fItemSize) then
      exit;
    inc(pb, fItemSize);
  end;
  result := -1;
end;

function SE_List.LowLevelGetItem(index: integer): pointer;
begin
  result := pointer(uint64(fData) + index * fItemSize)

end;

procedure SE_List.LowLevelSetItem(index: integer; value: pointer);
begin
   // move(pbyte(value)^, pbyte(uint64(fData) + index * fItemSize)^, fItemSize);//GG
  asm
    mov eax,Self
    push esi
    push edi
    mov esi,Value
    mov ecx,SE_List([eax]).fItemSize
    mov edi,Index
    imul edi,ecx
    add edi,SE_List([eax]).fData
    mov eax,ecx
    shr ecx,2
    rep movsd
    mov ecx,eax
    and ecx,3
    rep movsb
    pop edi
    pop esi
  end;

end;

procedure SE_List.Assign(Source: SE_List);
begin
  if assigned(Source) then
  begin
    fCount := Source.fCount;
    fItemSize := Source.fItemSize;
    if assigned(fData) then
    begin
      freemem(fData);
      fData := nil;
    end;
    getmem(fData, fItemSize * fCount);
    move(pbyte(Source.fData)^, pbyte(fData)^, fItemSize * fCount);
  end;
end;

function SE_List.AddItem(value: pointer): integer;
begin
  result := fCount;
  SetCount(fCount + 1);
  move(pbyte(value)^, pbyte(uint64(fData) + result * fItemSize)^, fItemSize);
(*  asm
    mov eax,Self
    push esi
    push edi
    mov esi,Value
    mov ecx,SE_List([eax]).fItemSize
    mov edi,fCount
    imul edi,ecx
    add edi,SE_List([eax]).fData
    mov eax,ecx
    shr ecx,2
    rep movsd
    mov ecx,eax
    and ecx,3
    rep movsb
    pop edi
    pop esi
  end;
  result := fCount; *)

end;

procedure SE_DoubleList.Assign(Source: SE_List);
begin
  inherited;
end;

function SE_DoubleList.Add(dValue: double): integer;
begin
  result := AddItem(@dValue);
end;

procedure SE_DoubleList.Clear;
begin
  inherited;
  fItemSize := sizeof(double);
end;

function SE_DoubleList.GetItem(index: integer): double;
begin
  result := PDouble(LowLevelGetItem(index))^;
end;

procedure SE_DoubleList.SetItem(index: integer; dValue: double);
begin
  LowLevelSetItem(index, @dValue);
end;

procedure SE_DoubleList.Insert(index: integer; dValue: double);
begin
  InsertItem(index, @dValue);
end;

function SE_DoubleList.IndexOf(dValue: double): integer;
begin
  result := IndexOfItem(@dValue);
end;


procedure SE_IntegerList.Assign(Source: SE_List);
begin
  inherited;
end;

function SE_IntegerList.Add(iValue: integer): integer;
begin
  result := AddItem(@iValue);
end;

procedure SE_IntegerList.Clear;
begin
  inherited;
  fItemSize := sizeof(integer);
end;

function SE_IntegerList.GetItem(index: integer): integer;
begin
  result := PInteger(LowLevelGetItem(index))^;
end;

procedure SE_IntegerList.SetItem(index: integer; iValue: integer);
begin
  LowLevelSetItem(index, @iValue);
end;

procedure SE_IntegerList.Insert(index: integer; iValue: integer);
begin
  InsertItem(index, @iValue);
end;

function SE_IntegerList.IndexOf(iValue: integer): integer;
begin
  result := IndexOfItem(@iValue);
end;

constructor SE_RecordList.CreateList(RecordSize: integer);
begin
  inherited Create;
  fItemSize := RecordSize;
end;

function SE_RecordList.Add(rPtr: pointer): integer;
begin
  result := AddItem(rPtr);
end;

function SE_RecordList.GetItem(index: integer): pointer;
begin
  result := LowLevelGetItem(index);
end;

procedure SE_RecordList.SetItem(index: integer; rPtr: pointer);
begin
  LowLevelSetItem(index, rPtr);
end;

procedure SE_RecordList.Insert(index: integer; rPtr: pointer);
begin
  InsertItem(index, rPtr);
end;

function SE_RecordList.IndexOf(rPtr: pointer): integer;
begin
  result := IndexOfItem(rPtr);
end;

procedure TPointList.Add(APoint: TPoint);
var
  p: PPoint;
begin
  New(p);
  p^.X := APoint.X;
  p^.Y := APoint.Y;
  inherited Add(p);
end;

procedure TPointList.Clear;
begin
  while Count > 0 do
    Delete(0);
end;

procedure TPointList.Delete(n: integer);
var
  p: PPoint;
begin
  p := PPoint(Items[n]);
  Dispose(p);
  inherited Delete(n);
end;

function TPointList.GetPoints(n: integer): TPoint;
begin
  result := PPoint(Items[n])^;
end;

procedure TPointList.Insert(index: integer; APoint: TPoint);
var
  p: PPoint;
begin
  New(p);
  p^.X := APoint.X;
  p^.Y := APoint.Y;
  inherited Insert(Index, p);
end;

procedure TPointList.SetPoints(n: integer; const value: TPoint);
var
  p: PPoint;
begin
  p := PPoint(Items[n]);
  p^.X := value.X;
  p^.Y := value.Y;
end;

procedure SE_Array.Clear;
begin
  FillChar(data^, fCount * FRecordSize, 0);
end;


constructor SE_Array.Create(Records: Longint; rSize: Cardinal);
begin

  fCount := Records;
  FRecordSize := rSize;

  getmem(data, Records * Longint(rSize));
  Clear;
end;

destructor SE_Array.Destroy;
begin
  freemem(data, fCount * FRecordSize);
  inherited Destroy;
end;

procedure SE_Array.Exchange(Record1, Record2: Longint);
begin
  asm
    mov eax,Self
    push ebx
    push esi
    push edi

    mov esi,Record1
    mov edi,Record2
    mov ecx,SE_Array([eax]).FRecordSize
    mov edx,SE_Array([eax]).Data
    imul esi,ecx
    add esi,edx
    imul edi,ecx
    add edi,edx
    mov edx,ecx
    shr ecx,2
    jz @2

  @1: xchg esi,edi
    add esi,4
    add edi,4
    dec ecx
    jnz @1

  @2: mov ecx,edx
    and ecx,3
    jz @4

  @3: xchg esi,edi
    inc esi
    inc edi
    dec ecx
    jnz @3

  @4: pop edi
    pop esi
    pop ebx
  end;
end;

procedure SE_Array.Fill(const value);
begin
  FillStruc(data^, fCount, value, FRecordSize);
end;
function SE_Array.GetItem ( index: integer ):pointer;
begin
  result := pointer(uint64(Data) + index * fRecordSize) ;
end;
procedure SE_Array.SetItem ( index: integer; value: pointer);
begin
   // move(pbyte(value)^, pbyte(uint64(fData) + index * fItemSize)^, fItemSize);//GG
  asm
    mov eax,Self
    push esi
    push edi
    mov esi,Value
    mov ecx,SE_Array([eax]).fRecordSize
    mov edi,Index
    imul edi,ecx
    add edi,SE_Array([eax]).Data
    mov eax,ecx
    shr ecx,2
    rep movsd
    mov ecx,eax
    and ecx,3
    rep movsb
    pop edi
    pop esi
  end;

end;
procedure SE_Array.Read(aRecord: Longint; var value);
begin
  // move((PChar(Data)+aRecord*FRecordSize)^, Value, FRecordSize);
  // exit;
  asm
    mov eax,Self
    push esi
    push edi
    mov edi,Value
    mov ecx,SE_Array([eax]).FRecordSize
    mov esi,aRecord
    imul esi,ecx
    add esi,SE_Array([eax]).Data
    mov eax,ecx
    shr ecx,2
    rep movsd          // <-- copiai i byte all'indirizzo di Value
    mov ecx,eax
    and ecx,3
    rep movsb
    pop edi
    pop esi
  end;
end;

procedure SE_Array.SetCount(Records: Longint);
var
  OldSize, NewSize: Longint;
  OldFData: pointer;
begin

  NewSize := Records * FRecordSize;
  OldSize := fCount * FRecordSize;
  OldFData := data;

  getmem(data, NewSize);

  fCount := Records;

  if NewSize > OldSize then
  begin
    Clear;
    NewSize := OldSize;
  end;
  move(OldFData^, data^, NewSize);

  freemem(OldFData, OldSize);
end;

procedure SE_Array.Write(aRecord: Longint; const value);
begin
  // move(Value, (PChar(Data)+aRecord*FRecordSize)^, FRecordSize);
  // exit;
  asm
    mov eax,Self
    push esi
    push edi
    mov esi,Value
    mov ecx,SE_Array([eax]).FRecordSize
    mov edi,aRecord
    imul edi,ecx
    add edi,SE_Array([eax]).Data
    mov eax,ecx
    shr ecx,2
    rep movsd
    mov ecx,eax
    and ecx,3
    rep movsb
    pop edi
    pop esi
  end;
end;

procedure SE_Matrix.Clear;
begin
  FillChar(data^, fCount * FRecordSize, 0);
end;


constructor SE_Matrix.Create(Rows, Cols, rSize: Cardinal);
begin

  FRecordSize := rSize;
  FRows := Rows;
  FCols := Cols;
  fCount := Longint(Rows) * Longint(Cols);
  RowSize := Longint(Cols) * Longint(rSize);
  getmem(data, fCount * Longint(rSize));
  Clear;
end;

destructor SE_Matrix.Destroy;
begin
  freemem(data, fCount * FRecordSize);
  inherited Destroy;
end;

procedure SE_Matrix.ExchangeRows(aRow1, aRow2: Cardinal);
begin
  asm
    mov eax,Self
    push ebx
    push esi
    push edi

    mov esi,aRow1
    mov edi,aRow2
    mov ecx,SE_Matrix([eax]).RowSize
    mov edx,SE_Matrix([eax]).Data
    imul esi,ecx
    add esi,edx
    imul edi,ecx
    add edi,edx
    mov edx,ecx
    shr ecx,2
    jz @2

  @1: xchg esi,edi
    add esi,4
    add edi,4
    dec ecx
    jnz @1

  @2: mov ecx,edx
    and ecx,3
    jz @4

  @3: xchg esi,edi
    inc esi
    inc edi
    dec ecx
    jnz @3

  @4: pop edi
    pop esi
    pop ebx
  end;
end;

procedure SE_Matrix.Fill(const value);
begin
  FillStruc(data^, fCount, value, FRecordSize);
end;

procedure SE_Matrix.Read(aRow, aCol: Cardinal; var value);
begin
  // move((PChar(Data)+(aRow*FCols+aCol)*FRecordSize)^, Value, FRecordSize);
  // exit;
  asm
    mov eax,Self
    push esi
    push edi
    mov edi,Value
    mov esi,aRow
    imul esi,SE_Matrix([eax]).FCols
    add esi,aCol
    mov ecx,SE_Matrix([eax]).FRecordSize
    imul esi,ecx
    add esi,SE_Matrix([eax]).Data
    mov eax,ecx
    shr ecx,2
    rep movsd
    mov ecx,eax
    and ecx,3
    rep movsb
    pop edi
    pop esi
  end;
end;

procedure SE_Matrix.ReadRow(aRow: Cardinal; var RowValue);
begin
  move((PAnsiChar(data) + (Longint(aRow) * RowSize))^, RowValue, RowSize);
end;

procedure SE_Matrix.SetCols(Cols: Cardinal);
var
  NewSize, OldRowSize, NewRowSize, BufSize: Longint;
  R, OldCols: Cardinal;
  OldFData, NewFData, RowData: pointer;
begin
  NewSize := Longint(Cols) * Longint(FRows) * FRecordSize;
  OldRowSize := RowSize;
  NewRowSize := Longint(Cols) * FRecordSize;
  OldCols := FCols;
  OldFData := data;

  getmem(NewFData, NewSize);

  if NewRowSize > OldRowSize then
    BufSize := NewRowSize
  else
    BufSize := OldRowSize;
  try
    getmem(RowData, BufSize);
  except
    freemem(NewFData, NewSize);
  end;

  if Cols > OldCols then
    FillChar(RowData^, BufSize, 0);
  for R := 0 to FRows - 1 do begin
    FCols := OldCols;
    RowSize := OldRowSize;
    data := OldFData;
    ReadRow(R, RowData^);
    FCols := Cols;
    RowSize := NewRowSize;
    data := NewFData;
    WriteRow(R, RowData^);
  end;
  freemem(RowData, BufSize);

  fCount := Longint(Cols) * Longint(FRows);

end;

procedure SE_Matrix.SetRows(Rows: Cardinal);
var
  OldSize, NewSize: Longint;
  OldFData: pointer;
begin
  if Rows <> FRows then
  begin

    OldSize := fCount * FRecordSize;
    NewSize := Longint(Rows) * Longint(FCols) * FRecordSize;
    OldFData := data;

    getmem(data, NewSize);

    fCount := Longint(Rows) * Longint(FCols);
    FRows := Rows;

    if NewSize > OldSize then
    begin
      Clear;
      NewSize := OldSize;
    end;
    move(OldFData^, data^, NewSize);

    freemem(OldFData, OldSize);
  end;
end;

procedure SE_Matrix.Write(aRow, aCol: Cardinal; const value);
begin
  // move(Value, (PChar(Data)+(aRow*FCols+aCol)*FRecordSize)^, FRecordSize);
  // exit;
  asm
    mov eax,Self
    push esi
    push edi
    mov esi,Value
    mov edi,aRow
    imul edi, SE_Matrix([eax]).FCols
    add edi,aCol
    mov ecx,SE_Matrix([eax]).FRecordSize
    imul edi,ecx
    add edi,SE_Matrix([eax]).Data
    mov eax,ecx
    shr ecx,2
    rep movsd              // <--- copia i dati dentro
    mov ecx,eax
    and ecx,3
    rep movsb
    pop edi
    pop esi
  end;
end;

procedure SE_Matrix.WriteRow(aRow: Cardinal; const RowValue);
begin
  move(RowValue, (PAnsiChar(data) + (Longint(aRow) * RowSize))^, RowSize);
end;

procedure FillStruc(var Dest; Count: Longint; const value; aRecordSize: Cardinal); assembler; register;
asm
  // eax = Dest, edx = Count, ecx = Value 
  push ebx
  push esi
  push edi
  mov edi,Dest
  mov eax,Value

  mov ebp,aRecordSize
  jmp @2
@1: mov ecx,ebp
  mov esi,eax
  mov bx,cx
  shr ecx,2
  rep movsd
  mov cx,bx
  and cx,3
  rep movsb
@2: sub edx,1
  jnc @1
  pop edi
  pop esi
  pop ebx
end;

constructor SE_ByteArray.Create(aBlockSize: integer);
begin
  inherited Create;
  fBlockSize := aBlockSize;
  fSize := 0;
  fBufferSize := fBlockSize;
  getmem(data, fBufferSize);
end;

destructor SE_ByteArray.Destroy;
begin
  freemem(data);
  inherited;
end;

procedure SE_ByteArray.AddByte(aByte: byte);
begin
  SetSize(fSize + 1);
  data^[fSize - 1] := aByte;
end;

procedure SE_ByteArray.Clear;
begin
  freemem(data);
  fSize := 0;
  fBufferSize := fBlockSize;
  getmem(data, fBufferSize);
end;

procedure SE_ByteArray.SetSize(NewSize: integer);
var
  tmpByteArray: pbytearray;
begin
  if NewSize > fSize then
  begin
    if NewSize > fBufferSize then
    begin
      fBufferSize := NewSize + fBlockSize;
      getmem(tmpByteArray, fBufferSize);
      CopyMemory(tmpByteArray, data, fSize);
      freemem(data);
      data := tmpByteArray;
    end;
  end
  else
  begin
    if NewSize < (fBufferSize - fBlockSize) then
    begin
      fBufferSize := NewSize + fBlockSize;
      getmem(tmpByteArray, fBufferSize);
      CopyMemory(tmpByteArray, data, NewSize);
      freemem(data);
      data := tmpByteArray;
    end;
  end;
  fSize := NewSize;
end;

end.
