import datetime

input = "EURUSD_M15_201808131000_202209022345_save.csv"
output = "transform-"+input
ref_arquivo = open("../arquivos_de_coleta/"+input,"r")
f = open("../arquivos_de_coleta/"+output,'w')

for linha in ref_arquivo:
    valores = linha.split(",")
    data =  datetime.datetime.strptime(valores[0],'%Y.%m.%d').strftime('%d.%m.%Y')
    line_string = data+" "+str(valores[1])+";"+str(valores[2])+";"+str(valores[3])+";"+str(valores[4])+";"+str(valores[5])+";"+str(valores[6])
    f.write(line_string)

f.close()
ref_arquivo.close()