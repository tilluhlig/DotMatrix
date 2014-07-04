.include "m644Pdef.inc"


.def temp = r16
.def temp2 = r17
.def temp3 = r18
.def temp4 = r19
.def temp5 = r20
.def temp6 = r21
.def temp7 = r22
.def temp8 = r23

.equ XTAL = 20000000
.equ F_CPU = 20000000                        ; Systemtakt in Hz
.equ BAUD  =  28800// 19200 // 9600         //38400                     ; Baudrate
.equ MATRIZEN = 20 // 127 Matrizen möglich  (bis 400 getestet, ohne probleme)

.MACRO SetZ ;(Adresse)
        ldi     ZL, LOW(@0)
        ldi     ZH, HIGH(@0)
.ENDMACRO

.MACRO SetX ;(Adresse)
        ldi     XL, LOW(@0)
        ldi     XH, HIGH(@0)
.ENDMACRO

.MACRO SetY ;(Adresse)
        ldi     YL, LOW(@0)
        ldi     YH, HIGH(@0)
.ENDMACRO

.MACRO INPUT
  .if @1 < 0x40
	in	@0, @1
  .else
  	lds	@0, @1
  .endif
.ENDMACRO

.MACRO OUTPUT
  .if @0 < 0x40
	out	@0, @1
  .else
  	sts	@0, @1
  .endif
.ENDMACRO

.MACRO PIXEL ; DataRegister, Arbeitsregister (muss 0 sein)
    mov @1, @0 // 1
	andi @1, 0b00000001 // 1
	out PORTB, @1 // 1
	lsr @0 // 1	
	//NOP
	sbi PORTB, 1 // 2
	//NOP
.ENDMACRO ; == 6 Takte

.MACRO DATEN_EINLESEN

.ENDMACRO

.MACRO RESET_MATRIX
// Schieberegister Initialisieren
ldi temp4, 0
out PORTA, temp4

ldi temp, low(MATRIZEN*16)
sbi PORTB, 0
ldi temp2, high(MATRIZEN*16)+1

schleife2:

schleife:
cbi PORTB,1
sbi PORTB,1

dec temp
brne schleife

cpi temp2, 0
breq endschleife2

ldi temp, 0
dec temp2
brne schleife2
endschleife2:

sbi PORTB,2
cbi PORTB,2
.ENDMACRO

; Berechnungen
.equ UBRR_VAL   = ((F_CPU+BAUD*8)/(BAUD*16)-1)  ; clever runden
.equ BAUD_REAL  = (F_CPU/(16*(UBRR_VAL+1)))      ; Reale Baudrate
.equ BAUD_ERROR = ((BAUD_REAL*1000)/BAUD-1000)  ; Fehler in Promille

.if ((BAUD_ERROR>10) || (BAUD_ERROR<-10))       ; max. +/-10 Promille Fehler
  .error "Systematischer Fehler der Baudrate grösser 1 Prozent und damit zu hoch!"
  
.endif 
 
.org 0x0000
rjmp reset


reset:
          ldi      temp, HIGH(RAMEND)     ; Stackpointer initialisieren
          out      SPH, temp
          ldi      temp, LOW(RAMEND)
          out      SPL, temp
/*
 ; Baudrate einstellen
    ldi     temp, HIGH(UBRR_VAL)
    sts     UBRR0H, temp
    ldi     temp, LOW(UBRR_VAL)
    sts     UBRR0L, temp*/

ldi temp, 0xFF
out DDRA, temp
out DDRB, temp

ldi temp, 0x00
out PORTA, temp // Ebenen (8)  1 = AN, 0 = AUS

ldi temp, 0x00
out PORTB, temp // Schieberegister B0 (1= Aus, 0 = An), B1 (Taktsignal)

//dot:

//rjmp dot
/*
	  ;RS232 initialisieren
	ldi r16, LOW(UBRR_VAL)
	sts UBRR0L,r16
	ldi r16, HIGH(UBRR_VAL)
	sts UBRR0H,r16
	ldi r16, (1<<UMSEL0)|(3<<UCSZ00) ; Frame-Format: 8 Bit /// ???
	sts UCSR0C,r16

	lds temp, UCSR0B
	sbr temp, RXEN0			; RX (Empfang) aktivieren
	sbr temp, TXEN0			; TX (Senden)  aktivieren
sts UCSR0B, temp
*/


Reset_Matrix

// Arbeitsspeicher initialisieren (alles 1)
SetZ DATA
//SetX DATA2
ldi temp, low(MATRIZEN*16)

ldi temp3,0b11111110
ldi temp2, high(MATRIZEN*16)+1
ldi temp5, 0
schleife4:

schleife3:

// Zu Testzwecken ist dieses Muster drin
//mov temp4, temp3
//andi temp4, 0b00000001
//cpi temp4, 0
//breq is0
//ldi temp4, 0b10101010//01010101
mov temp4, temp3
st Z+,  temp4

inc temp5
cpi temp5, MATRIZEN*2
brne no_8
ldi temp5, 0

sec
rol temp3
brcs no_ret
subi temp3, 1
no_ret:

no_8:

//st X+,  temp4
/*rjmp overis0
is0:
ldi temp4, 0b01010101
st Z+,  temp4
//st X+,  temp4
overis0:*/

//inc temp3

dec temp
brne schleife3

ldi temp, 0
dec temp2
brne schleife4


do:
// Hauptschleife

// Ausgabe
SetZ DATA // welcher Speicher soll genutzt werden?
ldi temp2, 0 // muss so bleiben, kann sich ändern
ldi temp3, 0b00000001 // Das register zur Auswahl der Ebenen
ldi temp4, 0 // ist immer 0
ldi temp5, 0

Zeichnen:


ldi temp7, low(MATRIZEN*2)

start:
ld temp, Z+ // lade nächsten Datensatz
//ldi temp, 0b11111101
PIXEL temp, temp2
PIXEL temp, temp2
PIXEL temp, temp2
PIXEL temp, temp2
PIXEL temp, temp2
PIXEL temp, temp2
PIXEL temp, temp2
PIXEL temp, temp2
dec temp7
brne start

// nun die Daten ausgeben
// schalte alle Ebenen ab
out PORTA, temp4

// 64 mal NOP // Transistoren sind träge
ldi temp5, 21
NOPs:
dec temp5
brne NOPs

// Daten in den Schieberegistern sichtbar machen
sbi PORTB, 2

// schalte Ebene x ein
out PORTA, temp3

// 256 mal NOP // Transistoren sind träge
ldi temp5, 0
NOPs2:
dec temp5
brne NOPs2

lsl temp3
breq no_Zeichnen
rjmp Zeichnen
no_Zeichnen:

 rjmp do
 
.DSEG ; Arbeitsspeicher
DATA:   .BYTE  MATRIZEN*16
DATA2:   .BYTE  MATRIZEN*16 
