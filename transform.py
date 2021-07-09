#Esse arquivo faz o tratamento dos dados em formato reconhecido pela rede


import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)
import pandas as pd
import numpy as np
#%matplotlib inline
import sys

parser = lambda x: pd.datetime.strptime(x, "%d.%m.%Y %H:%M:%S")
df = pd.read_csv( 'arquivos_de_coleta/EURUSD_15m.csv', sep=';', header=0, parse_dates=['time'],date_parser=parser)
#print(df)

lines = []

#print(df.iloc[0,1:])

for i in range(0,len(df)-4,4):
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