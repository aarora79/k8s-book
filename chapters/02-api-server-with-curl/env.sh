# Shared settings for chapter 2. Each step script sources this file.
# Start `kubectl proxy --port=8001` in another terminal first (steps 1 to 5).
API="${API:-http://127.0.0.1:8001}"
NS="${NS:-ch02}"
