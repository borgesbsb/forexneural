from flask import Flask, jsonify, request
import joblib as jl
import json
# from tensorflow.keras.models import load_model

app = Flask(__name__)

# scaler_X = jl.load('./redeneural/scaler_x.pkl')
# scaler_y = jl.load('./redeneural/scaler_y.pkl')
# model = load_model('./redeneural/'+'LSTM_EURUSD-15M-1H')


@app.route('/', methods=['POST'])
def predictions():
    dados  = json.loads(request.data)
    
    return jsonify(dados['close4'])



if __name__ == '__main__':
    app.run()
