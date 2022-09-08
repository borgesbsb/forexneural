from tensorflow.keras.models import load_model
from sklearn.preprocessing import MinMaxScaler
import joblib as jl



class Predictions:   
    def __init__(self,namemodel, timestamp, features ):
        self.model = load_model('../redeneural/'+namemodel)
        self.scaler_X  = MinMaxScaler()
        self.scaler_Y  = MinMaxScaler()
        self.timestamp = timestamp
        self.features  = features
        self.predict = None
        self.setScaler()

    def setScaler(self):
        self.scaler_X = jl.load('../redeneural/scaler_x.pkl')
        self.scaler_y = jl.load('../redeneural/scaler_y.pkl')

    def makepredictions(self,values):
        values = values.split(",")
        x_values = []
        print(values)
        for i in values:
            x_values.append(float(i))
        x_values = np.array(x_values)
        x_values = np.reshape(x_values,(1,13))
        
        x_values = self.scaler_X.transform(x_values)
        x_values = np.reshape(x_values,(1, 1, 13))
        self.predict =  self.model.predict(x_values)
        prevision = self.scaler_y.inverse_transform(self.predict)
        return  str(prevision[0][0])