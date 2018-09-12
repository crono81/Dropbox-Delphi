program DemoAPIDropbox;

uses
  Forms,
  Principal in 'Principal.pas' {Form1},
  Dropbox in 'Dropbox.pas',
  uLkJSON in 'uLkJSON.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
