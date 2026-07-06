from datetime import datetime

from flask import Blueprint, jsonify, request

from db import get_db

booking_bp = Blueprint("booking", __name__)

DATETIME_FORMAT = "%Y-%m-%d %H:%M:%S"


def _parse_datetime(value):
    return datetime.strptime(value, DATETIME_FORMAT)


@booking_bp.route("/users/<int:user_id>/vehicles", methods=["GET"])
def get_user_vehicles(user_id):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            """
            SELECT vehicle_id, user_id, plate_number, vehicle_type
            FROM vehicle
            WHERE user_id = %s
            ORDER BY vehicle_id
            """,
            (user_id,),
        )
        vehicles = cursor.fetchall()
    finally:
        cursor.close()
        conn.close()

    return jsonify(vehicles), 200


@booking_bp.route("/book", methods=["POST"])
def book_slot():
    data = request.json or {}

    required_fields = ["user_id", "vehicle_id", "slot_id", "start_time", "end_time"]
    missing = [field for field in required_fields if field not in data]
    if missing:
        return jsonify({"error": f"Missing required fields: {', '.join(missing)}"}), 400

    try:
        start_time = _parse_datetime(data["start_time"])
        end_time = _parse_datetime(data["end_time"])
    except ValueError:
        return jsonify({"error": "Invalid date format. Use YYYY-MM-DD HH:MM:SS"}), 400

    if end_time <= start_time:
        return jsonify({"error": "End time must be after start time"}), 400

    try:
        user_id = int(data["user_id"])
        vehicle_id = int(data["vehicle_id"])
        slot_id = int(data["slot_id"])
    except (TypeError, ValueError):
        return jsonify({"error": "user_id, vehicle_id and slot_id must be integers"}), 400

    conn = get_db()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("SELECT user_id FROM users WHERE user_id = %s", (user_id,))
        if not cursor.fetchone():
            return jsonify({"error": "User not found"}), 404

        cursor.execute(
            """
            SELECT vehicle_id
            FROM vehicle
            WHERE vehicle_id = %s AND user_id = %s
            """,
            (vehicle_id, user_id),
        )
        if not cursor.fetchone():
            return jsonify({"error": "Vehicle does not belong to user"}), 400

        cursor.execute(
            "SELECT slot_status FROM parking_slot WHERE slot_id = %s",
            (slot_id,),
        )
        slot_row = cursor.fetchone()
        if not slot_row:
            return jsonify({"error": "Slot not found"}), 404

        if slot_row["slot_status"] != "AVAILABLE":
            return jsonify({"error": "Slot is not available"}), 409

        cursor.execute(
            """
            SELECT booking_id
            FROM booking
            WHERE slot_id = %s
              AND booking_status = 'ACTIVE'
              AND NOT (%s >= end_time OR %s <= start_time)
            LIMIT 1
            """,
            (slot_id, data["start_time"], data["end_time"]),
        )
        conflicting_booking = cursor.fetchone()
        if conflicting_booking:
            return jsonify({"error": "Slot is already booked for the selected time"}), 409

        cursor.execute(
            """
            INSERT INTO booking(user_id, vehicle_id, slot_id, start_time, end_time, booking_status)
            VALUES (%s, %s, %s, %s, %s, 'ACTIVE')
            """,
            (user_id, vehicle_id, slot_id, data["start_time"], data["end_time"]),
        )
        booking_id = cursor.lastrowid

        cursor.execute(
            "UPDATE parking_slot SET slot_status = 'OCCUPIED' WHERE slot_id = %s",
            (slot_id,),
        )

        cursor.execute(
            """
            INSERT INTO notification(user_id, message, status)
            VALUES (%s, %s, 'SENT')
            """,
            (user_id, f"Booking #{booking_id} confirmed successfully."),
        )

        conn.commit()
        return (
            jsonify(
                {
                    "message": "Booked successfully",
                    "booking_id": booking_id,
                    "slot_id": slot_id,
                    "start_time": data["start_time"],
                    "end_time": data["end_time"],
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
