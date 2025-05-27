# --- Stage 1: Builder with TA-Lib ---
FROM --platform=linux/amd64 python:3.11.12-slim-bookworm as builder

WORKDIR /install

# TA-Lib sistem bağımlılıkları
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    wget \
    && rm -rf /var/lib/apt/lists/*

# TA-Lib kurulumu
RUN wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz && \
    tar -xvzf ta-lib-0.4.0-src.tar.gz && \
    cd ta-lib/ && \
    ./configure --prefix=/usr && \
    make -j$(nproc) && \
    make install && \
    rm -rf ../ta-lib* && \
    ldconfig

# Python bağımlılıklarını yükle
COPY requirements.txt .
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

# --- Stage 2: Runtime ---
FROM python:3.11.12-slim-bookworm

WORKDIR /app

# TA-Lib ve kütüphaneleri kopyala
COPY --from=builder /usr/lib/libta_lib.so* /usr/lib/
COPY --from=builder /usr/include/ta-lib/ /usr/include/ta-lib/
COPY --from=builder /install /usr/local

# Uygulama dosyaları
COPY . .

# Runtime ayarları
ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# Persistan veriler için volume
VOLUME /app/user_data

# FreqTrade'i çalıştır
CMD ["freqtrade", "trade", "--strategy", "MyStrategy", "--db-url", "sqlite:////app/user_data/trades.sqlite"]
