unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,math,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, DSE_theater, Vcl.ExtCtrls, Vcl.StdCtrls, Generics.Collections ,Generics.Defaults, DSE_Bitmap,
  DSE_ThreadTimer;

type
  TForm1 = class(TForm)
    SE_Theater1: SE_Theater;
    SE_Background: SE_Engine;
    SE_Engine1: SE_Engine;
    procedure FormCreate(Sender: TObject);
    procedure SE_Theater1AfterVisibleRender(Sender: TObject; VirtualBitmap, VisibleBitmap: SE_Bitmap);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  Ship,ShipFire: SE_SpritePolygon;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin

  SE_Theater1.VirtualWidth := 1024;
  SE_Theater1.VirtualHeight := 600;
  SE_Theater1.Width := 1024;
  SE_Theater1.Height := 600;

  SE_Background.Priority := 0;
  SE_Engine1.Priority := 1;


  Ship := SE_Engine1.CreateSpritePolygon ('ship', se_theater1.Width div 2, se_theater1.Height div 2, claqua,clBlue, '0.-10,8.10,0.5,-8.10',False,1 );
  Ship.TransparentColor := clWhite;
  Ship.Filled := True;

  Ship.MoverData.MoveMode := Thrust;
  Ship.MoverData.MoveModeThrust_Thrust := 0;//0.3;
  Ship.MoverData.MoveModeThrust_Friction := 0.1;
  Ship.MoverData.MoveModeThrust_MaximumSpeed := 8;

  ShipFire := SE_Engine1.CreateSpritePolygon ('shipfire', se_theater1.Width div 2, se_theater1.Height div 2, clRed,clYellow,'0.0,4.8,0.13,-4.8',False,1 );
  ShipFire.TransparentColor := clWhite;

  ShipFire.MoverData.MoveMode := Thrust;
  ShipFire.MoverData.MoveModeThrust_Thrust := 0;//0.3;
  ShipFire.MoverData.MoveModeThrust_Friction := 0.1;
  ShipFire.MoverData.MoveModeThrust_MaximumSpeed := 8;
  ShipFire.Filled := True;

  ShipFire.Visible := False;

  SE_Theater1.Active := True;

  Randomize;

end;
procedure TForm1.SE_Theater1AfterVisibleRender(Sender: TObject; VirtualBitmap, VisibleBitmap: SE_Bitmap);
begin
  if GetAsyncKeyState (VK_LEFT) < 0 then begin
    Ship.Angle := Ship.Angle - 10;
    ShipFire.Angle := ShipFire.Angle - 10;

  end;
  if GetAsyncKeyState (VK_RIGHT) < 0 then  begin
    Ship.Angle := Ship.Angle + 10;
    ShipFire.Angle := ShipFire.Angle + 10;
  end;

  if GetAsyncKeyState (VK_UP) < 0 then begin
    Ship.MoverData.MoveModeThrust_Thrust := 0.3;
    ShipFire.MoverData.MoveModeThrust_Thrust := 0.3;
    ShipFire.Visible := True;
  end
  else begin
    Ship.MoverData.MoveModeThrust_Thrust := 0;
    ShipFire.MoverData.MoveModeThrust_Thrust := 0;
    ShipFire.Visible := False;
  end;


    //    VK_UP:
//    VK_DOWN:
end;

end.
