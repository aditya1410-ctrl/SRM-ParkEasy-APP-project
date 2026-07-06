from flask import Blueprint, jsonify, request

from db import get_db

payment_bp = Blueprint("payment", __name__)

ALLOWED_METHODS = {"UPI", "CARD", "WALLET"}


@payment_bp.route("/pay", methods=["POST"])
def pay():
    data = request.json or {}

    required_fields = ["booking_id", "amount", "method"]
    missing = [field for field in required_fields if field not in data]
    if missing:
        return jsonify({"error": f"Missing required fields: {', '.join(missing)}"}), 400

    payment_method = str(data["method"]).upper()
    if payment_method not in ALLOWED_METHODS:
        return jsonify({"error": "Invalid payment method"}), 400

    try:
        booking_id = int(data["booking_id"])
        amount = float(data["amount"])
    except (TypeError, ValueError):
        return jsonify({"error": "Invalid booking_id or amount"}), 400

    if amount <= 0:
        return jsonify({"error": "Amount must be greater than 0"}), 400

    conn = get_db()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT booking_id, user_id FROM booking WHERE booking_id = %s",
            (booking_id,),
        )
        booking = cursor.fetchone()
        if not booking:
            return jsonify({"error": "Booking not found"}), 404

        cursor.execute(
            """
            INSERT INTO payment(booking_id, amount, payment_method, payment_status)
            VALUES (%s, %s, %s, 'SUCCESS')
            """,
            (booking_id, amount, payment_method),
        )
        payment_id = cursor.lastrowid

        cursor.execute(
            """
            INSERT INTO notification(user_id, message, status)
            VALUES (%s, %s, 'SENT')
            """,
            (booking["user_id"], f"Payment successful for booking #{booking_id}."),
        )

        conn.commit()
        return (
            jsonify(
                {
                    "message": "Payment Success",
                    "payment_id": payment_id,
                    "booking_id": booking_id,
                    "amount": amount,
                    "method": payment_method,
                }
            ),
            201,
        )
    except Exception as exc:
        conn.rollback()
        return jsonify({"error": str(exc)}), 500
    finally:
        cursor.close()
        conn.close()
