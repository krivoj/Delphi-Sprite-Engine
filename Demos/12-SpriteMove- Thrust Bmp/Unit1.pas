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
  Ship: SE_Sprite;

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

  Ship:= SE_Engine1.CreateSprite('..\!media\spacecraft.bmp','ship',{framesX}1,{framesY}1,{Delay}0,{X}SE_theater1.Width div 2,{Y}SE_theater1.Height div 2,{transparent}true,0);
  Ship.MoverData.MoveMode := Thrust;
  Ship.MoverData.MoveModeThrust_Thrust := 0;//0.3;
  Ship.MoverData.MoveModeThrust_Friction := 0.1;
  Ship.MoverData.MoveModeThrust_MaximumSpeed := 8;

  SE_Theater1.Active := True;


end;
procedure TForm1.SE_Theater1AfterVisibleRender(Sender: TObject; VirtualBitmap, VisibleBitmap: SE_Bitmap);
begin
  if GetAsyncKeyState (VK_LEFT) < 0 then begin
    Ship.Angle := Ship.Angle - 10;

  end;
  if GetAsyncKeyState (VK_RIGHT) < 0 then  begin
    Ship.Angle := Ship.Angle + 10;
  end;

  if GetAsyncKeyState (VK_UP) < 0 then begin
    Ship.MoverData.MoveModeThrust_Thrust := 0.3;
  end
  else begin
    Ship.MoverData.MoveModeThrust_Thrust := 0;
  end;


    //    VK_UP:
//    VK_DOWN:
end;

end.
