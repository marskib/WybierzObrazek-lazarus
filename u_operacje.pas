unit u_operacje;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Menus, Buttons, LazFileUtils,
  u_parametry, u_sprawdzacz,  u_tmimage, u_ramka,  u_odtwarzacz, uoprogramie, windows;



  const MAX_OBR=50; //maxymalna dozwolona liczba obrazkow - powyzej tego - gruba przesada....; wymog formalnu; operacyjnie stosuję zmienna MAX_OBR_OD

  Type

  TtabSek = array[1..MAX_OBR] of SmallInt; //typ dla tablicy zawierajacej sekwencję (kolejnosc) wyswietlania obrazkow w OD

  { TFOperacje }

  TFOperacje = class(TForm)
    Button1: TButton;
    Button2: TButton;
    BRebuildAll: TButton;
    BPodp: TButton;
    BAgain: TButton;
    BNextCwicz: TButton;
    LNazwa: TLabel;
    SpeedBtnGraj: TSpeedButton;
    TimerNazwa: TTimer;
    TimerKlawisze: TTimer;
    TimerLosuj: TTimer;
    MainMenu1: TMainMenu;
    MenuItem6: TMenuItem;
    OProgramie: TMenuItem;
    Parametry: TMenuItem;
    SLinia: TShape;
    procedure BAgainClick(Sender: TObject);
    procedure BGrajClick(Sender: TObject);
    procedure Naczytaj();
    procedure BNextCwiczClick(Sender: TObject);
    procedure BPodpClick(Sender: TObject);
    procedure BRebuildAllClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure OProgramieClick(Sender: TObject);
    procedure ParametryClick(Sender: TObject);
    procedure SpeedBtnGrajClick(Sender: TObject);
    procedure TimerKlawiszeTimer(Sender: TObject);
    procedure TimerLosujTimer(Sender: TObject);
    procedure TimerNazwaTimer(Sender: TObject);
    procedure TimWzorzecPaint(Sender: TObject);
    procedure UstawEkranStartowy;
    procedure LosujUmiescObrazek();
    procedure RebuildAll();
  private
    { private declarations }
  public
    tabOb   : array[1..MAX_OBR] of TMojImage;  //tablica na obrazki
    TImWzorzec: TMojImage;                        //obrazek-wzorzec na gorze okranu (w OG = Obszar Górny)
    idWylos : Integer;                            //id wylosowanego obrazka
    nrWylos : Integer;                            //numer (index w tablicy tabOb) wylosowanego obrazka
    liczbaObrWKatalogu : Integer;                 //Liczba obrazkow wczytanych z dysku do katalogu
    procedure PokazKlawisze();
    procedure UkryjKlawisze();
    procedure GrajNagrode(opoznienie:SmallInt);
    procedure GrajNagane(opoznienie:SmallInt);
    procedure GrajZle(opoznienie:SmallInt);
    procedure GrajDing(opoznienie:SmallInt);
    function  DajLosowaSekwencje():TtabSek;
    procedure GenerujPojemnikNaWzorzec();
    procedure PokazNazwePodObrazkiem();
  end;



Function skib_InvertColor(const myColor: TColor): TColor; (* Daje kolor 'odwrotny' do zadanego - potrzebne pry rysowaniu ramek widocznych na nieznanym background'dzie *)

var
  FOperacje: TFOperacje;

  Sprawdzacz : TSprawdzacz;      //na sprawdzanie na MouseUp na obrazku, a potem się ten obiekt odpytuje
  Ramka      : TRamka;           //Ramka na polozenie Obrazka; bedzie wystawiac Lapke

CONST
    PELNA_WERSJA = TRUE;         //na etapie kompilacji okreslam czy pelna czy demo
    JESTEM_W_105 = TRUE;        //zeby nie grac, gdy jestem w 1.05
VAR

    MAX_OBR_OD :SmallInt;        //maxymalna dozwolona liczba obrazkow w Obszarze Dolnym (jak za duzo, to dziecko nie da rady...); zalezy tez od PELNA_WERSJA=True/False

    SciezkaZasoby  : string;     //katalog z zasobami w biezacym katalogu programu
    MPlayer : TMediaPlayerSki;   //do odgrywania nagrod

    komciePath,
    oklaskiPath, tadaPath : String;  //sciezki do plikow dzwiekowych

implementation

{$R *.lfm}

{ TFOperacje }

function skib_InvertColor(const myColor: TColor): TColor;
(* Daje kolor 'odwrotny' do zadanego - potrzebne pry rysowaniu ramek widocznych na nieznanym background'dzie *)
Begin
  if myColor = clDefault then
    result := clBlack //doswiadczalnie
  else  //znalezione w Internecie:
    result := TColor(Windows.RGB(255 - GetRValue(myColor), 255 - GetGValue(myColor), 255 - GetBValue(myColor)));
End;


procedure TFOperacje.GenerujPojemnikNaWzorzec();
(* Generuje 'pojemnik' na obrazek-wzorzec na gorze ekranu. *)
(* Nie wypelnia trescia (to gdzie indziej).                *)
Begin
  TImWzorzec := TMojImage.WlasnyCreate_Generic(); //'pojemnik' na obrazek-wzorzec
  TImWzorzec.Parent := FOperacje;
  TImWzorzec.Top    := 30;
End;



procedure TFOperacje.FormShow(Sender: TObject);
Begin
  GenerujPojemnikNaWzorzec(); //powstanie obiekt o nazwie TImWzorzec - niszczony/generowany w kazdym cyklu
  {}
  UstawEkranStartowy();
  (* Obiekty potrzebne do dzialania: *)
  Sprawdzacz := TSprawdzacz.Create();
  Ramka := TRamka.WlasnyCreate(30,30,200,200);  //Ramka do wkladania przez dziecko zgadywanego obrazka
  Ramka.UstawKolorObramowania(FOperacje.Color);
  Ramka.Brush.Color := Ramka.Pen.Color; //na potrzeby WybierzObrazek - zmiana tla Ramki - 2019.09.29
  Ramka.Parent := FOperacje;
  MPlayer := TMediaPlayerSki.WlasnyCreate();
  (**)
  liczbaObrWKatalogu := FParametry.FListBox1.Count;
  Naczytaj(); //naczytanie obrazków+wiele innych
  UkryjKlawisze();
  BPodp.Visible:=FParametry.CBPodp.Checked;
  (**)
End; (* FormShow() *)

procedure TFOperacje.OProgramieClick(Sender: TObject);
begin
  FOprogramie.Top  := (FOperacje.Height - FOprogramie.Height) div 2;
  FOprogramie.Left := (FOperacje.Width  - FOprogramie.Width)  div 2;
  FOprogramie.ShowModal;
end;


procedure TFOperacje.ParametryClick(Sender: TObject);
(* Pokazanie formy FParametry *)
begin
  FParametry.Top := Top + 20;
  FParametry.Left := Left + 8;
  FParametry.ShowModal;
end;


procedure TFOperacje.TimerKlawiszeTimer(Sender: TObject);
(* pokazanie klawiszy nawigacyjnych *)
Begin
  PokazKlawisze();
  TimerKlawisze.Enabled := False;
End;


procedure TFOperacje.TimerLosujTimer(Sender: TObject);
(* Losowanie obrazka, wyswietlenie wylosowanego *)
Begin
  LosujUmiescObrazek();
  BPodp.Visible := FParametry.CBPodp.Checked;
  TimerLosuj.Enabled := False;
End;

procedure TFOperacje.TimerNazwaTimer(Sender: TObject);
(* pokazanie nazwy pod Wzorcem *)
Begin
  PokazNazwePodObrazkiem();
  TimerNazwa.Enabled:=false;
End;



type
  TGraphicControlAccess = class(TGraphicControl)
end;
procedure TFOperacje.TimWzorzecPaint(Sender: TObject);
begin
  inherited Paint();
  with TGraphicControlAccess(TImWzorzec).Canvas do  begin
    Brush.Style := bsClear;
    Pen.Color   := clRed;
    Rectangle(ClientRect);
  end;
end;

procedure TFOperacje.Button1Click(Sender: TObject);
var i:integer;
begin
  for i:=1 to TMojImage.liczbaOb do begin
    tabOb[i].Destroy();
  end;
end;

procedure TFOperacje.RebuildAll();
(* Zniszczenie i Odbudowa wszystkich obrazkow *)
var liczZbO : SmallInt;      //licznosc zbioru obrazkow;
    i,k : Integer;
    Sek : array[1..MAX_OBR] of SmallInt; //na losowa sekwencje pokazywania obrazkow
Begin
  Screen.Cursor:=crHourGlass;
  //likwidacja tego co na górze:
  TImWzorzec.Destructor_Generic();
  //Likwidacja i odbudowa tego co nad dole:
  for i:=1 to TMojImage.liczbaOb do
    tabOb[i].Destroy();

  (************** Kreowanie obrazkow w OD: ***********************************)
  liczZbO:=FParametry.DajLicznoscZbioru(Zbior);
  k:=1;
  for i:=0 to liczbaObrWKatalogu-1 do begin
    if i in Zbior then begin  //kreowanie pojedynczego Obrazka (z wymiartowaniem)
      tabOb[k] := TMojImage.WlasnyCreate_ze_Skalowaniem(FParametry.FListBox1, i, liczZbO);
      k:=k+1;
    end;
  end;


  //Rozlozenie obrazkow na FOperacje:
  //przygotowanie 'sekwencji' w jakiej ma nastapic wyswietlenie
  sek := DajLosowaSekwencje();
  //rozmieszczenie obrazkow:
  TMojImage.RozmiescObrazki_v2(tabOb, sek);
  //Pokazanie na formie:
  for i:=1 to TMojImage.liczbaOb do tabOb[i].Parent := FOperacje;
 (**************** koniec kreowania*************************************)

   Screen.Cursor:=crDefault;
End;  (* RebuildAll *)


procedure TFOperacje.PokazKlawisze();
(* Pokazanie klawiszy po cwiczeniu *)
Begin
  BNextCwicz.Visible:= True;
  BAgain.Visible    := True;
End;

procedure TFOperacje.UkryjKlawisze();
(* Ukrycie klawiszy przed i w trakcie cwiczeniea (= po Zwyciestwie) *)
Begin
  BPodp.Visible := False;
  BNextCwicz.Visible:= False;
  BAgain.Visible    := False;
End;


function TFOperacje.DajLosowaSekwencje(): TtabSek;
(* ******************************************************************************************************************** *)
(* Zwraca tablice 'shadow' dla tabOb, pokazujaca w jakiej kolejnosci w OD maja byc wyswietlane obiekty tabOb (obrazki)  *)
(* np. Result[3]=5 oznacza, że 3-cim obrazkiem w OD ma byc 5-ty element tablicy tabOb (czyli obrazek zawarty w tabOb[5] *)
(* ******************************************************************************************************************** *)
var i:SmallInt;
    los : SmallInt;
    sek : TtabSek; //sekwencja w jakiej ma nastapic wyswietlenie
    ZbDozw : set of 1..MAX_OBR;
Begin
  ZbDozw:=[];
  for i:=1 to TMojImage.liczbaOb do ZbDozw:=ZbDozw+[i];
  for i:=1 to TMojImage.liczbaOb do begin
    Repeat
      los := 1 +Random(TMojImage.liczbaOb);
    Until los in ZbDozw;
    sek[i]:=los;
    ZbDozw:=ZbDozw-[los];
  end;
  Result := sek;
End;   (* Function *)

procedure TFOperacje.BRebuildAllClick(Sender: TObject);
begin
  RebuildAll();
end;

procedure TFOperacje.Naczytaj();
Begin
  UkryjKlawisze();
  RebuildAll();
  LosujUmiescObrazek();
  Sprawdzacz.Resetuj();
  BPodp.Visible := FParametry.CBPodp.Checked;
End;

procedure TFOperacje.BNextCwiczClick(Sender: TObject);
var i:SmallInt;
    sek : TtabSek; //sekwencja w jakiej ma nastapic wyswietlenie
Begin
  //Aktywacja wylaczonych handlerow + 'sprzatanie':
  UkryjKlawisze();
  SpeedBtnGraj.Visible:=False; // j.w.;
  TImWzorzec.Destructor_Generic();   //usuwam obrazkek-wzorzec
  LNazwa.Visible := False;           //znika podpis pod obrazkiem (if any)
  Ramka.JestLapka := False;   //gdyby byla...
  Ramka.Visible   := False;   //j.w.
  Sprawdzacz.Resetuj();
  for i:=1 to TMojImage.liczbaOb do begin
     tabOb[i].inArea := False;
     tabOb[i].WlaczHandlery();
     tabOb[i].JestLapka:=False;   //gdyby 'jakos' byla...
     tabOb[i].Cursor := crDefault;
  end;
  //Przygotowanie 'sekwencji' w jakiej ma nastapic wyswietlenie:
  sek := DajLosowaSekwencje();
  //Wyswietlenie sekwencji obrazkow:
  TMojImage.RozmiescObrazki_v2(tabOb, sek);
  //Wylosowanie i pokazanie wylosowanego w OG (lekkie opoznienie - efekciarstwo ;)):
  TimerLosuj.Enabled := True;
End;

procedure TFOperacje.BAgainClick(Sender: TObject);
(* Powtorzenie cwiczenia (ma byc identycznie, czyli nie przeprowadzam losowania) *)
(* Wszystkie obrazki wracaja na swoje miejsca. Nie dobieram nowych obrazkow(!)   *)
var i : SmallInt;
Begin
  UkryjKlawisze();
  BPodp.Visible := FParametry.CBPodp.Checked; //powinien pozostac
  Sprawdzacz.Resetuj();
  for i:=1 to TMojImage.liczbaOb do begin
    tabOb[i].inArea := False;
    tabOb[i].Left := tabOb[i].getXo();
    tabOb[i].Top  := tabOb[i].getYo();
    tabOb[i].JestLapka := False;    //Jakby byla jakas Lapka, to gaszę
    tabOb[i].WlaczHandlery();
  end;
  Ramka.JestLapka := False;  //gasze, gdyby byla Lapka
End;

procedure TFOperacje.BGrajClick(Sender: TObject);
(* Odegranie nazwy obrazka (if any) *)
var plikWava : string;
Begin
  plikWava := tabOb[idWylos].DajEwentualnyPlikWav();
  MPlayer.Play(SciezkaZasoby+plikWava,0);
End;

procedure TFOperacje.SpeedBtnGrajClick(Sender: TObject);
(* Odegranie nazwy obrazka (if any) *)
var plikWava : string;
Begin
  if not FParametry.CBOdgrywaj.Checked then Exit;
  plikWava := tabOb[idWylos].DajEwentualnyPlikWav();
  MPlayer.Play(SciezkaZasoby+plikWava,0);
End;

procedure TFOperacje.BPodpClick(Sender: TObject);
(* Udzielenie podpowiedzi - wystawienie Lapek na Ramce i wlasciwym Obrazku *)
(* (dziala takze jak switch on/off                                         *)
Begin
  tabOb[nrWylos].JestLapka := not tabOb[nrWylos].JestLapka; //ramka wokol zgadywanego obrazka
  Ramka.JestLapka  := not Ramka.JestLapka; //na gornej Ramce

  With tabOb[nrWylos] do begin
    if JestLapka and (not inArea) then
      PotrzasnijBezWskazu();
  end;
End;

procedure TFOperacje.Button2Click(Sender: TObject);
begin
  if TMojImage.liczbaOb>0 then
    tabOb[TMojImage.liczbaOb].Destroy();
end;

procedure TFOperacje.FormCreate(Sender: TObject);
Begin
  if PELNA_WERSJA then  //ograniczenie 'marketingowe'
    MAX_OBR_OD := 15
  else
    MAX_OBR_OD := 4;
  {}
  nrWylos := -1; //inicjacyjne, zeby sprawdzenie w LosujUmiescObrazek() zadzialalo jak trzeba (True)
End;

procedure TFOperacje.UstawEkranStartowy;
Begin
  FParametry.ComboBoxKolorChange(nil); //wymuszenie defaultowego (=czarnego) koloru FOperacje
  //
  FOperacje.Top := 5; //zeby FOperacje byla w miare na gorze
  //Forma na wiekszosc ekranu :
  FOperacje.Width := Trunc(0.98*Screen.Width);
  FOperacje.Height:= Trunc(0.93*Screen.Height);
  FOperacje.Left  := (Screen.Width-Width) div 2;

  SLinia.Left := 0;
  SLinia.Top  := 1*(FOperacje.Height div 2);
  SLinia.Width:= FOperacje.Width;

  //Pozycjonowanie klawiszy; BAgain jest klawiszem 'wzorcowym' :

  BAgain.Top := SLinia.Top - BAgain.Height-2;;
  BAgain.Left:= FOperacje.Width - BAgain.Width -2;

  BNextCwicz.Height:=BAgain.Height;
  BNextCwicz.Width :=BAgain.Width;

  BPodp.Height:=BAgain.Height;
  BPodp.Width :=BAgain.Width div 3;

  BNextCwicz.Left := FOperacje.Width - BNextCwicz.Width -2;
  BNextCwicz.Top  := BAgain.Top - BAgain.Height -1;

  BPodp.Left := FOperacje.Width - Bpodp.Width -2;
  BPodp.Top  := BNextCwicz.Top - BNextCwicz.Height -1;

  //Zeby TShape nie mrugal (blinking, flickering) za bardzo, kiedy przesuwany :
  FOperacje.DoubleBuffered:=True;
  (**)
  Randomize;
End; (*Procedure*)

procedure TFOperacje.LosujUmiescObrazek();
(* ************************************************************************************ *)
(* Wylosowanie i wyswietlenie obrazka do zgadywania.                                    *)
(* Sposrod obrazkow na dole ekranu losuje jeden i jego kopię umieszcza na gorze ekranu. *)
(* Ewentualne odegranie pliku z nazwa obrazka.                                          *)
(* ************************************************************************************ *)
var x,y : Integer;   //pomocnicze, dla zwiekszenia czytelnosci
    los : SmallInt;  //indeks wylosowanego obrazka
    plikWav : string;    //na ewentualne odegranie nazwy (if any)
    odstep: Integer; //odstep miedzy klawiszem z glosnikiem a ramką na obrazek

Begin
  {Losowanie obrazka ze zmniejszeniem p-stwa wylosowania tego samego:}
  los := 1+ Random(TMojImage.liczbaOb);  //+1 bo Random(x) generuje w przedziale  0=< liczba <x
  if los=nrWylos then //sprawdzenie, czy nie taki sam jak poprzednio wylosowany
    los := 1+ Random(TMojImage.liczbaOb);
  if los=nrWylos then //j.w.
    los := 1+ Random(TMojImage.liczbaOb);
  nrWylos := los;    //poprzednio wylosowany staje sie aktualnie wylosowanym; system-wide - przyda sie...
  {}
  idWylos := tabOb[nrWylos].getIdOb(); //system-wide, przyda sie w innych modulach

  //Pokazanie wylosowanego obrazka w Ramce w OG:
  GenerujPojemnikNaWzorzec(); //powstanie obiekt o nazwie TImWzorzec (niszczony/odnawiany w kazdym cyklu)

  TImWzorzec.Picture := tabOb[nrWylos].Picture;

  TImWzorzec.Proportional:= tabOb[nrWylos].Proportional;
  TImWzorzec.Stretch     := tabOb[nrWylos].Stretch;
  TImWzorzec.Center      := tabOb[nrWylos].Center;

  TImWzorzec.Width  :=  SpeedBtnGraj.Width; // zmiana na potrzeby WybierzObrazek 2019.10.01tabOb[nrWylos].Width;
  TImWzorzec.Height := tabOb[nrWylos].Height;
  TImWzorzec.Left   := FOperacje.Width div 2 - TImWzorzec.Width - 20;

  TImWzorzec.Visible := FALSE;  //->ukrywam - przerobka  WybierzObrazek 2019.09.30

  {nowe 2019.10.30:}
  //Dazymy to tego, zeby 'kompleks' ["BitBtnGraj + Ramka"] lezal centralnie (w poziomie) na Foperacje:
  Ramka.UstalWidthHeight(tabOb[nrWylos]);  //wielkosc Ramki ustalamy na pdst. obrazka, ktory ma do niej trafic
  SpeedBtnGraj.Top   := Ramka.Top;
  SpeedBtnGraj.Height:= Ramka.Height;
  odstep := 1*(SpeedBtnGraj.Width div 2);
  x := (FOperacje.Width - (SpeedBtnGraj.Width + odstep + Ramka.Width)) div 2;
  SpeedBtnGraj.Left := x;
  y :=  TImWzorzec.Top;
  Ramka.PolozNaXY(x+SpeedBtnGraj.Width + odstep, y);
  Ramka.Visible := True;
  SpeedBtnGraj.Visible := True;
  //Dzieki tym 2 'bezsensownym' instrukcom podobiekt Lapka bedzie mial 'bojowe' wspolrzedne - wykorzystywane w funkcki TMojImage.ObrazekJestWOkregu(...) (troche trick...):
  Ramka.JestLapka:=True;
  Ramka.JestLapka:=False;
  //Ewentualne odegranie nazwy wylosowanego obrazka (jesli stowarzyszony plikWav istnieje):
  if not JESTEM_W_105 then begin //nie gram gdy jestem w pracy...
    if FParametry.CBOdgrywaj.Checked then begin
      plikWav := tabOb[idWylos].DajEwentualnyPlikWav();  //nazwa Potencjalnego(!) pliku
      MPlayer.Play(SciezkaZasoby+plikWav,1);             //odegra, albo cisza :)
    end;
  end;

  //Podpis pod obrazkiem (jego nazwa):
  if Fparametry.CBNazwa.Checked then
    TimerNazwa.Enabled:=True
  else
    LNazwa.Visible:=False;
End; (* Procedure *)


procedure TFOperacje.GrajNagrode(opoznienie:SmallInt);
(* ************************************************************* *)
(* Odegranie (losowej) nagrody z podkatalogu 'Zasoby/komentarze' *)
(* Par. 'opoznienie' - ile opoznic granie (wielokrotnosc 750 ms) *)
(* ************************************************************* *)
var los : Integer;
    sl  : TStringList;
    plik: String;
    liczbaPlikow:Integer;
Begin
  if JESTEM_W_105 then EXIT; //nie gram gdy jestem w pracy...
  if FParametry.RBNoAward.Checked then begin
    Exit;
  end;
  if FParametry.RBOkrzyk.Checked then begin
    MPlayer.Play(tadaPath,opoznienie);
    Exit;
  end;
  if FParametry.RBOklaski.Checked then begin
    MPlayer.Play(oklaskiPath,opoznienie);
    Exit;
  end;
  IF FParametry.RBPochwala.Checked then begin
    sl := FindAllFiles(komciePath, '0*-*.wav', True); //taki wzorzec nazwy przyjalem dla plikow z nagroda - np. '03-dobrze-brawo.wav'
    Try
      liczbaPlikow:=sl.Count;
      los := 1+Random(liczbaPlikow);
      try     //musi byc wewnetrzny try z p ustym except, bo jak nie ma plikow w sl, to zgalaszany jest wyjatek, ktory przebija sie do usera...
        plik:= sl.Strings[los-1]; // -1 bo indeksowanie jest od 0 zera
        MPlayer.Play(plik,opoznienie);
      except
      end;
    Finally
      sl.Free; //BARDZO WAZNE !!!!!! bo memory leaks
    End;
    Exit;
  End;  //IF
End; (* Procedure *)


procedure TFOperacje.GrajNagane(opoznienie:SmallInt);
(* Odegranie, ze zle - jesli polozy w Ramce niewlasciwy obrazek *)
var plik:string;
Begin
  if JESTEM_W_105 then Exit; //nie gram gdy jestem w pracy...
  Case Random(2) of          //zakladam, ze na 'naganę' będą tylko 2 pliki
    0 : plik:= komciePath+'nie-e2.wav';
    1 : plik:= komciePath+'nie-e-probuj-dalej-2.wav';
  End;
  MPlayer.Play(plik,opoznienie);
End;

procedure TFOperacje.GrajZle(opoznienie:SmallInt);
Begin
  MPlayer.Play(komciePath+'zle.wav',opoznienie);
End;

procedure TFOperacje.GrajDing(opoznienie:SmallInt);
Begin
  MPlayer.Play(komciePath+'ding.wav',opoznienie);
End;


procedure TFOperacje.PokazNazwePodObrazkiem();
(* Pod Ikoną z glosnikiem pokazuje polecenie z nim zwiazane (=nazwe obrazka) *)
var rob:string;
Begin
  With SpeedBtnGraj do begin
    rob:=ExtractFileNameOnly( FOperacje.tabOb[FOperacje.nrWylos].DajEwentualnyPlikWav() ); //daje z roszerz. *.wav, wiec ucinam
    LNazwa.Caption := rob;
    LNazwa.Top := Top+Height+20;
    LNazwa.Visible:=True;  //Visible MUSI byc przed LNazwa.Width, bo inaczej źle zmierzy szerokosc LNazwa'y...
    LNazwa.Left:= Left-((LNazwa.Width div 2) - (Width div 2));
  End;
End; (* Procedure *)



Begin
  //Okreslenie polozenia plikow z nagrodami:
  komciePath := GetCurrentDir(*UTF8*)+'\Zasoby\komentarze\';
  oklaskiPath:= komciePath+'oklaski.wav';
  //dzwiek 'tada':
  tadaPath   := oklaskiPath;
  if FileExists(*UTF8*)('C:\Windows\Media\tada.wav') then
    tadaPath := 'C:\Windows\Media\tada.wav'
  else
  if FileExists(*UTF8*)('D:\Windows\Media\tada.wav') then
    tadaPath := 'D:\Windows\Media\tada.wav'  //dalej nie szukam, zostaje tadaPath=oklaskiPath
End.

