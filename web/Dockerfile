FROM python:3.12-alpine

WORKDIR /app
COPY runtime/server.py /app/server.py

ENV PORT=8080 \
    SERVICE=web \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

EXPOSE 8080
USER nobody

CMD ["python", "/app/server.py"]
