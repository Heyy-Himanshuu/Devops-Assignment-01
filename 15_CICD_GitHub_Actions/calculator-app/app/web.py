"""Tiny HTTP front-end over calculator.py, so the image has something to deploy and curl."""
import os

from flask import Flask, jsonify, request

from app.calculator import OPERATIONS

app = Flask(__name__)
VERSION = os.environ.get("APP_VERSION", "dev")


@app.get("/")
def index():
    return f"Hello World from the Session 16 CI/CD calculator (version {VERSION})\n"


@app.get("/health")
def health():
    return jsonify(status="ok", version=VERSION)


@app.get("/api/<op>")
def calculate(op):
    if op not in OPERATIONS:
        return jsonify(error=f"unknown operation '{op}'", valid=sorted(OPERATIONS)), 404
    try:
        a, b = float(request.args["a"]), float(request.args["b"])
        return jsonify(operation=op, a=a, b=b, result=OPERATIONS[op](a, b))
    except KeyError:
        return jsonify(error="query parameters 'a' and 'b' are required"), 400
    except ValueError as e:
        return jsonify(error=str(e)), 400


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8000")))  # nosec B104 - container
