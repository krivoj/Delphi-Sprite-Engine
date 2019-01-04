unit DSE_defs;

interface

uses Windows, Messages, Classes, SysUtils, vcl.Graphics;


type

  SE_Direction = ( dirForward, dirBackward );
  TFlipDirection = (FlipH, FlipV);
  SE_BlendMode = (
    SE_BlendNormal,
    SE_BlendAlpha,
    SE_BlendOR,
    SE_BlendAND,
    SE_BlendXOR,
    SE_BlendMAX,
    SE_BlendMIN,
    SE_BlendAverage,
    SE_BlendHardLight,
    SE_BlendSoftLight,
    SE_BlendReflect,
    SE_BlendStamp,
    SE_BlendLuminosity,
    SE_BlendLuminosity2
    );

  PRGB = ^TRGB;
  PRGBROW = ^RGBROW;

  PBitmapInfoHeader256 = ^TBitmapInfoHeader256;
  TBitmapInfoHeader256 = packed record
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
    Palette: array[0..1] of TRGBQUAD;
  end;

  TRGB = packed record
    b: byte;
    g: byte;
    r: byte;
  end;
  RGBROW = array[0..Maxint div 16] of TRGB;

 type  TPointArray7 = array[0..6] of TPoint;

  type THexCellSize = record
    Width : Integer;
    Height : Integer;
    SmallWidth : Integer;
  end;



implementation

end.
