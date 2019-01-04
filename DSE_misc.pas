unit DSE_Misc;

interface
  uses Windows, Classes, vcl.Graphics, Sysutils, vcl.Controls, DSE_defs;
type polygonSquare = array [0..4] of TPoint;

Const DosDelimSet  : set of AnsiChar = ['\', ':', #0];
Const stMaxFileLen  = 260;

function imax(v1, v2: Integer): Integer;
function imin(v1, v2: Integer): Integer;
function ilimit(vv, min, max: Integer): Integer;
function TColor2TRGB(cl: TColor): TRGB;
function TRGB2TColor(rgb: TRGB): TColor;
function dmin(v1, v2: Double): Double;
function dmax(v1, v2: Double): Double;
function blimit(vv: Integer): Integer;
function wlimit(vv: Integer): word;
function RGB2TColor(r, g, b: Integer): TColor;

function HasExtensionL(const Name : String; var DotPos : Cardinal) : Boolean;
function JustFilenameL(const PathName : String) : String;
function JustNameL(const PathName : String) : String;
function CharExistsL(const S : String; C : Char) : Boolean;
function WordPositionL(N : Cardinal; const S, WordDelims : String;
                      var Pos : Cardinal) : Boolean;
function ExtractWordL(N : Cardinal; const S, WordDelims : String) : String;
function WordCountL(const S, WordDelims : String) : Cardinal;

function getToken( var sString: String; const sDelim: String ): String;
function GetNextToken  (Const S: string;   Separator: char;   var StartPos: integer): String;
procedure Split  (const S: String;   Separator: Char;   MyStringList: TStringList) ;
function AddToken    (const aToken, S: String;   Separator: Char;   StringLimit: integer): String;



implementation
function imax(v1, v2: Integer): Integer;
asm
  cmp  edx,eax
  jng  @1
  mov  eax,edx
@1:
end;
function imin(v1, v2: Integer): Integer;
asm
  cmp  eax,edx
  jng  @1
  mov  eax,edx
@1:
end;
function ilimit(vv, min, max: Integer): Integer;
asm
  cmp eax,edx
  jg @1
  mov eax,edx
  ret
  @1:
  cmp eax,ecx
  jl @2
  mov eax,ecx
  ret
@2:
end;
function TColor2TRGB(cl: TColor): TRGB;
var
  rgb: longint;
begin
  rgb := colortorgb(cl);
  result.r := $FF and rgb;
  result.g := ($FF00 and rgb) shr 8;
  result.b := ($FF0000 and rgb) shr 16;
end;

function TRGB2TColor(rgb: TRGB): TColor;
begin
  with rgb do
    result := r or (g shl 8) or (b shl 16);
end;

function dmin(v1, v2: Double): Double;
begin
  if v1 < v2 then
    dmin := v1
  else
    dmin := v2;
end;

function dmax(v1, v2: Double): Double;
begin
  if v1 > v2 then
    dmax := v1
  else
    dmax := v2;
end;

function blimit(vv: Integer): Integer;

asm
  OR EAX, EAX
  JNS @@plus
  XOR EAX, EAX
  RET

  @@plus:
  CMP EAX, 255
  JBE @@END
  MOV EAX, 255
@@END:
end;
function wlimit(vv: Integer): word;
begin
  if vv < 0 then
    result := 0
  else
  if vv>65535 then
    result := 65535
  else
    result := vv;
end;

function RGB2TColor(r, g, b: Integer): TColor;
begin
  result := r or (g shl 8) or (b shl 16);
end;

function PointInLineAsm(X, Y, x1, y1, x2, y2, d: Integer): Boolean;
var
  sine, cosinus: Double;
  dx, dy, len: Integer;
begin
  if d = 0 then d := 1;
  asm
    fild(y2)
    fisub(y1)
    fild(x2)
    fisub(x1)
    fpatan
    fsincos
    fstp cosinus
    fstp sine
  end;
  dx  := Round(cosinus * (x - x1) + sine * (y - y1));
  dy  := Round(cosinus * (y - y1) - sine * (x - x1));
  len := Round(cosinus * (x2 - x1) + sine * (y2 - y1)); // length of line
  Result:= (dy > -d) and (dy < d) and (dx > -d) and (dx < len + d);
end;
{function PontInLine(X, Y, x1, y1, x2, y2, d: Integer): Boolean;
var
  Theta,  sine, cosinus: Double;
  dx, dy, len: Integer;
begin
  if d = 0 then d := 1;
  //calc the angle of the line
  Theta:=ArcTan2( (y2-y1),(x2-x1));
  SinCos(Theta,sine, cosinus);
  dx  := Round(cosinus * (x - x1) + sine * (y - y1));
  dy  := Round(cosinus * (y - y1) - sine * (x - x1));
  len := Round(cosinus * (x2 - x1) + sine * (y2 - y1)); // length of line
  Result:= (dy > -d) and (dy < d) and (dx > -d) and (dx < len + d);
end;}


function GetNextToken  (Const S: string;   Separator: char;   var StartPos: integer): String;
var Index: integer;
begin
   Result := '';

   While (S[StartPos] = Separator)
   and (StartPos <= length(S))do
    StartPos := StartPos + 1;

   if StartPos > length(S) then Exit;

   Index := StartPos;

   While (S[Index] <> Separator)
   and (Index <= length(S))do
    Index := Index + 1;

   Result := Copy(S, StartPos, Index - StartPos) ;

   StartPos := Index + 1;
end;

procedure Split    (const S: String;   Separator: Char;   MyStringList: TStringList) ;
var Start: integer;
begin
   Start := 1;
   While Start <= Length(S) do
     MyStringList.Add
       (GetNextToken(S, Separator, Start)) ;
end;

function AddToken (const aToken, S: String; Separator: Char; StringLimit: integer): String;
begin
   if Length(aToken) + Length(S) < StringLimit then
     begin
       if S = '' then
         Result := ''
       else Result := S + Separator;

       Result := Result + aToken;
     end
   else
     Raise Exception.Create('Cannot add token') ;
end;
function getToken( var sString: String; const sDelim: String ): String;
var
  nPos: integer;
begin
  nPos := Pos( sDelim, sString );
  if nPos > 0 then  begin
    GetToken := Copy( sString, 1, nPos - 1 );
    sString := Copy( sString, nPos + 1, Length( sString ) - nPos );
  end
  else  begin
    GetToken := sString;
    sString := '';
  end;
end;

function ExtractWordL(N : Cardinal; const S, WordDelims : String) : String;
var
  C : Cardinal;
  I, J   : Longint;
begin
  Result := '';
  if WordPositionL(N, S, WordDelims, C) then begin
    I := C;
    J := I;
    while (I <= Length(S)) and not
           CharExistsL(WordDelims, S[I]) do
      Inc(I);
    SetLength(Result, I-J);
    Move(S[J], Result[1], (I-J) * SizeOf(Char));
  end;
end;
function WordCountL(const S, WordDelims : String) : Cardinal;
var
  I    : Cardinal;
  SLen : Cardinal;
begin
  Result := 0;
  I := 1;
  SLen := Length(S);

  while I <= SLen do begin
    {skip over delimiters}
    while (I <= SLen) and CharExistsL(WordDelims, S[I]) do
      Inc(I);

    if I <= SLen then
      Inc(Result);

    while (I <= SLen) and not CharExistsL(WordDelims, S[I]) do
      Inc(I);
  end;
end;

function WordPositionL(N : Cardinal; const S, WordDelims : String;
                      var Pos : Cardinal) : Boolean;
var
  Count : Longint;
  I     : Longint;
begin
  Count := 0;
  I := 1;
  Result := False;

  while (I <= Length(S)) and (Count <> LongInt(N)) do begin
    {skip over delimiters}
    while (I <= Length(S)) and CharExistsL(WordDelims, S[I]) do
      Inc(I);

    if I <= Length(S) then
      Inc(Count);

    if Count <> LongInt(N) then
      while (I <= Length(S)) and not CharExistsL(WordDelims, S[I]) do
        Inc(I)
    else begin
      Pos := I;
      Result := True;
    end;
  end;
end;
function CharExistsL(const S : String; C : Char) : Boolean; register;
  {-Count the number of a given character in a string. }
{$IFDEF UNICODE}
var
  I: Integer;
begin
  Result := False;
  for I := 1 to Length(S) do begin
    if S[I] = C then begin
      Result := True;
      Break;
    end;
  end;
end;
{$ELSE}
asm
  push  ebx
  xor   ecx, ecx
  or    eax, eax
  jz    @@Done
  mov   ebx, [eax-StrOffset].LStrRec.Length
  or    ebx, ebx
  jz    @@Done
  jmp   @@5

@@Loop:
  cmp   dl, [eax+3]
  jne   @@1
  inc   ecx
  jmp   @@Done

@@1:
  cmp   dl, [eax+2]
  jne   @@2
  inc   ecx
  jmp   @@Done

@@2:
  cmp   dl, [eax+1]
  jne   @@3
  inc   ecx
  jmp   @@Done

@@3:
  cmp   dl, [eax+0]
  jne   @@4
  inc   ecx
  jmp   @@Done

@@4:
  add   eax, 4
  sub   ebx, 4

@@5:
  cmp   ebx, 4
  jge   @@Loop

  cmp   ebx, 3
  je    @@1

  cmp   ebx, 2
  je    @@2

  cmp   ebx, 1
  je    @@3

@@Done:
  mov   eax, ecx
  pop   ebx
end;
{$ENDIF}
function JustNameL(const PathName : String) : String;
var
  DotPos : Cardinal;
  S      : AnsiString;
begin
  S := JustFileNameL(PathName);
  if HasExtensionL(S, DotPos) then
    S := System.Copy(S, 1, DotPos-1);
  Result := S;
end;
function HasExtensionL(const Name : String; var DotPos : Cardinal) : Boolean;
var
  I : Cardinal;
begin
  DotPos := 0;
  for I := Length(Name) downto 1 do
    if (Name[I] = '.') and (DotPos = 0) then
      DotPos := I;
  Result := (DotPos > 0)
    and not CharExistsL(System.Copy(Name, Succ(DotPos), StMaxFileLen), '\');
end;
function JustFilenameL(const PathName : String) : String;
var
  I : Cardinal;
begin
  Result := '';
  if PathName = '' then Exit;
  I := Succ(Cardinal(Length(PathName)));
  repeat
    Dec(I);
  until (I = 0) or (PathName[I] in DosDelimSet);
  Result := System.Copy(PathName, Succ(I), StMaxFileLen);
end;

end.
