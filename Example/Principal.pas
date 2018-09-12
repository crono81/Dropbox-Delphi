unit Principal;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DropBox, StdCtrls, IdBaseComponent, IdIntercept, IdLogBase,
  IdLogEvent, Grids;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    IdLogEvent1: TIdLogEvent;
    Edit1: TEdit;
    Label1: TLabel;
    Button3: TButton;
    Button4: TButton;
    StringGrid1: TStringGrid;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure IdLogEvent1Received(ASender: TComponent; const AText,
      AData: String);
    procedure IdLogEvent1Sent(ASender: TComponent; const AText,
      AData: String);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    sToken: string;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var Dropbox: TDropbox;
    sTokenL: TStringList;
begin
  Dropbox := TDropbox.Create;
  sTokenL := TStringList.Create;
  Dropbox.AppKey := 'xxxxxxxxxxxxxxx';//You app key here
  Dropbox.RedirectURI := 'http://localhost';//This must be the same as you configured in dropbox
  Dropbox.AuthorizeApp;
  sToken := Dropbox.Token;
  Edit1.Text := sToken;
  sTokenL.Add(sToken);
  sTokenL.SaveToFile('token.txt');
  sTokenL.Free;
  Dropbox.Free;
end;

procedure TForm1.Button2Click(Sender: TObject);
var Dropbox: TDropbox;
    List: TListResultArray;
    i, j: integer;
begin
  Dropbox := TDropbox.Create;
  //Dropbox.IdLogEvent := IdLogEvent1;//Enable this line to catch requests (for debug purposes)
  if sToken <> '' then
    list := Dropbox.ListDirectory('', sToken)//empty string means the root directory
  else if Edit1.Text <> '' then
    list := Dropbox.ListDirectory('', Edit1.Text);
  for i := 0 to StringGrid1.ColCount - 1 do
    for j := 1 to StringGrid1.RowCount - 1 do
      StringGrid1.Cells[i, j] := '';
  StringGrid1.RowCount := 2;
  for i := 0 to length(List) - 1 do begin
    StringGrid1.Cells[0, i + 1] := IntToStr(i + 1);
    StringGrid1.Cells[1, i + 1] := list[i].tag;
    StringGrid1.Cells[2, i + 1] := list[i].name;
    StringGrid1.Cells[3, i + 1] := list[i].id;
    StringGrid1.Cells[4, i + 1] := list[i].content_hash;
    StringGrid1.Cells[5, i + 1] := list[i].client_modified;
    StringGrid1.RowCount := StringGrid1.RowCount + 1; 
  end;
  Dropbox.Free;
end;

procedure TForm1.IdLogEvent1Received(ASender: TComponent; const AText,
  AData: String);
begin
  ShowMessage(AData);
end;

procedure TForm1.IdLogEvent1Sent(ASender: TComponent; const AText,
  AData: String);
begin
  ShowMessage(AData);
end;

procedure TForm1.Button3Click(Sender: TObject);
var Dropbox: TDropbox;
begin
  Dropbox := TDropbox.Create;
  //Dropbox.IdLogEvent := IdLogEvent1;//Enable this line to catch requests (for debug purposes)
  if sToken <> '' then begin
    if Dropbox.Download('', 'remote_file.txt', 'local_file.txt', sToken) then begin
      ShowMessage('File downloaded');
    end;
  end else if Edit1.Text <> '' then begin
    if Dropbox.Download('', 'remote_file.txt', 'local_file.txt', Edit1.Text) then begin
      ShowMessage('File downloaded');
    end;
  end;
  Dropbox.Free;
end;

procedure TForm1.Button4Click(Sender: TObject);
var Dropbox: TDropbox;
begin
  Dropbox := TDropbox.Create;
  //Dropbox.IdLogEvent := IdLogEvent1;//Enable this line to catch requests (for debug purposes)
  if sToken <> '' then begin
    if Dropbox.Upload('', 'remote_file.txt', 'local_file.txt', sToken) then begin
      ShowMessage('File uploaded');
    end;
  end else if Edit1.Text <> '' then begin
    if Dropbox.Upload('', 'remote_file.txt', 'local_file.txt', Edit1.Text) then begin
      ShowMessage('File uploaded');
    end;
  end;
  Dropbox.Free;
end;

procedure TForm1.FormShow(Sender: TObject);
var sTokenL: TStringList;
begin
  if FileExists('token.txt') then begin
    sTokenL := TStringList.Create;
    sTokenL.LoadFromFile('token.txt');
    Edit1.Text := sTokenL[0];
    sTokenL.Free;
  end;
end;

end.
