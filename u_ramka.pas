unit u_ramka;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, Graphics, LCLIntf, windows, u_tmimage, u_Lapka;

type

  { TRamka }


  (* Ramka po prawej stronie ikony-prostokata z glosnikiem. Do tej Ramki dziecko wklada zgadywany obrazek *)

  TRamka = class(TShape)

    constructor WlasnyCreate(xlg,ylg,wys,szer:SmallInt);
    public procedure UstawKolorObramowania(JakieJestTlo : TColor);       //ustawia kolor obramowania Ramki i Lapki
    public procedure PolozNaXY(X,Y:Integer);                //zamiast Left:=x, Top:=y
    public procedure UstalWidthHeight(obrZgad:TMojImage);   //j.w.
    public procedure MrugajLapka(Sender:TObject);   //UWAGA - parametr formalny (typu TObject) MUSI byc, bo inaczej kompilator nie puszcza przypisywania handlera (sygnatura metody sztywna?)
    public procedure PrzestanMrugacLapka();
    public procedure PonowMruganieLapka();

    //Na mechanizm wystawiania Lapki;
    private FJestLapka : Boolean;
    procedure setJestLapka(aValue: Boolean);
    public property JestLapka : Boolean read FJestLapka write setJestLapka;

    //Szerokosc Lapki (inaczej Lapka.Width, ale Lapka nie widoczna na zewnątrz, wiec przez property)
    private FLW : SmallInt;
    function getLW:SmallInt;  //akronim: getLapkaWidth()
    public property LW : SmallInt read getLW;

    //Wysokosc Lapki (inaczej Lapka.Height, ale Lapka nie widoczna na zewnątrz, wiec przez property)
    private FLH : SmallInt;
    function getLH:SmallInt;
    public property LH : SmallInt read getLH;

    //Top Lapki (inaczej Lapka.Top, ale Lapka nie widoczna na zewnątrz, wiec przez property)
    private FLT : SmallInt;
    function getLT:SmallInt;
    public property LT : SmallInt read getLT;

    //Left Lapki (inaczej Lapka.Left, ale Lapka nie widoczna na zewnątrz, wiec przez property)
    private FLL : SmallInt;
    function getLL:SmallInt;
    public property LL : SmallInt read getLL;

    //Srodek i promien okregu Lapki, ale Lapka nie widoczna na zewnątrz, wiec przez property)
    private FLXo : SmallInt;
    function getLXo:SmallInt;
    public property LXo : SmallInt read getLXo;

    private FLYo : SmallInt;
    function getLYo:SmallInt;
    public property LYo : SmallInt read getLYo;

    private FLR : SmallInt;
    function getLR:SmallInt;
    public property LR : SmallInt read getLR;


    private
      Lapka1,Lapka2 : TLapka; //Lapka/Podpowiedz wystawiana przez Ramke (jesli jest to wlasciwy obrazek przebywajacy w OG)
      //na potrzebt WybierzObrazek - 2 (dwie) Lapki ("biala" i "czarna", żeby bylo widać na bialym tle ramki na obrazek)

  End; //Class

implementation
uses u_operacje, u_parametry;

{ TRamka }

procedure TRamka.setJestLapka(aValue: Boolean);
var Lszer, Lwys : integer; //wysokosc i szerokosc LApki
Begin
  if aValue=FJestLapka then Exit;
  FJestLapka := aValue;
  if FJestLapka then begin //Zaczynamy mrugac Lapka
    if (Lapka1.Parent = Nil) then begin
      Lapka1.Parent := Self.Parent; //zeby byla zobrazowana, jesli nie ma jeszcze Parenta; {parentem Self-a jest FOperacje)
      Lapka2.Parent := Self.Parent; //jw
    end;
    Lapka1.UstawKolorObramowania(Self.Parent.Color);

    //UWAGA - ponizej ustawic na invert samego siebie - zeby bylo widac na tle Ramki:
    Lapka2.UstawKolorObramowania(Self.Brush.Color);

     //Ramkę wysylam w tlo, zeby bylo na niej widac lapke 2020-01-04:
     //doswiadczalnie - te sama instrukcje trzeba jeszcze poworzyc w TMmimage.coNaMouseUP - bo nie ma efektu w pewbycgh warunkach....
     Self.SendToBack();

    Lszer := 8*(min(Height,Width) div 10);
    Lwys  := Lszer;
    Lapka1.PolozNaXY_i_Wymiaruj(Left-(Lszer div 2)+10,    Top-(Lwys div 2)+10,    Lszer ,     Lwys);
    Lapka2.PolozNaXY_i_Wymiaruj(Left-(Lszer div 2)+10 -1, Top-(Lwys div 2)+10 -1, Lszer+2*1 , Lwys+2*1);
    Lapka1.Mrugaj();
    Lapka2.Mrugaj();
  end
  else begin      //chowamy Lapke
    Lapka1.Zgas();
    Lapka2.Zgas();
  end;
End;

function TRamka.getLW: SmallInt;
(* Zwraca szerokosc Lapki posiadanej przez Ramke *)
Begin
 Result := Lapka1.Width;
End;


function TRamka.getLH: SmallInt;
Begin
  Result := Lapka1.Height;
End;


function TRamka.getLT: SmallInt;
Begin
  Result := Lapka1.Top;
End;


function TRamka.getLL: SmallInt;
Begin
  Result := Lapka1.Left;
End;

function TRamka.getLXo: SmallInt;
Begin
  with Lapka1 do
    Result := Left + (Width div 2);
End;

function TRamka.getLYo: SmallInt;
Begin
  with Lapka1 do
    Result := Top + (Height div 2);
End;

function TRamka.getLR: SmallInt;
Begin
  with Lapka1 do
    Result := LW div 2;  //zakladam, ze to okrąg
End;


constructor TRamka.WlasnyCreate(xlg,ylg,wys,szer:SmallInt);
Begin
  inherited Create(nil);
  Self.Left := xlg;
  Self.Top  := ylg;
  Self.Height := wys;
  Self.Width  := szer;
  Self.Brush.Style:=bsClear; //zeby widoczne byl baclground
  //dawniej: Self.Pen.Color := InvertColor(Brush.Color); //albo: Self.Pen.Color := clRed;  bo czerwony pasuje do wszystkiego...
  {}
  Lapka1 := TLapka.WlasnyCreate(stCircle); //Lapka 'Ramkowa' powinna byc okregiem (uzgodniono z Konsultantem)
  Lapka2 := TLapka.WlasnyCreate(stCircle); //na potrzeby WybierzObrazek -2-ga lapka, bedzie inny kolor, zeby lepiej widoczna na tle miejsca na obrazek 2019.09.27
End;


procedure TRamka.MrugajLapka(Sender: TObject);
(* Mrugamy wystawiona lapka; wywolywana na onTimer *)
Begin
  //Try zabezpiecza przed sytuacja kiedy probujemy mrugac lapka, a obiektu juz nie ma -

  Try
   if Lapka1.Pen.Style = psDot then begin
     Lapka1.Pen.Style := psDash;
     Lapka2.Pen.Style := psDash;
   end
   else begin
     Lapka1.Pen.Style := psDot;
     Lapka2.Pen.Style := psDot;
   end;
  Except
  End;

End;  (* MrugajLapka *)

procedure TRamka.PrzestanMrugacLapka();
Begin
 Self.Lapka1.NieMrugaj();
 Self.Lapka2.NieMrugaj();
End;

procedure TRamka.PonowMruganieLapka();
Begin
  Self.Lapka1.WznowMruganie();
  Self.Lapka2.WznowMruganie();
End;

procedure TRamka.UstawKolorObramowania(JakieJestTlo: TColor);
(* Kolor odwrotny niz tlo, zeby mozna bylo cos widziec... *)
Begin
  Self.Pen.Color   := skib_InvertColor(JakieJestTlo);
  Lapka1.Pen.Color := Self.Pen.Color;
  //Lapka 2 - przeciwna nie do tla Formy, ale do tla Ramki, czyli jak tlo Formy... 2019.12.25 :
  //mozna tak: Lapka2.Pen.Color := JakieJestTlo;
  {mozna tak (b.elegancko):}
  Lapka2.Pen.Color := skib_InvertColor(Self.Pen.Color);
  {koniec 2019.12.25}

End;

procedure TRamka.PolozNaXY(X, Y: Integer);
Begin
  Self.Left := X;
  Self.Top  := Y;
End;

procedure TRamka.UstalWidthHeight(obrZgad:TMojImage);
(* Uzywana, zeby dostosowac ramkę do wymiarow zgadywanego Obrazka *)
Begin
  Self.Width :=obrZgad.Width;
  Self.Height:=obrZgad.Height;
  //Wymuszenie dostosowania wymiarow Lapki do nowej szerokosci Ramki:
  if JestLapka then begin
     JestLapka:=False;
     JestLapka:=True;
  end;
End;



end.

