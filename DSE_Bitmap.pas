unit DSE_Bitmap;

interface

uses
  Windows, Messages, vcl.Forms, Classes, vcl.StdCtrls, vcl.Graphics, vcl.Controls, Contnrs, SysUtils,  vcl.extctrls, DSE_defs ;


type
  SE_Bitmap = class;

  SE_Bitmap = class
  private
    fBmpName: string;
    fBitmap: TBitmap;
    fAlpha : double;
    fWidth, fHeight: integer;
    function AllocateImage: boolean;

    function GetPixel(x, y: integer): Tcolor;
    function GetPixel24(x, y: integer): TRGB;
    function GetPPixel24(x, y: integer): PRGB;
    procedure SetPixel(x, y: integer; value: TRGB);
    procedure SetPixel24(x, y: integer; Value: TRGB);

    procedure DestroyBitmapScanlines;
    procedure CreateBitmapScanlines;
    function GetMemory(): pointer;
    procedure CopyToTBitmap(Dest: TBitmap);
    procedure CopyBitmap(Source, Dest: TBitmap);
    function GetRow(Row: integer): pointer;

  protected

    function GetCanvas: TCanvas;
    procedure SetAlpha(Value: double);
    procedure SetWidth(Value: integer);
    procedure SetHeight(Value: integer);
    function GetScanLine(Row: integer): pointer;
    procedure Render24(dbitmapscanline: ppointerarray; var ABitmap: SE_Bitmap; XLUT, YLUT: pinteger; xSrc, ySrc: integer; xDst, yDst: integer; cx1, cy1, cx2, cy2: integer; rx, ry: integer); virtual;
    procedure SetBitmap(bmp: TBitmap);

  public
    fbitmapAlpha: TBitmap;
    fBitmapScanlines: ppointerarray;
    fdata: pointer;
    info: TBitmapInfo;
    DIB_SectionHandle: HBITMAP;
    fRowLen: integer;
    BlendMode: SE_BlendMode;
    constructor Create(); overload;
    constructor Create(aWidth, aHeight: integer; aColor:Tcolor); overload;
    constructor Create(aWidth, aHeight: integer); overload;
    constructor Create(const FileName: string); overload;
    constructor Create(image: SE_Bitmap); overload;
    constructor Create(image: SE_Bitmap; Rect: TRect); overload;
    constructor Create(image: TBitmap; Rect: TRect); overload;
    destructor Destroy; override;

    procedure TakeTBitmap(aBitmap: TBitmap);
    function LoadFromStreamBMP(Stream: TStream): TBitmap;
    function LoadFromFileBMP(const FileName: WideString): TBitmap;

    property BmpName: string read FBmpName write FBmpName;

    property Alpha: double read fAlpha write SetAlpha;

    property Width: integer read fWidth write SetWidth;
    property Height: integer read fHeight write SetHeight;
    procedure Assign(Source: TObject);   // for SE_Bitmap and TBitmap
    procedure AssignImage(Source: SE_Bitmap);     // assign without alpha channel
    property ScanLine[Row: integer]: pointer read GetScanLine;
    procedure UpdateFromTBitmap;


    function GetSegment(Row: integer; Col: integer; Width: integer): pointer;
    property Memory: pointer read GetMemory;
    property TBitmapScanlines: ppointerarray read fBitmapScanlines;
    property Canvas: TCanvas read GetCanvas;
    function Allocate(aWidth, aHeight: integer): boolean;
    procedure FreeImage;


    procedure CopyFromTBitmap(Source: TBitmap);

    procedure CopyRectTo(DestBitmap: SE_Bitmap; SrcX, SrcY, DstX, DstY: integer; RectWidth, RectHeight: integer; Transparent: boolean;wTrans: integer); overload;
//    procedure CopyRectTo(DestBitmap: SE_Bitmap; DstX, DstY: integer; RectSource: Trect); overload;
    procedure Resize(NewWidth, NewHeight: integer;  BackgroundColor: double);
    procedure InternalRender(ABitmap: SE_Bitmap; var ABitmapScanline: ppointerarray;
    xDst, yDst, dxDst, dyDst: integer; xSrc, ySrc, dxSrc, dySrc: integer);

    procedure Flip(Direction: TFlipDirection);
    procedure Rotate(Angle: double); overload;
    function Rotate(Angle: integer): SE_Bitmap; overload;
    procedure Stretch ( NewWidth, Newheight : integer );
    procedure GrayScale;
    procedure Blend(var src: PRGB; var dst: PRGB; BlendMode: SE_BlendMode; var PixAlpha: PRGB);

    property Pixel[x, y: integer]: TColor read GetPixel;
    property Pixel24[x, y: integer]: TRGB read GetPixel24 write SetPixel24;
    property PPixel24[x, y: integer]: PRGB read GetPPixel24;

    procedure Fill(Value: double); overload;
    procedure FillRect(x1, y1, x2, y2: integer; Value: double);

    property Bitmap: TBitmap read fBitmap write SetBitmap;


  end;


procedure BMPReadStream(fs: TStream; Bitmap: SE_Bitmap);
function GetNextZoomValue(CurrentZoom: double; bZoomIn: boolean; SuggestedZoom: double) : double;
function BmpRowLen(Width: integer): int64;


implementation

uses math, DSE_misc, DSE_Theater ;
var
  SE_CosineTab: array[0..255] of integer;

{$R-}
function BmpRowLen(Width: integer): int64;
begin
      result := (((Width * 24) + 31) shr 5) shl 2; // row byte length
 //   result := (Width*3);
//    result := (((Width * 24) + (24 - 1)) div 24) * 3;
//    result := (((Width * 32) + (32 - 1)) div 32) * 4;
end;

procedure Stretch(BitsPerPixel: integer; dest: pbyte; dxDst, dyDst, xSrc, ySrc, dxSrc, dySrc: integer; src: pbyte; srcWidth, srcHeight: integer; fx1, fy1, fx2, fy2: integer);
var
  rx, ry, sy: integer;
  y2, x2: integer;
  x, y: integer;
  px1, px2, px3: pbyte;
  destRowlen, srcRowLen: integer;
  ffx1, ffy1, ffx2, ffy2: integer;
  zx, zy: double;
  arx, arxp: pinteger;
begin
  if (dxDst < 1) or (dyDst < 1) then
    exit;
  destRowlen := (((DxDst * 24) + (24 - 1)) div 24) * 3;
  zeromemory(dest, destRowlen * dyDst);
  srcRowLen := (((srcWidth * 24) + (24 - 1)) div 24) * 3;
  ry := trunc((dySrc / dyDst) * 16384);
  rx := trunc((dxSrc / dxDst) * 16384);
  y2 := dyDst - 1;
  x2 := dxDst - 1;
  zx := dxDst / dxSrc;
  zy := dyDst / dySrc;
  ffy1 := imax(trunc(zy * (fy1 - ySrc)), 0);
  ffx1 := imax(trunc(zx * (fx1 - xSrc)), 0);
  ffy2 := imin(trunc(zy * (fy2 - ySrc + 1)), y2);
  ffx2 := imin(trunc(zx * (fx2 - xSrc + 1)), x2);
  if (ffx2-ffx1+1)<=0 then
    exit;
  zeromemory(dest, (((DxDst * 24) + (24 - 1)) div 24) * 3);
  getmem(arx, sizeof(integer) * (ffx2 - ffx1 + 1));
  arxp := arx;
  for x := ffx1 to ffx2 do begin
    arxp^ := ((rx * x) shr 14) + xSrc;
    inc(arxp);
  end;
  for y := ffy1 to ffy2 do begin
    px2 := pbyte(uint64(dest) + (dyDst - y - 1) * destRowlen);
    sy := imin( SrcHeight-1, ((ry * y) shr 14) + ySrc );
    px1 := pbyte(uint64(src) + (srcHeight - sy - 1) * srcRowlen);
    arxp := arx;
    for x := ffx1 to ffx2 do begin
      pbytearray(px2)^[x] := pbytearray(px1)^[arxp^];
      inc(arxp);
    end;
  end;
  freemem(arx);
end;


constructor SE_Bitmap.Create();
var
  i: integer;
begin
  inherited;
  fWidth := 0;
  fHeight := 0;
  fBitmap := nil;
  fBitmapScanlines := nil;
  for i := 0 to 255 do
    SE_CosineTab[i] := Round(64 - Cos(i * Pi / 255) * 64);

end;

constructor SE_Bitmap.Create(aWidth, aHeight: integer);
begin
  Create();
  Allocate(aWidth, aHeight);
end;

constructor SE_Bitmap.Create(aWidth, aHeight: integer; aColor: TColor);
begin
  Create();
  Allocate(aWidth, aHeight);
  Bitmap.Canvas.Brush.Color := aColor;
  Bitmap.Canvas.Brush.Style := bsSolid;
  Bitmap.Canvas.FillRect(rect(0,0,bitmap.Width,bitmap.Height));
end;
constructor SE_Bitmap.Create(const FileName: string);
begin
  Create();
  LoadFromFileBMP(filename);
  FBmpName:= Filename;
end;

constructor SE_Bitmap.Create(image: SE_Bitmap);
begin
  Create();
  Assign(image);
end;

constructor SE_Bitmap.Create(image: SE_Bitmap; Rect: TRect);
begin
  Create();
  Allocate(Rect.Right - Rect.Left + 1, Rect.Bottom - Rect.Top + 1);
  image.CopyRectTo(self, Rect.Left, Rect.Top, 0, 0, Width, Height,false,0);
end;

constructor SE_Bitmap.Create(image: TBitmap; Rect: TRect);
var
  bmp: SE_Bitmap;
begin
  Create();
  Allocate(Rect.Right - Rect.Left + 1, Rect.Bottom - Rect.Top + 1);
  bmp := SE_Bitmap.Create();
  try
    bmp.CopyFromTBitmap (image);
    bmp.CopyRectTo(self, Rect.Left, Rect.Top, 0, 0, Width, Height,false,0);
  finally
    bmp.Free();
  end;
end;


procedure SE_Bitmap.UpdateFromTBitmap;
begin
  if assigned(fBitmap) then
    if (fWidth <> fBitmap.Width) or (fHeight <> fBitmap.Height) then
    begin
      fWidth := fBitmap.Width;
      fHeight := fBitmap.Height;
      fRowLen := BmpRowLen(fWidth);
      CreateBitmapScanlines;
    end;
    if (fHeight > 0) and assigned(fBitmapScanlines) and (fBitmapScanlines[0] <> fBitmap.Scanline[0]) then
      CreateBitmapScanlines;
end;

destructor SE_Bitmap.Destroy;
begin
  FreeImage;
  inherited;
end;


procedure SE_Bitmap.DestroyBitmapScanlines;
begin
  if fBitmapScanlines <> nil then
    freemem(fBitmapScanlines);
  fBitmapScanlines := nil;
end;

procedure SE_Bitmap.CreateBitmapScanlines;
var
  i: integer;
begin
  DestroyBitmapScanlines;
  if assigned(fBitmap) then begin
    getmem(fBitmapScanlines, (sizeof(pointer) * fHeight) );
    for i := 0 to fHeight - 1 do begin
      fBitmapScanlines[i] := fBitmap.Scanline[i];
    end;
  end;
end;

procedure SE_Bitmap.SetAlpha(Value: double);
begin
  fAlpha := value;
end;


procedure SE_Bitmap.SetWidth(Value: integer);
begin
  if Value <> fWidth then  begin
    if fBitmap = nil then  fBitmap := TBitmap.Create;
    fBitmap.Width := Value;
    fWidth := fBitmap.Width;
    fRowLen := BmpRowLen(fWidth);
    CreateBitmapScanlines;
  end;
end;


procedure SE_Bitmap.SetHeight(Value: integer);
begin
  if Value <> fHeight then  begin
    if fBitmap = nil then  fBitmap := TBitmap.Create;
    fBitmap.Height := Value;
    fHeight := fBitmap.Height;
    CreateBitmapScanlines;
  end;
end;

procedure DoAlignAfter(Bitmap: SE_Bitmap; OldWidth, OldHeight: integer; BackgroundColor: double );
begin
  if Bitmap.Width > OldWidth then
  begin
    Bitmap.FillRect(OldWidth, 0, Bitmap.Width - 1, Bitmap.Height - 1, BackgroundColor);
  end;
  if Bitmap.Height > OldHeight then
  begin
    Bitmap.FillRect(0, OldHeight, Bitmap.Width - 1, Bitmap.Height - 1, BackgroundColor);
  end;
end;

procedure SE_Bitmap.Resize(NewWidth, NewHeight: integer; BackgroundColor: double);
var
  lw, lh: integer;
begin
    lw := Width;
    lh := Height;
    SetWidth(NewWidth);
    SetHeight(NewHeight);
    DoAlignAfter(self, lw, lh, BackgroundColor);
end;
procedure SE_Bitmap.Stretch ( NewWidth, Newheight : integer );
var
  Dst: SE_Bitmap;
  x, y: Integer;
  zx, zy: Double;
  sxarr: array of Integer;
  dst_rgb: PRGB;
  src_rgb: PRGBROW;
begin

    dst:= SE_Bitmap.Create (NewWidth,Newheight);
    dst.Bitmap.PixelFormat := pf24bit;

   // StretchBlt(dst.Bitmap.Canvas.Handle,0,0,NewWidth,Newheight, fbitmap.Canvas.Handle ,0,0,fbitmap.Width,fbitmap.Height,SRCCOPY );
    zx := fbitmap.Width / NewWidth;
    zy := fbitmap.Height / Newheight;


    SetLength(sxarr, NewWidth);
    for x := 0 to NewWidth - 1 do
      sxarr[x] := trunc(x * zx);
      for y := 0 to Newheight - 1 do begin
        src_rgb := fbitmap.Scanline[trunc(y * zy)];
        dst_rgb := Dst.Scanline[y];
        for x := 0 to Dst.Width - 1 do begin
          dst_rgb^ := src_rgb[sxarr[x]];
          inc(dst_rgb);
        end;
      end;
   // sxarr := nil;
    AssignImage(dst);
    FreeAndNil(dst);
end;

procedure SE_Bitmap.Rotate(Angle: double);
var
  dst: SE_Bitmap;

  parx1, parx2: pinteger;
  a, tsin, tcos, cxSrc, cySrc, cxDest, cyDest: Double;
  fx, fy: Integer;
  dw, dh,  x, y: Integer;
  px: pbyte;
  arx1, arx2: pintegerarray;
  ary1, ary2: Integer;
  ps, pd: pbyte;
  dw1, dh1: Integer;
  prgb_s, prgb_d: PRGB;
  srcrows: ppointerarray;
  iangle: Integer;
  aTRGB:trgb;
  wtrans: double;

  procedure Rot90(inv: Boolean);
  var
    x, y: Integer;
    mulx, muly, addx, addy: Integer;
  begin
    dw := height; dw1 := dw-1;
    dh := Width;  dh1 := dh-1;
    dst:= SE_Bitmap.Create (dw,dh);
    aTRGB:= Pixel24   [0,0];
    wtrans:= RGB2TColor (aTRGB.b, aTRGB.g , aTRGB.r) ;
    dst.Fill(wtrans);
    if inv then begin
      mulx := -1;
      muly := 1;
      addx := dw1;
      addy := 0;
    end
    else begin
      mulx := 1;
      muly := -1;
      addx := 0;
      addy := dh1;
    end;
    for x := 0 to dw1 do begin
      ps := ScanLine[addx+x*mulx];
      prgb_s := PRGB(ps);
      for y := 0 to dh1 do begin
        prgb_d := dst.Scanline[addy+y*muly];
        inc(prgb_d, x);
        prgb_d^ := prgb_s^;
        inc(prgb_s);
      end;
    end;
  end;

  procedure Rot180;
  var
    x, y: Integer;
  begin
    dw := width; dw1 := dw-1;
    dh := height;  dh1 := dh-1;
    dst:= SE_Bitmap.Create (dw,dh);
    aTRGB:= Pixel24   [0,0];
    wtrans:= RGB2TColor (aTRGB.b, aTRGB.g , aTRGB.r) ;
    dst.Fill(wtrans);
    for y := 0 to dh1 do begin
      pd := dst.ScanLine[dh1 - y];
      ps := Scanline[y];
      prgb_d := PRGB(pd);
      prgb_s := PRGB(ps);
      inc(prgb_s, dw1);
      for x := 0 to dw1 do begin
        prgb_d^ := prgb_s^;
        inc(prgb_d);
        dec(prgb_s);
      end;
    end;
  end;



begin

  if (Frac(angle) = 0) and ((trunc(angle) mod 90) = 0) then
  begin
    iangle := trunc(angle) mod 360;
    case iangle of
      90 : Rot90(false);
      180 : Rot180;
      270 : Rot90(true);
      -90 : Rot90(true);
      -180 : Rot180;
      -270 : Rot90(false);
    end;
    AssignImage(dst);
    FreeAndNil(dst);
    exit;
  end;

  a := angle * pi / 180;
  dw := round(abs(width * cos(a)) + abs(height * sin(a)));
  dh := round(abs(width * sin(a)) + abs(height * cos(a)));
  dw1 := dw-1;
  dh1 := dh-1;
 { TODO -cbug : verificare bug fill color non clblack }
  dst:= SE_Bitmap.Create (dw,dh);
  aTRGB:= Pixel24   [0,0];
  wtrans:= RGB2TColor (aTRGB.b, aTRGB.g , aTRGB.r) ;
  dst.Fill(wtrans);

  tsin := sin(a);
  tcos := cos(a);
  cxSrc := (Width - 1) / 2;
  cySrc := (Height - 1) / 2;
  cxDest := (dst.Width - 1) / 2;
  cyDest := (dst.Height - 1) / 2;
  getmem(arx1, sizeof(integer) * dst.Width);
  getmem(arx2, sizeof(integer) * dst.Width);
  for x := 0 to dst.Width - 1 do begin
    arx1[x] := round( cxSrc + (x - cxDest) * tcos );
    arx2[x] := round( cySrc + (x - cxDest) * tsin );
  end;
//  per := 100 / (dst.Height);

  getmem(srcrows, height*sizeof(pointer));
  for y := 0 to height-1 do
    srcrows[y] := GetRow(y);

  for y := 0 to dh1 do begin
    px := dst.Scanline[y];
    ary1 := round( (y - cyDest) * tsin );
    ary2 := round( (y - cyDest) * tcos );

    parx1 := @arx1[0];
    parx2 := @arx2[0];

    prgb_d := prgb(px);
    for x := 0 to dw1 do begin
      fx := parx1^ - ary1;
      if (fx >= 0) and (fx < width )then begin
        fy := parx2^ + ary2;
        if (fy >= 0) and (fy < height) then begin
          prgb_s := srcrows[fy];
          inc(prgb_s, fx);
          prgb_d^ := prgb_s^;
        end;
      end;
      inc(prgb_d);
      inc(parx1);
      inc(parx2);
    end;


  end;

  freemem(srcrows);
  freemem(arx1);
  freemem(arx2);

  AssignImage(dst);
  FreeAndNil(dst);

end;

function SE_Bitmap.Rotate(Angle: integer): SE_Bitmap;
var
  dst: SE_Bitmap;

  parx1, parx2: pinteger;
  a, tsin, tcos, cxSrc, cySrc, cxDest, cyDest: Double;
  fx, fy: Integer;
  dw, dh,  x, y: Integer;
  px: pbyte;
  arx1, arx2: pintegerarray;
  ary1, ary2: Integer;
  ps, pd: pbyte;
  dw1, dh1: Integer;
  prgb_s, prgb_d: PRGB;
  srcrows: ppointerarray;
  iangle: Integer;
  aTRGB:trgb;
  wtrans: double;

  procedure Rot90(inv: Boolean);
  var
    x, y: Integer;
    mulx, muly, addx, addy: Integer;
  begin
    dw := height; dw1 := dw-1;
    dh := Width;  dh1 := dh-1;
    dst:= SE_Bitmap.Create (dw,dh);
    aTRGB:= Pixel24   [0,0];
    wtrans:= RGB2TColor (aTRGB.b, aTRGB.g , aTRGB.r) ;
    dst.Fill(wtrans);
    if inv then begin
      mulx := -1;
      muly := 1;
      addx := dw1;
      addy := 0;
    end
    else begin
      mulx := 1;
      muly := -1;
      addx := 0;
      addy := dh1;
    end;
    for x := 0 to dw1 do begin
      ps := ScanLine[addx+x*mulx];
      prgb_s := PRGB(ps);
      for y := 0 to dh1 do begin
        prgb_d := dst.Scanline[addy+y*muly];
        inc(prgb_d, x);
        prgb_d^ := prgb_s^;
        inc(prgb_s);
      end;
    end;
  end;

  procedure Rot180;
  var
    x, y: Integer;
  begin
    dw := width; dw1 := dw-1;
    dh := height;  dh1 := dh-1;
    dst:= SE_Bitmap.Create (dw,dh);
    aTRGB:= Pixel24   [0,0];
    wtrans:= RGB2TColor (aTRGB.b, aTRGB.g , aTRGB.r) ;
    dst.Fill(wtrans);
    for y := 0 to dh1 do begin
      pd := dst.ScanLine[dh1 - y];
      ps := Scanline[y];
      prgb_d := PRGB(pd);
      prgb_s := PRGB(ps);
      inc(prgb_s, dw1);
      for x := 0 to dw1 do begin
        prgb_d^ := prgb_s^;
        inc(prgb_d);
        dec(prgb_s);
      end;
    end;
  end;



begin

  if (Frac(angle) = 0) and ((trunc(angle) mod 90) = 0) then begin
    iangle := trunc(angle) mod 360;
    case iangle of
      90 : Rot90(false);
      180 : Rot180;
      270 : Rot90(true);
      -90 : Rot90(true);
      -180 : Rot180;
      -270 : Rot90(false);
    end;
    AssignImage(dst);
    FreeAndNil(dst);
    exit;
  end;

  a := angle * pi / 180;
  dw := round(abs(width * cos(a)) + abs(height * sin(a)));
  dh := round(abs(width * sin(a)) + abs(height * cos(a)));
  dw1 := dw-1;
  dh1 := dh-1;
 { TODO -cbug : verificare bug fill color non clblack }
   dst:= SE_Bitmap.Create (dw,dh);
  aTRGB:= Pixel24   [0,0];
  wtrans:= RGB2TColor (aTRGB.b, aTRGB.g , aTRGB.r) ;
  dst.Fill(wtrans);

  tsin := sin(a);
  tcos := cos(a);
  cxSrc := (Width - 1) / 2;
  cySrc := (Height - 1) / 2;
  cxDest := (dst.Width - 1) / 2;
  cyDest := (dst.Height - 1) / 2;
  getmem(arx1, sizeof(integer) * dst.Width);
  getmem(arx2, sizeof(integer) * dst.Width);
  for x := 0 to dst.Width - 1 do begin
    arx1[x] := round( cxSrc + (x - cxDest) * tcos );
    arx2[x] := round( cySrc + (x - cxDest) * tsin );
  end;

  getmem(srcrows, height*sizeof(pointer));
  for y := 0 to height-1 do
    srcrows[y] := GetRow(y);

  for y := 0 to dh1 do  begin
    px := dst.Scanline[y];
    ary1 := round( (y - cyDest) * tsin );
    ary2 := round( (y - cyDest) * tcos );

    parx1 := @arx1[0];
    parx2 := @arx2[0];

    prgb_d := prgb(px);
    for x := 0 to dw1 do begin
      fx := parx1^ - ary1;
      if (fx >= 0) and (fx < width )then begin
        fy := parx2^ + ary2;
        if (fy >= 0) and (fy < height) then begin
          prgb_s := srcrows[fy];
          inc(prgb_s, fx);
          prgb_d^ := prgb_s^;
        end;
      end;
      inc(prgb_d);
      inc(parx1);
      inc(parx2);
    end;


  end;

  freemem(srcrows);
  freemem(arx1);
  freemem(arx2);

  Result := dst;

end;

procedure SE_Bitmap.Flip(Direction: TFlipDirection);
var
  x, y, w, h: Integer;
  newbitmap: SE_Bitmap;
  newpx, oldpx: PRGB;
begin
  newbitmap := SE_Bitmap.create;
  newbitmap.Allocate(Width, Height);
  w := width - 1;
  h := height - 1;
  case direction of
    FlipH:
        for y := 0 to h do begin
          newpx := newbitmap.ScanLine[y];
          oldpx := ScanLine[y];
          inc(oldpx, w);
          for x := 0 to w do begin
            newpx^ := oldpx^;
            inc(newpx);
            dec(oldpx);
          end;
        end;


    FlipV:
        for y := 0 to h do
          copymemory(newbitmap.scanline[y], scanline[h - y], 3 * Width)
  end;
  AssignImage(newbitmap);
  FreeAndNil(newbitmap);

end;

procedure SE_Bitmap.FreeImage;
begin
  DestroyBitmapScanlines;
  if fBitmap <> nil then FreeAndNil(fBitmap);
  fBitmap := nil;
  fWidth := 0;
  fHeight := 0;
  fRowlen := 0;
end;

function SE_Bitmap.AllocateImage: boolean;
begin
  result := false;
  if (fWidth > 0) and (fHeight > 0)  then begin

    fRowLen := BmpRowLen(fWidth);
    fBitmap := TBitmap.Create;
    fBitmap.Width  := fWidth;
    fBitmap.Height := fHeight;
    fBitmap.PixelFormat := pf24bit;

    CreateBitmapScanlines;
    result := true;
  end;
end;



function SE_Bitmap.Allocate(aWidth, aHeight: integer): boolean;
begin
    if fbitmap <> nil then fBitmap.PixelFormat := pf24bit;
    FreeImage;
    fWidth := aWidth;
    fHeight := aHeight;
    result := AllocateImage;
    if result=false then begin
      fWidth  := 0;
      fHeight := 0;
    end;

end;


procedure SE_Bitmap.Assign(Source: TObject);
var
  src: SE_Bitmap;
  row, mi: integer;
begin
  if Source is SE_Bitmap then begin
      src := Source as SE_Bitmap;
      fWidth := src.fWidth;
      fHeight := src.fHeight;
      if fBitmap = nil then
        fBitmap := TBitmap.Create;
      fBitmap.Width := 4;
      fBitmap.Height := 4;
      fbitmap.PixelFormat := pf24bit;
      fBitmap.Width := fWidth;
      fBitmap.Height := fHeight;
      fRowLen := BmpRowLen(fWidth);
      CreateBitmapScanlines;
      mi := imin(fRowLen, src.fRowLen);
      for row := 0 to fHeight - 1 do
        copymemory(ScanLine[row], src.ScanLine[row], mi);
  end
  else
  if Source is TBitmap then
    CopyFromTBitmap(Source as TBitmap);
end;

procedure SE_Bitmap.AssignImage(Source: SE_Bitmap);
var
  row, mi: integer;
begin
    fWidth       := Source.fWidth;
    fHeight      := Source.fHeight;
    if fBitmap = nil then
      fBitmap := TBitmap.Create;
    fBitmap.Width  := fWidth;
    fBitmap.Height := fHeight;
    fBitmap.PixelFormat := pf24bit;
    fRowLen       := BmpRowLen(fWidth);
    CreateBitmapScanlines;

    mi := imin(fRowLen, Source.fRowLen);
    for row := 0 to fHeight - 1 do
      CopyMemory(ScanLine[row], Source.ScanLine[row], mi);
end;


function SE_Bitmap.GetSegment(Row: integer; Col: integer; Width: integer): pointer;
begin
    result := Scanline[Row];
    inc(pbyte(result), Col * 3);
end;

function SE_Bitmap.GetScanLine(Row: integer): pointer;
begin
    result := fBitmapScanlines[row];
end;

function SE_Bitmap.GetRow(Row: integer): pointer;
begin
      result := fBitmapScanlines[row];
end;

procedure SE_Bitmap.GrayScale;
var
  x, y,v: integer;
  ppx: PRGB;
begin

  for y := 0 to height - 1 do  begin
    ppx := ScanLine[y];
    for x := 0 to Width -1 do begin
      with ppx^ do begin
        v := (r * 21 + g * 71 + b * 8) div 100;
        r := v;
        g := v;
        b := v;
      end;
      inc(ppx);
    end;
   end;
end;


procedure SE_Bitmap.CopyToTBitmap(Dest: TBitmap);
var
   row,  mi: integer;
begin

    Dest.Width := fWidth;
    Dest.Height := fHeight;
    Dest.PixelFormat := pf24bit;
    mi := imin(fRowLen, BmpRowLen(Dest.Width));
    for row := 0 to fHeight - 1 do
      CopyMemory(Dest.Scanline[row], Scanline[row], mi);
end;

procedure SE_Bitmap.CopyRectTo(DestBitmap: SE_Bitmap; SrcX, SrcY, DstX, DstY: integer; RectWidth, RectHeight: integer; Transparent: boolean;wTrans: integer);
var
  y,x: integer;
  ps, pd: pbyte;
  rl: integer;
  ppRGBCurrentFrame,ppVirtualRGB,ppRGBCurrentFrameAlpha: pRGB;
  aTrgb: Trgb;
  label skip;


begin

  if Transparent then begin

     aTRGB:= DSE_Misc.TColor2TRGB (wtrans);

    SrcX:=0;  // arbitrario
    SrcY:=0;
   // DstX:= DrawingRect.Left ;
   // DstY:= DrawingRect.Top;


   // RectWidth:=fbitmap.width;
   // rectheight:=fbitmap.height;
    if DstX < 0 then begin
      inc(SrcX, -DstX);
      dec(RectWidth, -DstX);
      DstX := 0;
    end;
    if DstY < 0 then begin
      inc(SrcY, -DstY);
      dec(RectHeight, -DstY);
      DstY := 0;
    end;

    DstX := imin(DstX, DestBitmap.Width - 1);
    DstY := imin(DstY, DestBitmap.Height - 1);

    SrcX := imin(imax(SrcX, 0), fbitmap.Width - 1);
    SrcY := imin(imax(SrcY, 0), fbitmap.Height - 1);

//    if SrcX + RectWidth > Width then //begin
//     exit;
//    if SrcY + RectHeight > Height then //begin
//     exit;

    if SrcX + RectWidth > fbitmap.Width then
      RectWidth := fbitmap.Width - SrcX;
    if SrcY + RectHeight > fbitmap.Height then
      RectHeight := fbitmap.Height - SrcY;

    if DstX + RectWidth > DestBitmap.Width then
      RectWidth := DestBitmap.Width - DstX;
    if DstY + RectHeight > DestBitmap.Height then
      RectHeight := DestBitmap.Height - DstY;

    for y := 0 to RectHeight - 1 do begin
      ppRGBCurrentFrame := GetSegment(SrcY + y, SrcX, RectWidth);

      if Alpha <> 0 then begin
        ppRGBCurrentFrameAlpha :=   fBitmapAlpha.Scanline[SrcY + y];
        inc(pbyte(ppRGBCurrentFrameAlpha), SrcX * 3);
      end;

      ppVirtualRGB := DestBitmap.GetSegment(DstY + y, DstX, RectWidth);
      for x := SrcX to SrcX + RectWidth - 1 do begin
//        if not((ppRGBCurrentFrame.b = aTRGB.b) and (ppRGBCurrentFrame.g = aTRGB.g) and (ppRGBCurrentFrame.r = aTRGB.r)) then begin
        if (ppRGBCurrentFrame.b <> aTRGB.b) or (ppRGBCurrentFrame.g <> aTRGB.g) or (ppRGBCurrentFrame.r <> aTRGB.r) then begin
          if fAlpha <> 0 then begin
            if (ppRGBCurrentFrameAlpha.B <> 255) and (ppRGBCurrentFrameAlpha.G <> 255) and (ppRGBCurrentFrameAlpha.R <> 255)  then begin
          // se non è 0 in alpha
//              Blend ( ppRGBCurrentFrame,ppVirtualRGB,SE_BlendAlpha,0); ;  // trovare alpha   AND ????
              Blend ( ppRGBCurrentFrame,ppVirtualRGB,SE_BlendAlpha,ppRGBCurrentFrameAlpha ); ;  // trovare alpha  AND ????


            end
            else begin   // se è 0 in alpha
              if BlendMode = SE_BlendNormal then begin
                ppVirtualRGB.b := ppRGBCurrentFrame.b;
                ppVirtualRGB.g:= ppRGBCurrentFrame.g;
                ppVirtualRGB.r:= ppRGBCurrentFrame.r;
              end
              else begin
                Blend ( ppRGBCurrentFrame,ppVirtualRGB,BlendMode,ppRGBCurrentFrame); ;
              end;
            end;
          end
          else begin
              if BlendMode = SE_BlendNormal then begin
                ppVirtualRGB.b := ppRGBCurrentFrame.b;
                ppVirtualRGB.g:= ppRGBCurrentFrame.g;
                ppVirtualRGB.r:= ppRGBCurrentFrame.r;
              end
              else begin
                Blend ( ppRGBCurrentFrame,ppVirtualRGB,BlendMode,ppRGBCurrentFrame); ;
              end;
          end;
        end;
        SKIP:
        if fAlpha <> 0 then inc(pbyte(ppRGBCurrentFrameAlpha),3);
        inc(pbyte(ppRGBCurrentFrame),3);
        inc(pbyte(ppVirtualRGB),3);

      end;
    end;


  end
  else begin // non transparent
  //  RectWidth:=fbitmap.width;
  //  rectheight:=fbitmap.height;

  if DstX < 0 then begin
    inc(SrcX, -DstX);
    dec(RectWidth, -DstX);
    DstX := 0;
  end;
  if DstY < 0 then begin
    inc(SrcY, -DstY);
    dec(RectHeight, -DstY);
    DstY := 0;
  end;


  DstX := imin(DstX, DestBitmap.Width - 1);
  DstY := imin(DstY, DestBitmap.Height - 1);
  SrcX := imin(imax(SrcX, 0), Width - 1);
  SrcY := imin(imax(SrcY, 0), Height - 1);

//  if SrcX + RectWidth > Width then //begin
//   exit;
//  if SrcY + RectHeight > Height then //begin
 //  exit;
//  end;
  if SrcX + RectWidth > Width then
    RectWidth := Width - SrcX;
  if SrcY + RectHeight > Height then
    RectHeight := Height - SrcY;

  if DstX + RectWidth > DestBitmap.Width then
    RectWidth := DestBitmap.Width - DstX;
  if DstY + RectHeight > DestBitmap.Height then
    RectHeight := DestBitmap.Height - DstY;

    // pf24bit
    rl := (((RectWidth * 24) + 31) shr 5) shl 2; // row byte length
    if BlendMode = SE_BlendNormal then begin
      for y := 0 to RectHeight - 1 do begin
        ps := GetSegment(SrcY + y, SrcX, RectWidth);
        pd := DestBitmap.GetSegment(DstY + y, DstX, RectWidth);
        CopyMemory(pd, ps, rl);
      end;
    end
    else begin
      for y := 0 to RectHeight - 1 do begin
        ppRGBCurrentFrame := GetSegment(SrcY + y, SrcX, RectWidth);
        ppVirtualRGB := DestBitmap.GetSegment(DstY + y, DstX, RectWidth);
        for x := SrcX to SrcX + RectWidth - 1 do begin
          if not((ppRGBCurrentFrame.b = aTRGB.b) and (ppRGBCurrentFrame.g = aTRGB.g) and (ppRGBCurrentFrame.r = aTRGB.r)) then begin

            if BlendMode = SE_BlendNormal then begin
              ppVirtualRGB.b := ppRGBCurrentFrame.b;
              ppVirtualRGB.g:= ppRGBCurrentFrame.g;
              ppVirtualRGB.r:= ppRGBCurrentFrame.r;
            end
            else begin


              Blend ( ppRGBCurrentFrame,ppVirtualRGB,BlendMode,ppRGBCurrentFrame); ;
            end;
          end;
          inc(pbyte(ppRGBCurrentFrame),sizeof(TRGB));
          inc(pbyte(ppVirtualRGB),sizeof(TRGB));
        end;
      end;
    end;
  end;




end;

{procedure SE_Bitmap.CopyRectTo(DestBitmap: SE_Bitmap; DstX, DstY: integer; RectSource: Trect );
var
  rectDest: TRect;
  y,X: integer;
  rectDestBlock, rectIntersect: TRect;
  nSrcBlockWidth, nSrcBlockHeight: integer;
  nSrcX, nSrcY: integer;
  nOffSrc, nIncSrc: integer;
  nOffDest, nIncDest: integer;
  pSource, pDest: pointer;
  nSrcWidth3, nSrcX3, nSrcBlockWidth3, nDestX3, inverter: integer;
begin
  // al momento c'è un bug. procedura non utilizzata
  Inverter:= DestBitmap.Height -1;

  pDest := DestBitmap.Memory;//.ScanLine[Theater.fVirtualBitmap.Height -1];
  pSource := memory;//.Scanline[BmpCurrentFrame.height-1];

  nSrcBlockWidth := RectSource.Width +1;
  nSrcBlockHeight := RectSource.Height +1;
  nSrcX := RectSource.left;
  nSrcY := RectSource.top;

  X:= DstX;
  Y:= dSTY;

  rectDest := Rect( 0, 0, DestBitmap.Width - 1, DestBitmap.Height - 1 );
  rectDestBlock := Rect( X, Y, X + nSrcBlockWidth -1, Y + nSrcBlockHeight -1 );

  if not IntersectRect( rectIntersect, rectDest, rectDestBlock ) then
    Exit;
(* Taglia i bitmap se escono dalla visuale *)
  if X < 0 then
  begin
    Inc( nSrcX, Abs( X ) );
    Dec( nSrcBlockWidth, Abs( X ) );
    X:= 0;
  end;
  if ( X + nSrcBlockWidth - 1 ) >= DestBitmap.Width then
     Dec( nSrcBlockWidth, ( ( X + nSrcBlockWidth ) - DestBitmap.Width ) );
  if Y < 0 then
  begin
    Dec( nSrcBlockHeight, Abs( Y ) );
    Inc( nSrcY, Abs( Y ) );
    Y:=0;
  end;
  if ( Y + nSrcBlockHeight - 1 ) >= DestBitmap.Height then
     Dec( nSrcBlockHeight, ( ( Y + nSrcBlockHeight ) - DestBitmap.Height ) );

  nSrcWidth3 := Width * sizeof(TRGB);
  nSrcX3 := nSrcX * sizeof(TRGB);
  nSrcBlockWidth3 := nSrcBlockWidth * sizeof(TRGB);
  nDestX3 := X * sizeof(TRGB);

  nOffSrc := nSrcWidth3 * ( Height - nSrcY - 1 ) + nSrcX3;
  nIncSrc := -( nSrcWidth3 + nSrcBlockWidth3 );



  nOffDest :=DestBitmap.Width*sizeof(TRGB) * ( inverter - Y  ) + nDestX3;
  nIncDest := -( DestBitmap.Width*sizeof(TRGB) + nSrcBlockWidth3 );

//    nOffDest := (Theater.fVirtualBitmap.Width * sizeof(TRGB)) *  inverter ;
//    nIncDest := -( nSrcWidth3 + nSrcBlockWidth3 );

//      nOffDest := Theater.fVirtualBitmap.Width * sizeof(TRGB) * Y + nDestX3;          // ribaltato
//      nIncDest := Theater.fVirtualBitmap.Width * sizeof(TRGB) - nSrcBlockWidth3;

    asm
       push esi
       push edi
       push ebx

// imposto source/destination
        mov  esi,[pSource]
        mov  edi,[pDest]
        add  esi,[nOffSrc]
        add  edi,[nOffDest]

// quante righe copiare
        mov  edx,[nSrcBlockHeight]
        mov  eax,[nSrcBlockWidth]
        mov  ebx, eax

        push eax
        shr  ebx,1
        mov eax, ebx
        shr ebx,1
        add eax, ebx
        mov ebx,eax
        pop eax
        and  eax,$01
// inizio copie delle righe
      @OuterLoop:
        mov  ecx,ebx
        rep  movsd
        mov  ecx,eax
        rep  movsw

// dopo ogni riga aggiorno i puntatori
        add  esi,[nIncSrc]
        add  edi,[nIncDest]
        dec  edx
        jnz  @OuterLoop


        pop ebx
        pop edi
        pop esi
    end;

end;      }

procedure SE_Bitmap.CopyFromTBitmap(Source: TBitmap);
begin
    FreeImage;

    fBitmap := TBitmap.Create;
    fWidth := Source.Width;
    fHeight := Source.Height;
    fBitmap.Width := Source.Width ;
    fBitmap.height := Source.Height ;
    fBitmap.PixelFormat := pf24bit;
    Source.PixelFormat := pf24bit;
    CopyBitmap(Source, fBitmap);
    fRowLen := BmpRowLen(fWidth);
    CreateBitmapScanlines;
end;

procedure SE_Bitmap.CopyBitmap(Source, Dest: TBitmap);
var
  ps, pd: pbyte;
  l: Integer;
begin
  if (Source.Width = 0) or (Source.Height = 0) then
  begin
    Dest.Width := 1;
    Dest.Height := 1;
    Dest.Pixelformat := pf24bit;
  end
  else
  begin
    if (Dest.Width <> Source.Width) or (Dest.Height <> Source.Height) then
    begin
      Dest.Width := Source.Width;
      Dest.Height := Source.height;
      Dest.Pixelformat := pf24bit;
    end;
    ps := pbyte(imin(uint64(Source.Scanline[0]), uint64(Source.Scanline[Source.Height - 1])));
    pd := pbyte(imin(uint64(Dest.Scanline[0]), uint64(Dest.Scanline[Dest.Height - 1])));
    l := BmpRowLen(Dest.Width);
    copymemory(pd, ps, l * Dest.height);
  end;
end;



function SE_Bitmap.GetPixel24(x, y: integer): TRGB;
begin
  result := PRGB(GetSegment(y, x, 1))^;
end;

function SE_Bitmap.GetPixel(x, y: integer): TColor;
var
aTrgb: trgb;
begin
  aTRGB:= Pixel24   [x,y];
  Result:=    RGB2TColor (aTRGB.r, aTRGB.g , aTRGB.b) ;

end;
function SE_Bitmap.GetPPixel24(x, y: integer): PRGB;
begin
  result := @(PRGBROW(Scanline[y])^[x]);
end;


procedure SE_Bitmap.SetPixel24(x, y: integer; value: TRGB);
begin
    Canvas.Pixels [x,y] :=  DSE_misc.TRGB2TColor (Value);
//    Pixel24[x, y] := value;
end;


procedure SE_Bitmap.SetPixel(x, y: integer; Value: TRGB);
begin
  PRGBROW(Scanline[y])^[x] := Value;
end;


procedure SE_Bitmap.Fill(Value: double);
var
  row, col, iValue: integer;
  pxrgb: PRGB;
  vrgb: TRGB;
  pxb: pbyte;
begin
  ivalue := trunc(Value);
  vrgb := DSE_misc.TColor2TRGB(TColor(iValue));
  if fHeight>0 then begin
    getmem(pxb, fRowlen);
    pxrgb := PRGB(pxb);
    for col := 0 to fWidth - 1 do begin
      pxrgb^ := vrgb;
      inc(pxrgb);
    end;
    for row := 0 to fHeight-1 do
      CopyMemory(Scanline[row], pxb, fRowLen);
    freemem(pxb);
  end;

end;

procedure SE_Bitmap.FillRect(x1, y1, x2, y2: integer; Value: double);
var
  row, col, iValue: integer;
  pxrgb: PRGB;
  vrgb: TRGB;
  ww: integer;
begin
  x1 := imax(x1, 0);
  y1 := imax(y1, 0);
  x2 := imin(x2, fWidth - 1);
  y2 := imin(y2, fHeight - 1);
  ww := x2 - x1 + 1;
  iValue := trunc(Value);

  vrgb := DSE_misc.TColor2TRGB(TColor(iValue));
  for row := y1 to y2 do  begin
    pxrgb := GetSegment(row, x1, ww);
    for col := x1 to x2 do begin
      pxrgb^ := vrgb;
      inc(pxrgb);
    end;
  end;
end;

function SE_Bitmap.GetCanvas: TCanvas;
begin
  result := fBitmap.Canvas;
end;

procedure SE_Bitmap.InternalRender(ABitmap: SE_Bitmap; var ABitmapScanline: ppointerarray;
 xDst, yDst, dxDst, dyDst: integer; xSrc, ySrc, dxSrc, dySrc: integer);
var
  i, y, x, ww, hh: integer;
  DBitmapScanline: ppointerarray;
  x2, y2: integer;
  rx, ry: integer;
  cx1, cy1, cx2, cy2: integer;
  sxarr, psx, syarr, psy: pinteger;

  dummy1, dummy2: pinteger;
  zx, zy: double;
begin

    if (dxDst = 0) or (dyDst = 0) or (dxSrc = 0) or (dySrc = 0) then
      exit;
    if yDst > ABitmap.Height - 1 then
      exit;
    if xDst > ABitmap.Width - 1 then
      exit;
    zy := dySrc / dyDst;
    zx := dxSrc / dxDst;
    if yDst < 0 then begin
      y := -yDst;
      yDst := 0;
      dec(dyDst, y);
      inc(ySrc, round(y * zy));
      dec(dySrc, round(y * zy));
    end;
    if xDst < 0 then begin
      x := -xDst;
      xDst := 0;
      dec(dxDst, x);
      inc(xSrc, round(x * zx));
      dec(dxSrc, round(x * zx));
    end;
    if yDst + dyDst > ABitmap.Height then begin
      y := yDst + dyDst - ABitmap.Height;
      dyDst := ABitmap.Height - yDst;
      dec(dySrc, trunc(y * zy));
    end;
    if xDst + dxDst > ABitmap.Width then begin
      x := xDst + dxDst - ABitmap.Width;
      dxDst := ABitmap.Width - xDst;
      dec(dxSrc, trunc(x * zx));
    end;
    xDst  := imax(imin(xDst, ABitmap.Width - 1), 0);
    yDst  := imax(imin(yDst, ABitmap.Height - 1), 0);
    dxDst := imax(imin(dxDst, ABitmap.Width), 0);
    dyDst := imax(imin(dyDst, ABitmap.Height), 0);
    xSrc  := imax(imin(xSrc, Width - 1), 0);
    ySrc  := imax(imin(ySrc, Height - 1), 0);
    dxSrc := imax(imin(dxSrc, Width), 0);
    dySrc := imax(imin(dySrc, Height), 0);

    if (dxDst = 0) or (dyDst = 0) or (dxSrc = 0) or (dySrc = 0) then
      exit;

    if (dxDst = 0) or (dyDst = 0) or (dxSrc = 0) or (dySrc = 0) then
      exit;
    ww := ABitmap.Width;
    hh := ABitmap.Height;
    if ABitmapScanline = nil then
    begin
      getmem(DBitmapScanline, hh * sizeof(pointer));
      for y := 0 to hh - 1 do
        DBitmapScanline[y] := ABitmap.Scanline[y];
    end
    else
      DBitmapScanline := ABitmapScanline;

    if (dxDst <> 0) and (dyDst <> 0) then begin
      sxarr := nil;
      syarr := nil;
      ry := trunc((dySrc / dyDst) * 16384);
      rx := trunc((dxSrc / dxDst) * 16384);
      y2 := imin(yDst + dyDst - 1, hh - 1);
      x2 := imin(xDst + dxDst - 1, ww - 1);
      cx1 := -2147483646;
      cy1 := -2147483646;
      cx2 := 2147483646;
      cy2 := 2147483646;
      cx1 := imax(cx1, xDst);
      cx2 := imin(cx2, x2);
      cy1 := imax(cy1, yDst);
      cy2 := imin(cy2, y2);

      cx1 := imax(cx1, 0);
      cx1 := imin(cx1, ABitmap.Width - 1);
      cx2 := imax(cx2, 0);
      cx2 := imin(cx2, ABitmap.Width - 1);
      cy1 := imax(cy1, 0);
      cy1 := imin(cy1, ABitmap.Height - 1);
      cy2 := imax(cy2, 0);
      cy2 := imin(cy2, ABitmap.Height - 1);


      if (ry <> 16384) or (rx <> 16384) then begin
          getmem(sxarr, (cx2 - cx1 + 1) * sizeof(integer));
          psx := sxarr;

          for x := cx1 to cx2 do begin
            psx^ := ilimit(trunc( zx*(x-xDst) + xSrc ), 0, fWidth-1);
            inc(psx);
          end;

          getmem(syarr, (cy2 - cy1 + 1) * sizeof(integer));
          psy := syarr;

          for y := cy1 to cy2 do begin
            psy^ := ilimit(trunc( zy*(y-yDst) + ySrc ), 0, fHeight-1);
            inc(psy);
          end;

      end;

      Render24(dbitmapscanline, ABitmap, sxarr, syarr, xSrc, ySrc, xDst, yDst, cx1, cy1, cx2, cy2, rx, ry);

      if (sxarr <> nil)  then
          freemem(sxarr);
      if (syarr <> nil)  then
          freemem(syarr);
    end;

    if ABitmapScanline = nil then begin
        freemem(DBitmapScanline)
    end;


end;


procedure SE_Bitmap.Render24(dbitmapscanline: ppointerarray; var ABitmap: SE_Bitmap; XLUT, YLUT: pinteger; xSrc, ySrc: integer; xDst, yDst: integer; cx1, cy1, cx2, cy2: integer; rx, ry: integer  );
var
  psy, syarr, psx, sxarr: pinteger;
  x, y, l, rl: integer;
  px4, px2: prgb;
  px1: PRGBROW;
  rl2, rl4: integer;
begin

  sxarr := XLUT;
  syarr := YLUT;
  l := -1;
  rl := ABitmap.fRowLen;

  if (ry = 16384) and (rx = 16384) then begin
    rl2 := uint64(dbitmapscanline[1]) - uint64(dbitmapscanline[0]);
    px2 := dbitmapscanline[cy1];
    inc(px2, cx1);
    rl4 := (cx2 - cx1 + 1) * 3;
    for y := cy1 to cy2 do
    begin
      px4 := scanline[ySrc + (y - yDst)];
      inc(px4, xSrc + (cx1 - xDst));
      copymemory(px2, px4, rl4);
      inc(pbyte(px2), rl2);
    end;
  end
  else begin
    psy := syarr;
    for y := cy1 to cy2 do begin
      if (l = psy^) then begin
        copymemory(dbitmapscanline[y], dbitmapscanline[y - 1], rl);
      end
      else begin
        px2 := dBitmapScanline[y];
        inc(px2, cx1);
        px1 := Scanline[psy^];
        psx := sxarr;
        for x := cx1 to cx2 do begin
          px2^ := px1[psx^];
          inc(px2);
          inc(psx);
        end;
        l := psy^;
      end;
      inc(psy);
    end
  end;
end;

function SE_Bitmap.GetMemory(): pointer;
begin
    result := self.fBitmapScanlines[fHeight - 1]
end;


function GetNextZoomValue(CurrentZoom: double; bZoomIn: boolean; SuggestedZoom: double) : double;
var
  ZoomInc: integer;
begin
  result := CurrentZoom;

  if bZoomIn then begin
    ZoomInc := 25;
    result := result + 1;
  end
  else begin
    if result < 6 then begin
      Result := 1;
      exit
    end
    else begin
      ZoomInc := 0;
      result := result - 1;
    end;
  end;

  if result < 26 then
    result := ((trunc(result) div 5) * 5) + (ZoomInc div 5)
  else
    if result < 300 then
    result := ((trunc(result) div 25) * 25) + ZoomInc
  else
    result := ((trunc(result) div 100) * 100) + (ZoomInc * 4);

  if (SuggestedZoom > 0) and
     (SuggestedZoom <> CurrentZoom) and
     (trunc(SuggestedZoom) <> trunc(CurrentZoom)) and
     (SuggestedZoom > Min(trunc(result), trunc(CurrentZoom))) and
     (SuggestedZoom < Max(trunc(result), trunc(CurrentZoom))) then
    result := SuggestedZoom;
end;



procedure SE_Bitmap.TakeTBitmap(aBitmap: TBitmap);
begin
  if (aBitmap<>nil) and ((aBitmap<>fBitmap) or (aBitmap.Width<>fWidth) or (aBitmap.Height<>fHeight) ) then begin
    fWidth := aBitmap.Width;
    fHeight := aBitmap.Height;
    fRowLen := BmpRowLen(fWidth);
    fBitmap := aBitmap;
    CreateBitmapScanlines;
  end;
end;


function SE_Bitmap.LoadFromStreamBMP(Stream: TStream): TBitmap;
begin
  if assigned(fBitmap) then
    TakeTBitmap(fBitmap);

    BMPReadStream(Stream, Self );
    result:= fBitmap;
end;


function SE_Bitmap.LoadFromFileBMP(const FileName: WideString):  TBitmap;
var
  aStream: TFileStream;
begin
    aStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    LoadFromStreamBMP(aStream);
    Result:= fBitmap;
    FreeAndNil(aStream);
end;

procedure SE_Bitmap.SetBitmap(bmp: TBitmap);
begin
  CopyFromTBitmap(fBitmap);
end;

type
  TBITMAPINFOHEADER2 = packed record
    biSize: DWORD;
    biWidth: Longint;
    biHeight: Longint;
    biPlanes: Word;
    biBitCount: Word;
    biCompression: DWORD;
    biSizeImage: DWORD;
    biXPelsPerMeter: Longint;
    biYPelsPerMeter: Longint;
    biClrUsed: DWORD;
    biClrImportant: DWORD;

    biUnits: word;
    biReserved: word;
    biRecording: word;
    biRendering: word;
    biSize1: dword;
    biSize2: dword;
    biColorencoding: dword;
    biIdentifier: dword;
end;
procedure BMPReadStream(fs: TStream; Bitmap: SE_Bitmap );
var
  FileHead: TBITMAPFILEHEADER;
  InfoHead: ^TBITMAPINFOHEADER2;
  CoreHead: ^TBITMAPCOREHEADER;
  dm: integer;
  p0: int64;
  y: integer;
  lw: integer;
  inverter: integer;

begin

  InfoHead := AllocMem(sizeof(TBITMAPINFOHEADER2));
  CoreHead := AllocMem(sizeof(TBITMAPCOREHEADER));

  try
    p0 := fs.Position;
    fs.Read(FileHead, sizeof(TBITMAPFILEHEADER));
    if FileHead.bfSize > 0  then
    if FileHead.bfType <> 19778 then exit;

    fs.Read(dm, sizeof(dm));
    fs.Seek(-4, soCurrent);

      FillChar(InfoHead^, sizeof(TBITMAPINFOHEADER2), 0);
      fs.Read(InfoHead^, imin(sizeof(TBITMAPINFOHEADER2), dm));
      if dm > sizeof(TBITMAPINFOHEADER2) then
        fs.Seek(dm - 40, soCurrent);

      if dm <> 40 then exit;

      if InfoHead^.biHeight < 0 then begin
        InfoHead^.biHeight := -InfoHead^.biHeight;
        inverter := InfoHead^.biHeight - 1;
      end
      else
      inverter := 0;

      if InfoHead.biBitCount <> 24 then
          raise Exception.Create( ' BitCount is not 24 ! ');


      if (InfoHead^.biCompression= BI_RLE4) or (InfoHead^.biCompression = BI_RLE8) then
        raise Exception.Create('Compressed Bitmap not supported!');


      if FileHead.bfOffBits > 0 then
      fs.Position := p0 + FileHead.bfOffBits;


      if not Bitmap.Allocate(InfoHead^.biWidth, InfoHead^.biHeight ) then  exit;

//      lw := (((Bitmap.width * 24) + (24 - 1)) div 24) * 3;
//      lw :=   (((Bitmap.width * 32) + (32 - 1)) div 32) * 4;
      lw := (((Bitmap.Width * 24) + 31) shr 5) shl 2; // row byte length
//      lw:= BmpRowLen (Bitmap.width);
      for y := Bitmap.Height - 1 downto 0 do
      begin
        fs.read(pbyte(Bitmap.Scanline[abs(inverter - y)])^, lw);
      end;

  finally
    freemem(InfoHead);
    freemem(CoreHead);
  end;
end;
procedure RGB2HSL(px: PRGB; var Hue, Sat, Lum: Double);
var
  delta, r, g, b, cmax, cmin: Double;
begin
  r := px.r / 255;
  g := px.g / 255;
  b := px.b / 255;
  cmax := dmax(r, dmax(g, b));
  cmin := dmin(r, dmin(g, b));
  Lum := (cmax + cmin) / 2;
  if cmax = cmin then  begin
    Sat := 0;
    Hue := 0;
  end
  else begin
    if Lum < 0.5 then
      Sat := (cmax - cmin) / (cmax + cmin)
    else
      Sat := (cmax - cmin) / (2 - cmax - cmin);
    delta := cmax - cmin;
    if r = cmax then
      Hue := (g - b) / delta
    else
    if g = cmax then
      Hue := 2 + (b - r) / delta
    else
      Hue := 4 + (r - g) / delta;
    Hue := Hue / 6;
    if Hue < 0 then
      Hue := Hue + 1;
  end;
end;

// iHue, iSat, iLum 0..1

procedure HSL2RGB(var px: PRGB; iHue, iSat, iLum: Double);
  function HueToRGB(m1, m2, h: Double): Double;
  const
    C1 = 2 / 3;
  begin
    if h < 0 then
      h := h + 1
    else
    if h > 1 then
      h := h - 1;
    if 6 * h < 1 then
      result := (m1 + (m2 - m1) * h * 6)
    else
    if 2 * h < 1 then
      result := m2
    else
    if 3 * h < 2 then
      result := (m1 + (m2 - m1) * (C1 - h) * 6)
    else
      result := m1;
  end;
const
  C1 = 1 / 3;
var
  r, g, b: Double;
  m1, m2: Double;
begin
  // check limits
  if iHue < 0 then
    iHue := 1 + iHue
  else
  if iHue > 1 then
    iHue := iHue - 1;
  if iSat < 0 then
    iSat := 0
  else
  if iSat > 1 then
    iSat := 1;
  if iLum < 0 then
    iLum := 0
  else
  if iLum > 1 then
    iLum := 1;
  //
  if iSat = 0 then
  begin
    r := iLum;
    g := iLum;
    b := iLum;
  end
  else
  begin
    if iLum <= 0.5 then
      m2 := iLum * (1 + iSat)
    else
      m2 := iLum + iSat - iLum * iSat;
    m1 := 2 * iLum - m2;
    r := HueToRGB(m1, m2, iHue + C1);
    g := HueToRGB(m1, m2, iHue);
    b := HueToRGB(m1, m2, iHue - C1);
  end;
  px.r := blimit(round(r * 255));
  px.g := blimit(round(g * 255));
  px.b := blimit(round(b * 255));
end;
procedure RGB2YCbCr(rgb: PRGB; var Y, Cb, Cr: integer);
begin
 // with rgb do
 // begin
    Y  := blimit(trunc(0.29900 * rgb.R + 0.58700 * rgb.G + 0.11400 * rgb.B));
    Cb := blimit(trunc(-0.16874 * rgb.R - 0.33126 * rgb.G + 0.50000 * rgb.B  + 128));
    Cr := blimit(trunc(0.50000 * rgb.R - 0.41869 * rgb.G - 0.08131 * rgb.B  + 128));
//  end;
end;

procedure YCbCr2RGB(var rgb: PRGB; Y, Cb, Cr: integer);
begin
  Cb := Cb-128;
  Cr := Cr-128;
  rgb.r := blimit(trunc(Y + 1.40200 * Cr));
  rgb.g := blimit(trunc(Y - 0.34414 * Cb - 0.71414 * Cr));
  rgb.b := blimit(trunc(Y + 1.77200 * Cb));
end;


procedure SE_Bitmap.Blend(var src: PRGB; var dst: PRGB; BlendMode: SE_BlendMode; var PixAlpha: PRGB);
// filters
  function softlight(ib, ia: integer): integer;  inline;
  var
    a, b, r: double;
  begin
    a := ia / 255;
    b := ib / 255;
    if b < 0.5 then
      r := 2 * a * b + sqr(a) * (1 - 2 * b)
    else
      r := sqrt(a) * (2 * b - 1) + (2 * a) * (1 - b);
    result := trunc(r * 255);
  end;

  function reflect(b, a: integer): integer;  inline;
  var
    c: integer;
  begin
    if b = 255 then
      result := 255
    else begin
      c := a * a div (255 - b);
      if c > 255 then
        result := 255
      else
        result := c;
    end;
  end;


  function stamp(b, a: integer): integer;  inline;
  var
    c: integer;
  begin
    c := a + 2 * b - 256;
    if c < 0 then
      result := 0
    else
    if c > 255 then
      result := 255
    else
      result := c;
  end;
  //
function MixBytes(FG, BG, TRANS: byte): byte;
asm
  push bx
  push cx
  push dx
  mov DH,TRANS
  mov BL,FG
  mov AL,DH
  mov CL,BG
  xor AH,AH
  xor BH,BH
  xor CH,CH
  mul BL
  mov BX,AX
  xor AH,AH
  mov AL,DH
  xor AL,$FF
  mul CL
  add AX,BX
  shr AX,8
  pop dx
  pop cx
  pop bx
end;
var
  Ha, Sa, La: double;
  Hb, Sb, Lb: double;
  tmp: TRGB;
  v1, v2: byte;
  Y_1, Cb_1, Cr_1: integer;
  Y_2, Cb_2, Cr_2: integer;
  i: integer;
  Table: array[-255..255] of Integer;
Begin

  case BlendMode of
    SE_BlendAlpha:
      begin
//        dst.R := Trunc(src.R * alpha + pixAlpha.R * (1.0 - alpha)); { TODO : da fixare }
//        dst.G := Trunc(src.G * alpha + pixAlpha.G * (1.0 - alpha));
//        dst.B := Trunc(src.B * alpha + pixAlpha.B * (1.0 - alpha));
//        dst.R := MixBytes (src.r, pixAlpha.R, Byte(Trunc(alpha)) );
//        dst.G := MixBytes (src.g, pixAlpha.G, Byte(Trunc(alpha)) );
//        dst.B := MixBytes (src.b, pixAlpha.B, Byte(Trunc(alpha)) );
//          dst.R := MixBytes (dst.r, src.R, Byte(Trunc(alpha)) );
//          dst.G := MixBytes (dst.g, src.G, Byte(Trunc(alpha)) );
//          dst.B := MixBytes (dst.b, src.B, Byte(Trunc(alpha)) );

//        for i := -255 to 255 do
//          Table[i] := (Round( FAlpha) * i) shr 8;
//          dst.b := Table[src.b - dst.b] + dst.b;
//          dst.g := Table[src.b - dst.g] + dst.g;
//          dst.r := Table[src.b - dst.r] + dst.r;

//          dst.r := (dst.r * (256 - Trunc(Alpha)) + pixAlpha.r * Trunc(Alpha)) shr 8;    // al posto di pixelalpha src ... inverte l'effetto
//          dst.g := (dst.g * (256 - Trunc(Alpha)) + pixAlpha.g * Trunc(Alpha)) shr 8;
//          dst.b := (dst.b * (256 - Trunc(Alpha)) + pixAlpha.b * Trunc(Alpha)) shr 8;

          dst.r := (dst.r * (256 - Trunc(Alpha)) + src.r * Trunc(Alpha)) shr 8;    // al posto di pixelalpha src ... inverte l'effetto
          dst.g := (dst.g * (256 - Trunc(Alpha)) + src.g * Trunc(Alpha)) shr 8;
          dst.b := (dst.b * (256 - Trunc(Alpha)) + src.b * Trunc(Alpha)) shr 8;

//          dst.r := (Trunc(Alpha) * (pixAlpha.r - dst.r) shr 8) + dst.r ;
//          dst.g := (Trunc(Alpha) * (pixAlpha.g - dst.g) shr 8) + dst.g ;
//          dst.b := (Trunc(Alpha) * (pixAlpha.b - dst.b) shr 8) + dst.b ;

//          dst.r := (Trunc(Alpha) * (src.r - dst.r) shr 8) + dst.r ;
//          dst.g := (Trunc(Alpha) * (src.g - dst.g) shr 8) + dst.g ;
//          dst.b := (Trunc(Alpha) * (src.b - dst.b) shr 8) + dst.b ;
      end;
    SE_BlendOR:
      begin
        dst.r := blimit(dst.r or src.r);
        dst.g := blimit(dst.g or src.g);
        dst.b := blimit(dst.b or src.b);
      end;
    SE_BlendAND:
      begin
        dst.r := blimit(dst.r and src.r);
        dst.g := blimit(dst.g and src.g);
        dst.b := blimit(dst.b and src.b);
      end;
    SE_BlendXOR:
      begin
        dst.r := blimit(dst.r xor src.r);
        dst.g := blimit(dst.g xor src.g);
        dst.b := blimit(dst.b xor src.b);
      end;
    SE_BlendMAX:
      begin
        dst.r := imax(dst.r, src.r);
        dst.g := imax(dst.g, src.g);
        dst.b := imax(dst.b, src.b);
      end;
    SE_BlendMIN:
      begin
        dst.r := imin(dst.r, src.r);
        dst.g := imin(dst.g, src.g);
        dst.b := imin(dst.b, src.b);
      end;
    SE_BlendAverage:
      begin
        dst.r := (dst.r + src.r) shr 1;
        dst.g := (dst.g + src.g) shr 1;
        dst.b := (dst.b + src.b) shr 1;
      end;
    SE_BlendHardLight:
      begin
        if src.r < 128 then
          dst.r := (src.r * dst.r) shr 7
        else
          dst.r := 255 - ((255 - src.r) * (255 - dst.r) shr 7);
        if src.g < 128 then
          dst.g := (src.g * dst.g) shr 7
        else
          dst.g := 255 - ((255 - src.g) * (255 - dst.g) shr 7);
        if src.b < 128 then
          dst.b := (src.b * dst.b) shr 7
        else
          dst.b := 255 - ((255 - src.b) * (255 - dst.b) shr 7);
      end;
    SE_BlendSoftLight:
      begin
        dst.r := softlight(src.r, dst.r);
        dst.g := softlight(src.r, dst.g);
        dst.b := softlight(src.r, dst.b);
      end;
    SE_BlendReflect:
      begin
        dst.r := Reflect(src.r, dst.r);
        dst.g := Reflect(src.g, dst.g);
        dst.b := Reflect(src.b, dst.b);
      end;
    SE_BlendStamp:
      begin
        dst.r := Stamp(src.r, dst.r);
        dst.g := Stamp(src.g, dst.g);
        dst.b := Stamp(src.b, dst.b);
      end;
    SE_BlendLuminosity:
      begin
        RGB2HSL(src, Ha, Sa, La);
        RGB2HSL(dst, Hb, Sb, Lb);
        HSL2RGB(dst, Hb, Sb, La);
      end;
    SE_BlendLuminosity2:
      begin
        RGB2YCbCr(src, Y_1, Cb_1, Cr_1);
        RGB2YCbCr(dst, Y_2, Cb_2, Cr_2);
        YCbCr2RGB(dst, Y_1, Cb_2, Cr_2);
      end;
end;
end;

end.





