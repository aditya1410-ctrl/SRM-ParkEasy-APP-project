from flask import Blueprint, jsonify

from db import get_db

notification_bp = Blueprint("notify", __name__)


@notification_bp.route("/notifications/<int:user_id>")
def get_notifications(user_id):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            """
            SELECT notification_id, user_id, message, sent_time, status
            FROM notification
            WHERE user_id = %s
            ORDER BY sent_time DESC
            LIMIT 50
            """,
            (user_id,),
        )
        rows = cursor.fetchall()
    finally:
        cursor.close()
        conn.close()

    return jsonify(rows), 200


@notification_bp.route("/notifications/<int:notification_id>/read", methods=["PATCH"])
def mark_notification_read(notification_id):
    conn = get_db()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """
            UPDATE notification
            SET status = 'READ'
            WHERE notification_id = %s
            """,
            (notification_id,),
        )
        if cursor.rowcount == 0:
            return jsonify({"error": "Notification not found"}), 404
        conn.commit()
    finally:
        cursor.close()
        conn.close()

    return jsonify({"message": "Notification marked as read"}), 200
