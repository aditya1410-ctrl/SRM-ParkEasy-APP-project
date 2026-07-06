from flask import Blueprint, jsonify, request

from db import get_db

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.json or {}
    email = (data.get("email") or "").strip()

    if not email:
        return jsonify({"error": "Email is required"}), 400

    conn = get_db()
    cursor = conn.cursor(dictionary=True)

    try:
        # Query to fetch user details by email
        cursor.execute(
            """
            SELECT user_id, srm_id, name, email, phone, role, created_at
            FROM users
            WHERE email = %s
            """,
            (email,),
        )
        user = cursor.fetchone()

        if user:
            cursor.execute(
                """
                INSERT INTO notification(user_id, message, status)
                VALUES (%s, %s, 'SENT')
                """,
                (
                    user["user_id"],
                    f"Welcome back, {user['name']}. You logged in successfully.",
                ),
            )
            conn.commit()
    finally:
        cursor.close()
        conn.close()

    if not user:
        return jsonify({"error": "User not found"}), 404

    return jsonify(user), 200


@auth_bp.route("/users/<int:user_id>/profile", methods=["GET"])
def get_user_profile(user_id):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute(
            """
            SELECT user_id, srm_id, name, email, phone, role, created_at
            FROM users
            WHERE user_id = %s
            """,
            (user_id,),
        )
        user = cursor.fetchone()
    finally:
        cursor.close()
        conn.close()

    if not user:
        return jsonify({"error": "User not found"}), 404

    return jsonify(user), 200
