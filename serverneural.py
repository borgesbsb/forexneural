import socket
import tensorflow as tf
from tensorflow.keras.models import load_model
import numpy as np
import pandas as pd
from sklearn.preprocessing import MinMaxScaler

class Connection:
    def __init__(self):
        self.host = '127.0.0.1' 
        self.port = 8082
        self.data_payload = 1000
    
    def listen(self):
         self.sock = socket.socket(socket.AF_INET,  socket.SOCK_STREAM)
         self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
         self.server_address = (self.host, self.port)
         self.sock.bind(self.server_address)
         self.sock.listen(5)
         self.client, self.address = self.sock.accept() 
         
    def forecasts(self,prediction):
        try:
            while True: 
                valores = []
                data = self.client.recv(self.data_payload).decode('utf-8') 
                if data:
                    predict = prediction.makepredictions(data)
                    self.client.send(bytes(predict), "utf-8")
        except KeyboardInterrupt:
            print("Encerrando Servidor de Previsões")
        pass 



###########################################Classe de Prfedição#######################################
class Predictions:   
    def __init__(self):
        self.model = load_model('LSTM',compile = False)
        self.scaler_X  = MinMaxScaler()
        self.scaler_Y  = MinMaxScaler()
        self.df = pd.read_csv('EURUSD_RECENTE.csv', sep=';', header=0)
        self.df_X = None
        self.df_Y = None
        self.predict = None
        self.setScaler()

    def setScaler(self):
        self.df_X = self.df.iloc[:,1:5]
        self.df_Y = self.df_X.copy()
        self.scaler_X.fit(self.df_X)
        self.scaler_Y.fit( self.df_Y.iloc[:,3].values.reshape(-1,1) )

    def makepredictions(self,values):
        values = values.split(",")
        x_values = []
        for i in values:
            x_values.append(float(i))
        x_values = np.array(x_values)
        x_values = np.reshape(x_values,(2,4))
        x_values = self.scaler_X.transform(x_values)
        x_values = np.reshape(x_values,(1,2,4))
        self.predict =  self.model.predict(x_values)
        self.predict =  self.scaler_Y.inverse_transform(self.predict)
        return self.predict

    def getPrediction(self):
        if (self.predict):
            return self.predict
        else:
            return "Previsao nao encontrada" 
        
    
##############################################################ALgoritmo################################################
prediction = Predictions()
brain = Connection()
brain.listen()
brain.forecasts(prediction)
