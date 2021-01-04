unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,math,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, DSE_theater, Vcl.ExtCtrls, Vcl.StdCtrls, Generics.Collections ,Generics.Defaults, DSE_Bitmap,
  DSE_ThreadTimer, DSE_defs;

type
  TForm1 = class(TForm)
    SE_Theater1: SE_Theater;
    SE_Background: SE_Engine;
    SE_Characters: SE_Engine;
    Panel1: TPanel;
    Label1: TLabel;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    Edit1: TEdit;
    Panel2: TPanel;
    Label2: TLabel;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    Edit2: TEdit;
    SE_ThreadTimer1: SE_ThreadTimer;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    CheckBox5: TCheckBox;
    CheckBox6: TCheckBox;
    SE_label: SE_Engine;
    Memo1: TMemo;
    SE_ThreadTimer2: SE_ThreadTimer;
    procedure FormCreate(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
    procedure CheckBox3Click(Sender: TObject);
    procedure CheckBox4Click(Sender: TObject);
    procedure Edit2Change(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure SE_ThreadTimer1Timer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure SE_CharactersSpriteDestinationReached(ASprite: SE_Sprite);
    procedure SE_Theater1BeforeVisibleRender(Sender: TObject; VirtualBitmap, VisibleBitmap: SE_Bitmap);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure CheckBox5Click(Sender: TObject);
    procedure SE_CharactersCollision(Sender: TObject; Sprite1, Sprite2: SE_Sprite);
    procedure SE_ThreadTimer2Timer(Sender: TObject);
  private
    { Private declarations }
    function GetIsoDirection (X1,Y1,X2,Y2:integer): integer;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  Background,SpriteTree: SE_Sprite;
  i: Integer;
begin

  SE_Theater1.VirtualWidth := 1920;
  SE_Theater1.VirtualHeight := 1200;
  SE_Theater1.Width := 1024;
  SE_Theater1.Height := 600;

  SE_Background.Priority := 0;
  SE_Characters.Priority := 1;


  Background:= SE_Background.CreateSprite('..\!media\back1.bmp','background',{framesX}1,{framesY}1,{Delay}0,{X}0,{Y}0,{transparent}false,0);
  Background.Position := Point( Background.FrameWidth div 2 , Background.FrameHeight div 2 );

  SE_Theater1.Active := True;
  Randomize;

  for i := 0 to 9 do begin
    SE_Characters.CreateSprite('..\!media\gabriel_WALK.bmp' ,'gabriel'+ IntToStr(i),{framesX}15,{framesY}6,{Delay}7,
    {X}randomrange(100,900),{Y}randomrange(100,500),{transparent}true,1);
  end;
  for i := 0 to 9 do begin
    SE_Characters.CreateSprite('..\!media\shahira_WALK.bmp' ,'shahira'+ IntToStr(i),{framesX}15,{framesY}6,{Delay}7,
    {X}randomrange(100,900),{Y}randomrange(100,500),{transparent}true,1);
  end;

  SpriteTree := SE_Characters.CreateSprite('..\!media\tree.bmp','tree',{framesX}2,{framesY}1,{Delay}5,{X}250,{Y}250,{transparent}true,1);
  SpriteTree.ModPriority := 170;
  SpriteTree.CollisionIgnore := True;

  SE_Characters.PixelCollision := CheckBox5.Checked ;

end;
function TForm1.GetIsoDirection (X1,Y1,X2,Y2:integer): integer;
begin

  if (X2 = X1) and (Y2 = Y1) then Result:=1;

  if (X2 = X1) and (Y2 < Y1) then Result:=4;
  if (X2 = X1) and (Y2 > Y1) then Result:=1;

  if (X2 < X1) and (Y2 < Y1) then Result:=5;
  if (X2 > X1) and (Y2 < Y1) then Result:=3;

  if (X2 > X1) and (Y2 > Y1) then Result:=2;
  if (X2 < X1) and (Y2 > Y1) then Result:=6;

  if (X2 > X1) and (Y2 = Y1) then Result:=3;
  if (X2 < X1) and (Y2 = Y1) then Result:=5;


end;

procedure TForm1.SE_CharactersCollision(Sender: TObject; Sprite1, Sprite2: SE_Sprite);
begin

  memo1.Lines.Add( 'Collision ' + Sprite1.Guid + ' ' + Sprite2.guid );
  Sprite1.BlendMode :=  SE_BlendReflect;
  Sprite2.BlendMode :=  SE_BlendReflect;

end;

procedure TForm1.SE_CharactersSpriteDestinationReached(ASprite: SE_Sprite);
begin
  aSprite.MoverData.MoveModePath_MovePath.Reverse ;
  aSprite.NotifyDestinationReached := True;
  aSprite.MoverData.MoveMode := Path;

end;

procedure TForm1.SE_Theater1BeforeVisibleRender(Sender: TObject; VirtualBitmap, VisibleBitmap: SE_Bitmap);
var
  Sprite: SE_Sprite;
  I,k: Integer;
begin
  if CheckBox6.Checked  then begin

    for I := 0 to 9 do begin
      Sprite:= SE_Characters.FindSprite('gabriel' + intTostr(i));
      if Sprite.MoverData.MoveModePath_MovePath.Count > 0 then begin
        VirtualBitmap.Canvas.Pen.Color := clSilver;

        VirtualBitmap.Canvas.MoveTo( Sprite.MoverData.MoveModePath_MovePath[0].X,Sprite.MoverData.MoveModePath_MovePath[0].Y );
        for k := 1 to Sprite.MoverData.MoveModePath_MovePath.Count -1 do begin
          VirtualBitmap.Canvas.LineTo( Sprite.MoverData.MoveModePath_MovePath[k].X,Sprite.MoverData.MoveModePath_MovePath[k].Y );
        end;

      end;
    end;

    for I := 0 to 9 do begin
     Sprite:= SE_Characters.FindSprite('shahira'+ intTostr(i));

      if Sprite.MoverData.MoveModePath_MovePath.Count > 0 then begin
        VirtualBitmap.Canvas.Pen.Color := clRed;

        VirtualBitmap.Canvas.MoveTo( Sprite.MoverData.MoveModePath_MovePath[0].X,Sprite.MoverData.MoveModePath_MovePath[0].Y );
        for k := 1 to Sprite.MoverData.MoveModePath_MovePath.Count -1 do begin
         VirtualBitmap.Canvas.LineTo( Sprite.MoverData.MoveModePath_MovePath[k].X,Sprite.MoverData.MoveModePath_MovePath[k].Y );
        end;
      end;
    end;
  end;
end;

procedure TForm1.SE_ThreadTimer1Timer(Sender: TObject);
var
  Sprite: SE_Sprite;
  I: Integer;
begin

  for I := 0 to 9 do begin
     Sprite:= SE_Characters.FindSprite('gabriel' + intTostr(i));
     if Sprite.MoverData.MoveModePath_CurWP < Sprite.MoverData.MoveModePath_MovePath.Count -1 then begin
     Sprite.FrameY :=  GetIsoDirection ( Sprite.Position.X, Sprite.Position.Y,
                                                Sprite.MoverData.MoveModePath_MovePath [ Sprite.MoverData.MoveModePath_CurWP +1].X ,
                                                Sprite.MoverData.MoveModePath_MovePath [ Sprite.MoverData.MoveModePath_CurWP +1].Y);
     end;
  end;
  for I := 0 to 9 do begin
     Sprite:= SE_Characters.FindSprite('shahira' + intTostr(i));
     if Sprite.MoverData.MoveModePath_CurWP < Sprite.MoverData.MoveModePath_MovePath.Count -1 then begin
     Sprite.FrameY :=  GetIsoDirection ( Sprite.Position.X, Sprite.Position.Y,
                                                Sprite.MoverData.MoveModePath_MovePath [ Sprite.MoverData.MoveModePath_CurWP +1].X ,
                                                Sprite.MoverData.MoveModePath_MovePath [ Sprite.MoverData.MoveModePath_CurWP +1].Y);
     end;
  end;


end;

procedure TForm1.SE_ThreadTimer2Timer(Sender: TObject);
var
  Sprite: SE_Sprite;
  I: Integer;
begin

  for I := 0 to 9 do begin
    Sprite:= SE_Characters.FindSprite('gabriel' + IntToStr(i));
    Sprite.BlendMode :=  SE_BlendNormal;
  end;
  for I := 0 to 9 do begin
    Sprite:= SE_Characters.FindSprite('shahira' + IntToStr(i));
    Sprite.BlendMode :=  SE_BlendNormal;
  end;

end;

procedure TForm1.Button1Click(Sender: TObject);
var
  Sprite: SE_Sprite;
  Point,Point2,lastPoint :Tpoint;
  tmpPath: TList<TPoint>;
  I,wayPoints,k: Integer;
begin

   for I := 0 to 9 do begin
     Sprite:= SE_Characters.FindSprite('gabriel' + IntToStr(i));
     Sprite.PositionX := RandomRange(100,900);
     Sprite.PositionY := RandomRange(100,500);
     Sprite.MoverData.MoveModePath_MovePath.Clear ;

     LastPoint := Sprite.Position;

     for WayPoints := 0 to 6 do begin
       Point.X:= randomrange ( 100,500);
       Point.Y:= randomrange ( 100,500);

       tmpPath:= TList<TPoint>.Create;
       GetLinePoints( LastPoint.X, LastPoint.Y,  Point.X, Point.Y,  tmpPath );

       for k := 0 to tmpPath.Count -1 do begin
         Point2:=tmpPath[k];
         Sprite.MoverData.MoveModePath_MovePath.Add(Point2);
       end;
       LastPoint := Point;
       tmpPath.Free ;


     end;

     Sprite.MoverData.MoveMode := Path;
     Sprite.MoverData.Speed := 1.0;  // minimum usepath
     Sprite.MoverData.MoveModePath_WPinterval  := 50; // delay
     Sprite.NotifyDestinationReached := True;

   end;

   for I := 0 to 9 do begin
     Sprite:= SE_Characters.FindSprite('shahira' + IntToStr(i));
     Sprite.PositionX := RandomRange(100,900);
     Sprite.PositionY := RandomRange(100,500);
     Sprite.MoverData.MoveModePath_MovePath.Clear ;

     LastPoint := Sprite.Position;

     for WayPoints := 0 to 6 do begin
       Point.X:= randomrange ( 100,500);
       Point.Y:= randomrange ( 100,500);

       tmpPath:= TList<TPoint>.Create;
       GetLinePoints( LastPoint.X, LastPoint.Y,  Point.X, Point.Y,  tmpPath );

       for k := 0 to tmpPath.Count -1 do begin
         Point2:=tmpPath[k];
         Sprite.MoverData.MoveModePath_MovePath.Add(Point2);
       end;
       LastPoint := Point;
       tmpPath.Free ;


     end;

     Sprite.MoverData.MoveMode :=Path;
     Sprite.MoverData.Speed := 1.0;  // minimum usepath
     Sprite.MoverData.MoveModePath_WPinterval  := 50; // delay
     Sprite.NotifyDestinationReached := True;

   end;


end;

procedure TForm1.Button2Click(Sender: TObject);
var
  Sprite: SE_Sprite;
  SpriteBuff : SE_SubSprite;
  i: Integer;
begin

   for I := 0 to 9 do begin
     Sprite:= SE_Characters.FindSprite('gabriel' + IntToStr(i));
     Sprite.SubSprites.Clear ;

     SpriteBuff := SE_SubSprite.create('..\!media\buff1.bmp','buff1',32,0,True,true,1);
     Sprite.SubSprites.Add(Spritebuff);
     SpriteBuff := SE_SubSprite.create('..\!media\buff2.bmp','buff2',50,0,True,true,1);
     Sprite.SubSprites.Add(Spritebuff);

   end;

   for I := 0 to 9 do begin
     Sprite:= SE_Characters.FindSprite('shahira' + IntToStr(i));
     Sprite.SubSprites.Clear ;

     SpriteBuff := SE_SubSprite.create('..\!media\buff3.bmp','buff3',32,0,True,true,1);
     Sprite.SubSprites.Add(Spritebuff);
     SpriteBuff := SE_SubSprite.create('..\!media\buff4.bmp','buff4',50,0,True,true,1);
     Sprite.SubSprites.Add(Spritebuff);

   end;

end;

procedure TForm1.Button3Click(Sender: TObject);
var
  Sprite: SE_Sprite;
  i: Integer;
  SpriteLabel : SE_SpriteLabel;
begin

   for I := 0 to 9 do begin
     Sprite:= SE_Characters.FindSprite('gabriel' + IntToStr(i));
     Sprite.labels.Clear ;
     SpriteLabel := SE_SpriteLabel.create(0,64,'Verdana',clYellow,clBlack,8,'Gabriel',True, 1, dt_center );   // 1= transparent, 2= opaque
     Sprite.Labels.Add(SpriteLabel);
   end;
   for I := 0 to 9 do begin
     Sprite:= SE_Characters.FindSprite('shahira' + IntToStr(i));
     Sprite.labels.Clear ;
     SpriteLabel := SE_SpriteLabel.create(0,64,'Verdana',clYellow,clBlack,8,'Shahira',True, 1, dt_center );   // 1= transparent, 2= opaque
     Sprite.Labels.Add(SpriteLabel);
   end;

end;

procedure TForm1.CheckBox1Click(Sender: TObject);
begin
  SE_Theater1.MousePan := checkBox1.Checked ;
end;

procedure TForm1.CheckBox2Click(Sender: TObject);
begin
  SE_Theater1.MouseScroll := checkBox2.Checked ;

end;

procedure TForm1.CheckBox3Click(Sender: TObject);
begin
  SE_Theater1.MouseWheelZoom  :=  checkBox3.Checked ;
end;

procedure TForm1.CheckBox4Click(Sender: TObject);
begin
  SE_Theater1.MouseWheelInvert  := checkBox4.Checked ;
end;

procedure TForm1.CheckBox5Click(Sender: TObject);
begin
  SE_Characters.PixelCollision := CheckBox5.Checked ;
end;

procedure TForm1.Edit1Change(Sender: TObject);
begin
  SE_Theater1.MouseScrollRate  := StrToFloatDef ( edit1.Text ,0 );

end;

procedure TForm1.Edit2Change(Sender: TObject);
begin
  SE_Theater1.MouseWheelValue  := StrToIntDef ( edit2.Text ,0 );

end;

end.
