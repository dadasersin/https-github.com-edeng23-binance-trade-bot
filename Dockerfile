# --- Stage 1: Builder with TA-Lib ---
FROM --platform=linux/amd64 python:3.11.12-slim-bookworm as builder

WORKDIR /install

# Gerekli sistem bağımlılıkları
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    wget \
    && rm -rf /var/lib/apt/lists/*

# TA-Lib kurulumu (önce kaynakları derle)
RUN wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz && \
    tar -xzf ta-lib-0.4.0-src.tar.gz && \
    cd ta-lib && \
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

# TA-Lib kütüphanelerini kopyala
COPY --from=builder /usr/lib/libta_lib.so* /usr/lib/
COPY --from=builder /usr/include/ta-lib/ /usr/include/ta-lib/
COPY --from=builder /install /usr/local

# Uygulama dosyaları
COPY . .

# Çalıştırma komutu
CMD ["freqtrade", "trade", "--strategy", "MyStrategy"]
