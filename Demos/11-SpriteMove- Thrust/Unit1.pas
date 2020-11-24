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
    SE_ThreadTimer1: SE_ThreadTimer;
    procedure FormCreate(Sender: TObject);
    procedure SE_Engine1SpriteDestinationReached(ASprite: SE_Sprite);
    procedure SE_Theater1AfterVisibleRender(Sender: TObject; VirtualBitmap, VisibleBitmap: SE_Bitmap);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  Ship: SE_SpritePolygon;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  Background: SE_Sprite;
begin

  SE_Theater1.VirtualWidth := 1920;
  SE_Theater1.VirtualHeight := 1200;
  SE_Theater1.Width := 1024;
  SE_Theater1.Height := 600;

  SE_Background.Priority := 0;
  SE_Engine1.Priority := 1;

  Background:= SE_Background.CreateSprite('..\!media\back1.bmp','background',{framesX}1,{framesY}1,{Delay}0,{X}0,{Y}0,{transparent}false,0);
  Background.Position := Point( Background.FrameWidth div 2 , Background.FrameHeight div 2 );

  Ship := SE_Engine1.CreateSpritePolygon ('ship', se_theater1.Width div 2, se_theater1.Height div 2, claqua,'0.-10,8.10,0.5,-8.10',False,1 );
  Ship.TransparentColor := clWhite;

  Ship.MoverData.UseThrust:= True;
  Ship.MoverData.fThrust := 0;//0.3;
  Ship.MoverData.FFriction := 0.1;
  Ship.MoverData.FMaximumSpeed := 8;

  SE_Theater1.Active := True;

  Randomize;

end;




procedure TForm1.SE_Engine1SpriteDestinationReached(ASprite: SE_Sprite);
begin
  ShowMessage( ASprite.Guid + ' reached destination point.');
end;


procedure TForm1.SE_Theater1AfterVisibleRender(Sender: TObject; VirtualBitmap, VisibleBitmap: SE_Bitmap);
begin
  if GetAsyncKeyState (VK_LEFT) < 0 then
   Ship.Angle := Ship.Angle - 10;
  if GetAsyncKeyState (VK_RIGHT) < 0 then
    Ship.Angle := Ship.Angle + 10;

  if GetAsyncKeyState (VK_UP) < 0 then
    Ship.MoverData.fThrust := 0.3
    else Ship.MoverData.fThrust := 0;


    //    VK_UP:
//    VK_DOWN:
end;

end.
