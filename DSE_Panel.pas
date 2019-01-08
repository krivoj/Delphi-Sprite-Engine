unit DSE_Panel;

interface

uses
  Windows, SysUtils, Classes, vcl.Controls, vcl.Graphics , Vcl.ExtCtrls, DSE_Bitmap;

type
  SE_Panel = class(TPanel)
  private
    { Private declarations }
    fBackground: SE_Bitmap;
    procedure SetBackground(const Value: SE_Bitmap);
  protected
    { Protected declarations }
    procedure Paint; override;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    property Background : SE_Bitmap read fBackground write SetBackground;
  published
    { Published declarations }
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('DSE', [SE_Panel]);
end;

{ SE_Panel }

constructor SE_Panel.Create(AOwner: TComponent);
begin
  inherited;
end;

procedure SE_Panel.SetBackground(const Value: SE_Bitmap);
begin
  if (FBackground <> Value) then begin
    if fBackground = nil then
      FBackground := SE_Bitmap.Create (Value)
    else
    FBackground.Assign(Value);
  end;
end;

procedure SE_Panel.Paint;
begin
  inherited;

  if not (csDesigning in ComponentState) then begin
    if fBackground <> nil then begin
      fBackground.Stretch( Width,Height );
      BitBlt(Canvas.Handle, 0, 0, Width, Height, fBackground.Canvas.Handle, 0, 0, SRCCOPY);
    end
    else begin
      Canvas.Brush.Color := Color;
      Canvas.FillRect( Rect(0,0, Width, Height) );
    end;
  end;

end;


end.






