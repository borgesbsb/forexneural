from crypt import methods
from flask import Flask

app = Flask(__name__)


@app.route("/<numero>", methods=['GET','POST'] )
def ola(numero):
    return 'Ola Mundo--> {}'.format(numero)

if __name__ == '__main__':
    app.run(debug=True)