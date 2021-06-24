import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)
import pandas as pd
import numpy as np
#%matplotlib inline
import sys

parser = lambda x: pd.datetime.strptime(x, "%d.%m.%Y %H:%M:%S")
df = pd.read_csv( 'arquivos_de_coleta/EURUSD_15m.csv', sep=';', header=0, parse_dates=['time'],date_parser=parser)
print(df)