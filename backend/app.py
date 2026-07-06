import os

from flask import Flask
from flask_cors import CORS

from routes.auth_routes import auth_bp
from routes.parking_routes import parking_bp
from routes.booking_routes import booking_bp
from routes.payment_routes import payment_bp
from routes.extension_routes import extension_bp
from routes.notification_routes import notification_bp

app = Flask(__name__)
CORS(app)

@app.route("/")
def health():
    return {"status": "ok", "message": "ParkEasy API is running"}

@app.route("/health")
def health_check():
    return {"status": "healthy"}

app.register_blueprint(auth_bp)
app.register_blueprint(parking_bp)
app.register_blueprint(booking_bp)
app.register_blueprint(payment_bp)
app.register_blueprint(extension_bp)
app.register_blueprint(notification_bp)

if __name__ == "__main__":
    app.run(
        host=os.getenv("API_HOST", "0.0.0.0"),
        port=int(os.getenv("API_PORT", "5001")),
        debug=os.getenv("API_DEBUG", "true").lower() == "true",
    )
