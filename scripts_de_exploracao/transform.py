#Esse arquivo faz o tratamento dos dados em formato reconhecido pela rede


import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)
import pandas as pd
import numpy as np
#%matplotlib inline
import sys
import re

parser = lambda x: pd.datetime.strptime(x, "%d.%m.%Y %H:%M:%S")
df = pd.read_csv( '../arquivos_de_coleta/transform-EURUSD_M15_201808131000_202209022345_save.csv', sep=';', header=0, parse_dates=['time'],date_parser=parser)
#print(df)

lines = []
drop_lines = []
#df.reset_index(drop=True, inplace=True)

for i in range(1,len(df)):
    if df.iloc[i,0].minute == df.iloc[i-1,0].minute:
        drop_lines.append(i-1)

df = df.drop(drop_lines)


# #print(df.iloc[0,1:])
# #Verificando decimais errados
for i in range(len(df)):
    for j  in range(1,5):
        if re.search('.0$',str(df.iloc[i,j])):
            df.iloc[i,j] = df.iloc[i,j]/1000        

# for i in range(0,len(df)-4,4):
#     lines_tmp = []
#     for columns_  in  range(0,6):
#         lines_tmp.append(df.iloc[i,columns_])
#     for columns_  in  range(1,6):
#         lines_tmp.append(df.iloc[i+1,columns_])
#     for columns_  in  range(1,6):
#         lines_tmp.append(df.iloc[i+2,columns_])
#     for columns_  in  range(1,6):
#         lines_tmp.append(df.iloc[i+3,columns_])
#     lines.append(lines_tmp)        
for i in range(len(df)-6):
    lines_tmp = []
    for columns_  in  range(0,6):
        lines_tmp.append(df.iloc[i,columns_])
    for columns_  in  range(1,6):
         lines_tmp.append(df.iloc[i+1,columns_])
    for columns_  in  range(1,6):
         lines_tmp.append(df.iloc[i+2,columns_])
    for columns_  in  range(1,6):
         lines_tmp.append(df.iloc[i+3,columns_])
    lines.append(lines_tmp)

df = pd.DataFrame(lines)

df.to_csv('transform_collection.csv', header=False, index=False,float_format='%.5f')