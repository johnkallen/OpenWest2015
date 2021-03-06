CON
  _clkmode = xtal1+pll16x
  _xinfreq = 5_000_000

  _dopin = 3   'miso
  _clkpin = 2
  _dipin = 4   'mosi
  _cspin = 5
  _cdpin = -1 ' -1 if unused.
  _wppin = -1 ' -1 if unused.
  _rtcres1 = -1 ' -1 always.
  _rtcres2 = -1 ' -1 always.
  _rtcres3 = -1 ' -1 always.

  lt = 800  'buffer /400 bytes optimo
  head = 54   'tama�o head BMP

  nRESET= 8
  RS    = 9 'D/C
  nCS   = 7
  MOSI  = 10
  SCLK  = 11
  MISO  = 12


OBJ
  fat0          : "SD-MMC_FATEngine.spin"
  disp          : "ILI9341-spi"

VAR
  byte temp1[lt],temp2[lt]
  long maxi, entry
  word lx,ly, top

pub main  | i
  disp.Start (nRESET, nCS, RS, MOSI, SCLK)

  fat0.fatEngineStart( _dopin, _clkpin, _dipin, _cspin, _wppin, _cdpin, _rtcres1, _rtcres2, _rtcres3)
  fat0.mountPartition(0)
  fat0.changeDirectory(string("img"))


  disp.SetColours ($0, $FFFF)
  disp.ClearScreen

  repeatImage

pub repeatImage | i
  fat0.listEntries("W")
  repeat while( entry := fat0.listEntries("N") )
    ifnot( fat0.listIsDirectory or fat0.listIsHidden )
      headBMP(0,true, entry)
      waitcnt (cnt + clkfreq*2)
  repeatImage

pub headBMP(x,y,puntero)|xi,yi,padd,ltr
  fat0.openFile(puntero, "R")
  fat0.readdata(@temp1,head)

  lx:=byte[@temp1][18]+byte[@temp1][19]*256
  ly:=byte[@temp1][22]+byte[@temp1][23]*256

  padd:=4-((lx*3)//4)
  if padd==4
    padd:=0

  ltr:=(lt/(lx*3+padd) *(lx*3+padd))
  ltr:=((lt-ltr)/3)*3+ltr

  yi:=y+ly-1
  xi:=x

  if x==true or y==true or x+lx>320 or yi>240
    xi:=(320-lx)/2           'centro foto
    yi:=239-(240-ly)/2       'centro foto

  disp.BMPinf(xi,yi,lx,ly)

  maxi:=(lx*ly)*3+padd*lx
  maxi/=ltr
  repeat maxi/2 +1
    fat0.readdata(@temp1,ltr)
    disp.SendBMP(@temp1,ltr)
    fat0.readdata(@temp2,ltr)
    disp.SendBMP(@temp2,ltr)
  fat0.closefile


pri drawdec(possx,possy,value,t)| i, zz

  if value < 0
    -value
    if t==0
      disp.drawcharsmall(possx,possy,"-")
      possx+=8
    else
      disp.drawchar(possx,possy,"-")
      possx+=16

  i := 1_000_000_000
  zz~

  repeat 10
    if value => i
      if t==0
        disp.drawcharsmall(possx,possy,value / i + "0")
        possx+=8
      else
        disp.drawchar(possx,possy,value / i + "0")
        possx+=16
      value //= i
      zz~~
    elseif zz or i == 1
      if t==0
        disp.drawcharsmall(possx,possy,"0")
        possx+=8
      else
        disp.drawchar(possx,possy,"0")
        possx+=16
    i /= 10
