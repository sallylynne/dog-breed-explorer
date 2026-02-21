FROM python:3.11-slim
RUN pip install --upgrade pip

# 1. Set the working directory inside the container
WORKDIR /app

# 2. Copy the requirements file first (for better caching)
COPY requirements.txt .

# 3. Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copy the rest of your code (including gcp-key.json and dog_pipeline.py)
COPY . .

# 5. Set environment variable for logs to show up immediately
ENV PYTHONUNBUFFERED=True

# 6. Command to run your script
CMD ["python", "dog_pipeline.py"]
