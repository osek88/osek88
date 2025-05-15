from flask import Flask, request

app = Flask(__name__)

@app.route('/')
def home():
    return "Welcome to vulnerable Flask API!"

@app.route('/echo', methods=['POST'])
def echo():
    data = request.json
    return data

if __name__ == "__main__":
    app.run(debug=True)
