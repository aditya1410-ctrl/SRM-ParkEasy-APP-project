from datetime import datetime

from flask import Blueprint, jsonify, request

from db import get_db

extension_bp = Blueprint("extension", __name__)

DATETIME_FORMAT = "%Y-%m-%d %H:%M:%S"


@extension_bp.route("/extend", methods=["POST"])
def extend():
    data = request.json or {}

    required_fields = ["booking_id", "extended_until", "extra_amount"]
    missing = [field for field in required_fields if field not in data]
    if missing:
        return jsonify({"error": f"Missing required fields: {', '.join(missing)}"}), 400

    try:
        booking_id = int(data["booking_id"])
        extra_amount = float(data["extra_amount"])
        extended_until = datetime.strptime(data["extended_until"], DATETIME_FORMAT)
    except (TypeError, ValueError):
        return jsonify({"error": "Invalid input format"}), 400

    if extra_amount < 0:
        return jsonify({"error": "extra_amount must be >= 0"}), 400

    conn = get_db()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute(
            """
            SELECT booking_id, user_id, end_time
            FROM booking
            WHERE booking_id = %s
            """,
            (booking_id,),
        )
        booking = cursor.fetchone()
        if not booking:
            return jsonify({"error": "Booking not found"}), 404

        if extended_until <= booking["end_time"]:
            return jsonify({"error": "extended_until must be after current end_time"}), 400

        cursor.execute(
            """
            INSERT INTO extension(booking_id, extended_until, extra_amount)
            VALUES (%s, %s, %s)
            """,
            (booking_id, data["extended_until"], extra_amount),
        )
        extension_id = cursor.lastrowid

        cursor.execute(
            "UPDATE booking SET end_time = %s WHERE booking_id = %s",
            (data["extended_until"], booking_id),
        )

        cursor.execute(
            """
            INSERT INTO notification(user_id, message, status)
            VALUES (%s, %s, 'SENT')
            """,
            (booking["user_id"], f"Booking #{booking_id} extended successfully."),
        )

        conn.commit()
        return (
            jsonify(
                {
                    "message": "Extended",
                    "extension_id": extension_id,
                    "booking_id": booking_id,
                    "extended_until": data["extended_until"],
                    "extra_amount": extra_amount,
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
