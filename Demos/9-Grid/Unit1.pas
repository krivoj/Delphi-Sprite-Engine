unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Generics.Collections ,Generics.Defaults, DSE_theater, DSE_GRID, DSE_Bitmap, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    SE_Grid1: SE_Grid;
    SE_Grid2: SE_Grid;
    Button7: TButton;
    procedure FormCreate(Sender: TObject);
    procedure SE_Grid1GridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer;
      Sprite: SE_Sprite);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure SE_Grid2GridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer;
      Sprite: SE_Sprite);
    procedure Button7Click(Sender: TObject);
  private
    { Private declarations }
    procedure reset;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  SE_grid1.ClearData;
  SE_grid2.ClearData;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  SE_grid1.RemoveRow(3);
  SE_grid2.RemoveRow(3);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  SE_grid1.RemoveColumn(1);
  SE_grid2.RemoveColumn(1);

end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  SE_grid1.AddRow;
  SE_grid2.AddRow;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  SE_grid1.AddColumn;
  SE_grid2.AddColumn;

end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  se_grid1.Columns[1].Width :=  se_grid1.Columns[1].Width + 20;
  se_grid1.Columns[2].Width :=  se_grid1.Columns[2].Width + 20;
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  Reset;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Reset;

end;
procedure TForm1.reset;
var
  c,r: Integer;
  bmp: SE_Bitmap;
begin
  // in questo ordine:
  se_grid1.ClearData;

  se_grid1.DefaultColWidth:= 100;
  se_grid1.DefaultRowHeight:= 32;

  se_grid1.ColCount :=3;
  se_grid1.RowCount :=8;

  for c := 0 to se_grid1.ColCount -1 do begin
    for r := 0 to se_grid1.RowCount -1 do begin
      se_grid1.Cells[c,r].BackColor := clNavy;
    end;
  end;

  se_grid1.Columns[0].Width := 120;
  se_grid1.Rows[3].Height := 60;

  bmp:= SE_Bitmap.create ( SE_grid1.Columns[2].Width,SE_grid1.Rows[2].Height);
  bmp.LoadFromFileBMP( '..\!media\ball1.bmp'  );
  se_grid1.AddSE_Bitmap ( 2,2,4, bmp, true );
  se_grid1.AddSE_Bitmap ( 2,3,2, bmp, true );
  bmp.Free;


  se_grid2.ClearData;
  se_grid2.DefaultColWidth:= 100;
  se_grid2.DefaultRowHeight:= 32;

  se_grid2.ColCount :=3;
  se_grid2.RowCount :=8;

  for c := 0 to se_grid2.ColCount -1 do begin
    for r := 0 to se_grid2.RowCount -1 do begin
      se_grid2.Cells[c,r].BackColor := clNavy;
    end;
  end;

  se_grid2.Columns[0].Width := 120;
  se_grid2.Rows[3].Height := 60;

  bmp:= SE_Bitmap.create ( SE_grid2.Columns[2].Width,SE_grid2.Rows[2].Height);
  bmp.LoadFromFileBMP( '..\!media\ball1.bmp'  );
  se_grid2.AddSE_Bitmap ( 2,2,4, bmp, true );
  se_grid2.AddSE_Bitmap ( 2,3,2, bmp, true );
  se_grid2.AddProgressBar (1,2, 50, clGreen, pbStandard );
  se_grid2.Cells[1,2].ProgressBarShowPercent := true;
  bmp.Free;
end;
procedure TForm1.SE_Grid1GridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer;
  Sprite: SE_Sprite);
begin
  SE_grid1.Cells[CellX,CellY].FontColor:= clRed;
  SE_grid1.Cells[CellX,CellY].Text := inttostr(cellx) +':'+inttostr(celly);
  SE_grid1.Cells[CellX,CellY].CellAlignmentH := HCenter;
  SE_grid1.Cells[CellX,CellY].CellAlignmentV := VCenter;

end;

procedure TForm1.SE_Grid2GridCellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; CellX, CellY: Integer;
  Sprite: SE_Sprite);
begin
  SE_grid2.Cells[CellX,CellY].FontColor:= clYellow;
  SE_grid2.Cells[CellX,CellY].Text := inttostr(cellx) +':'+inttostr(celly);
  SE_grid2.Cells[CellX,CellY].CellAlignmentH := Hright;
  SE_grid2.Cells[CellX,CellY].CellAlignmentV := VCenter;

end;

end.
