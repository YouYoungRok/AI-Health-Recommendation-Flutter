#!/usr/bin/env bash
cd "$(dirname "$0")"
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
uvicorn server:app --host 0.0.0.0 --port 8000
