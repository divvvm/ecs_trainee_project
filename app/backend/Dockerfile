FROM python:3.9

RUN apt-get update && apt-get install -y postgresql-client

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

COPY init_db.sh .
RUN chmod +x init_db.sh

EXPOSE 8000

ENTRYPOINT ["./init_db.sh"]
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]