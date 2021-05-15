import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

parser = lambda x: pd.datetime.strptime(x, "%Y-%m-%d %H:%M:%S")
df = pd.read_csv( 'previsoes_EURUSD_17032021', sep=',', header=0, parse_dates=['time'],date_parser=parser) 

#print(df)

df['acertos'] =  np.where( ( df['prevision'] > df['min']) & (df['prevision'] < df['max']),1,0)

sequencia = 0
maior_sequencia = 0
qtd_maior_serquencia = 0
for i in df['acertos']:
    if i == 0:
        sequencia = sequencia+1
    else:
        sequencia = 0
    if sequencia >= maior_sequencia:
        if maior_sequencia == sequencia and maior_sequencia == 6:
            qtd_maior_serquencia = qtd_maior_serquencia+1
        maior_sequencia = sequencia
        
print(maior_sequencia)
print(qtd_maior_serquencia)


