# --- Stage 1: Builder with TA-Lib ---
FROM --platform=$BUILDPLATFORM python:3.11-slim-bookworm as builder

WORKDIR /install

# TA-Lib sistem bağımlılıkları
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    wget && \
    wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz && \
    tar -xvzf ta-lib-0.4.0-src.tar.gz && \
    cd ta-lib/ && \
    ./configure --prefix=/usr && \
    make && \
    make install && \
    rm -rf ta-lib* && \
    ldconfig

# Python bağımlılıklarını yükle
COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt

# --- Stage 2: Runtime ---
FROM python:3.11-slim-bookworm

WORKDIR /app

# TA-Lib ve Python kütüphanelerini kopyala
COPY --from=builder /usr/lib/libta_lib.* /usr/lib/
COPY --from=builder /usr/include/ta-lib/ /usr/include/ta-lib/
COPY --from=builder /install /usr/local

# Uygulama dosyaları
COPY . .

CMD ["freqtrade", "trade", "--strategy", "MyStrategy"]
