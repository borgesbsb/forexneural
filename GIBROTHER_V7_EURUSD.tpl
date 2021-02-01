<chart>
id=132515651229294851
symbol=EURUSD
description=Euro vs US Dollar
period_type=1
period_size=1
digits=5
tick_size=0.000000
position_time=1610348400
scale_fix=0
scale_fixed_min=1.204000
scale_fixed_max=1.219300
scale_fix11=0
scale_bar=0
scale_bar_val=1.000000
scale=8
mode=1
fore=0
grid=0
volume=1
scroll=1
shift=1
shift_size=10.018904
fixed_pos=0.000000
ticker=1
ohlc=0
one_click=1
one_click_btn=1
bidline=1
askline=1
lastline=1
days=1
descriptions=0
tradelines=1
tradehistory=1
window_left=96
window_top=96
window_right=1567
window_bottom=489
window_type=3
floating=0
floating_left=0
floating_top=0
floating_right=0
floating_bottom=0
floating_type=1
floating_toolbar=1
floating_tbstate=
background_color=0
foreground_color=16777215
barup_color=3107669
bardown_color=128
bullcandle_color=2263842
bearcandle_color=2763429
chartline_color=65280
volumes_color=3329330
grid_color=7346457
bidline_color=10061943
askline_color=255
lastline_color=11829830
stops_color=255
windows_total=2

<expert>
name=roboforexneural
path=Experts\roboforexneural.ex5
expertmode=5
<inputs>
magicrobo=940
=
ativaenvioneural=true
endereco=127.0.0.1
porta=8082
=
ativaentradaea=true
loteinicial=0.04
=
tipomartingale=2
tipotunelvegas=0
pontosmart=60
multiplicador=2
=
ativaBE=true
recuoBE=20
ativaTS=true
pontosTS=20
avancoTS=20
=
ativasaidaea=true
pontosc1=120
pontosc2=140
pontosc3=140
pontosc4=120
pontosc5=20
pontosc6=20
pontosc7=20
pontosc8=30
pontosc9=30
=
inicio=00:05
termino=23:55
pausainicio1=
pausatermino1=
pausainicio2=
pausatermino2=
=
prctniveloper=1500
volumeinicial=1.2
=
ativastop=false
stopemdolar=250
</inputs>
</expert>

<window>
height=174.956994
objects=10

<indicator>
name=Main
path=
apply=1
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1
</indicator>
<object>
type=32
name=autotrade #159279686 sell 0.1 EURUSD at 1.17873
hidden=1
color=1918177
selectable=0
date1=1601927164
value1=1.178730
</object>

<object>
type=32
name=autotrade #159280407 sell 0.1 EURUSD at 1.17876
hidden=1
color=1918177
selectable=0
date1=1601927377
value1=1.178760
</object>

<object>
type=32
name=autotrade #159294361 sell 0.1 EURUSD at 1.17754
hidden=1
color=1918177
selectable=0
date1=1601932076
value1=1.177540
</object>

<object>
type=31
name=autotrade #159305950 buy 0.3 EURUSD at 1.17778
hidden=1
color=11296515
selectable=0
date1=1601935549
value1=1.177780
</object>

<object>
type=31
name=autotrade #159527904 buy 0.1 EURUSD at 1.17351
hidden=1
color=11296515
selectable=0
date1=1602029114
value1=1.173510
</object>

<object>
type=32
name=autotrade #159671752 sell 0.1 EURUSD at 1.17783
hidden=1
color=1918177
selectable=0
date1=1602085540
value1=1.177830
</object>

<object>
type=2
name=autotrade #159279686 -> #159280407 EURUSD
hidden=1
descr=1.17873 -> 1.17876
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1601927164
date2=1601927377
value1=1.178730
value2=1.178760
</object>

<object>
type=2
name=autotrade #159280407 -> #159294361 EURUSD
hidden=1
descr=1.17876 -> 1.17754
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1601927377
date2=1601932076
value1=1.178760
value2=1.177540
</object>

<object>
type=2
name=autotrade #159294361 -> #159305950 EURUSD
hidden=1
descr=1.17754 -> 1.17778
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1601932076
date2=1601935549
value1=1.177540
value2=1.177780
</object>

<object>
type=2
name=autotrade #159527904 -> #159671752 EURUSD
hidden=1
descr=1.17351 -> 1.17783
color=11296515
style=2
selectable=0
ray1=0
ray2=0
date1=1602029114
date2=1602085540
value1=1.173510
value2=1.177830
</object>

</window>

<window>
height=45.783133
objects=0

<indicator>
name=Relative Strength Index
path=
apply=1
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=1
scale_fix_min_val=0.000000
scale_fix_max=1
scale_fix_max_val=100.000000
expertmode=0
fixed_height=-1

<graph>
name=
draw=1
style=0
width=1
arrow=251
color=16748574
</graph>

<level>
level=30.000000
style=2
color=12632256
width=1
descr=
</level>

<level>
level=70.000000
style=2
color=12632256
width=1
descr=
</level>
period=10
</indicator>
</window>
</chart>