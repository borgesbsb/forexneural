import socket
import tensorflow as tf
from tensorflow.keras.models import load_model
import numpy as np
import pandas as pd
import joblib as jl
from utils.connections import Connection
from utils.predictions import Predictions


def main():    
    ##############################################################ALgoritmo################################################
    print("Carregando os Módulos, aguarde! Tenha Paciência")
    timestamp = 2
    # features = ['open1','max1','min1','open2','max2','min2','open3','max3','min3','open4','max4','min4','close4']
    features   = ['time','open1','max1','min1','ticks1','open2','max2','min2','ticks2','open3','max3','min3','ticks3','open4','max4','min4','close4']
    namemodel1 = 'LSTM_EURUSD-15M-1H'
    prediction = Predictions(namemodel1, timestamp, features)
    brain = Connection()
    brain.listen()
    brain.forecasts(prediction)
###########################################################################################################################


main()
