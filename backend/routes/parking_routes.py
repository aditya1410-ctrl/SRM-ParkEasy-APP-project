from flask import Blueprint, jsonify, request

from db import get_db

parking_bp = Blueprint("parking", __name__)


@parking_bp.route("/slots")
def get_slots():
    status_filter = (request.args.get("status") or "ALL").upper()
    allowed_filters = {"ALL", "AVAILABLE", "OCCUPIED"}

    if status_filter not in allowed_filters:
        return jsonify({"error": "Invalid status filter"}), 400

    conn = get_db()
    cursor = conn.cursor(dictionary=True)

    query = """
        SELECT slot_id, zone_id, slot_number, slot_status, zone_name, location
        FROM parking_slot
        JOIN parking_zone USING(zone_id)
    """
    params = ()

    if status_filter != "ALL":
        query += " WHERE slot_status = %s"
        params = (status_filter,)

    query += " ORDER BY zone_name, slot_number"

    try:
        cursor.execute(query, params)
        rows = cursor.fetchall()
    finally:
        cursor.close()
        conn.close()

    return jsonify(rows), 200
