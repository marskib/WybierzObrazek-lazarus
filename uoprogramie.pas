unit uoprogramie;

{$mode objfpc}{$H+}

interface

uses
Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
StdCtrls, ExtCtrls,
LCLProc, LazHelpHTML, UTF8Process;

type

  { TFOprogramie }

  TFOprogramie = class(TForm)
    Button1: TButton;
    Image1: TImage;
    LWebLink1: TLabel;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure Image1MouseEnter(Sender: TObject);
    procedure Image1MouseLeave(Sender: TObject);
    procedure LWebLink1MouseEnter(Sender: TObject);
    procedure LWebLink1MouseLeave(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  FOprogramie: TFOprogramie;

implementation
uses u_operacje;

{ TFOprogramie }

procedure TFOprogramie.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TFOprogramie.FormCreate(Sender: TObject);
Begin
  //Rozny naglowek w zaleznosci od wersji pelna/demo
  if not PELNA_WERSJA then begin
    Memo1.Lines[0] := 'WybierzObrazek - wersja 1.0 (demonstracyjna)';
    Memo1.Height := Memo1.Height - 40;
  end
  else begin
    Memo1.Lines[0] := 'WybierzObrazek - wersja 1.0 (pełna)';
    Memo1.Append('');
    Memo1.Append('Rozpowszechnianie programu bez zgody autora stanowi naruszenie praw autorskich.');
    FOperacje.Caption := 'WybierzObrazekPlus';
  end;
End;


procedure TFOprogramie.Image1Click(Sender: TObject);
var
  v: THTMLBrowserHelpViewer;
  BrowserPath:Ansistring; BrowserParams: Ansistring;
  p: LongInt;
  URL: String;
  BrowserProcess: TProcessUTF8;
begin
  v:=THTMLBrowserHelpViewer.Create(nil);
  try
    v.FindDefaultBrowser(BrowserPath,BrowserParams);
    debugln(['Path=',BrowserPath,' Params=',BrowserParams]);

    URL:='http://www.AutyzmSoft.pl';

    if PELNA_WERSJA then
        URL:='http://www.AutyzmSoft.pl';

    p:=System.Pos('%s', BrowserParams);
    System.Delete(BrowserParams,p,2);
    System.Insert(URL,BrowserParams,p);

    // start browser
    BrowserProcess:=TProcessUTF8.Create(nil);
    try
      BrowserProcess.CommandLine:=BrowserPath+' '+BrowserParams;
      BrowserProcess.Execute;
    finally
      BrowserProcess.Free;
    end;
  finally
    v.Free;
  end;
End;

procedure TFOprogramie.Image1MouseEnter(Sender: TObject);
begin
    Image1.Cursor:= crHandPoint;
end;

procedure TFOprogramie.Image1MouseLeave(Sender: TObject);
begin
    Image1.Cursor:= crDefault;
end;

procedure TFOprogramie.LWebLink1MouseEnter(Sender: TObject);
begin
  LWebLink1.Cursor:= crHandPoint;
end;

procedure TFOprogramie.LWebLink1MouseLeave(Sender: TObject);
begin
  LWeblink1.Cursor:= crDefault;
end;

initialization
  {$I uoprogramie.lrs}

end.


