
# --- Stage 1: Builder with TA-Lib and dependencies ---
FROM --platform=$BUILDPLATFORM python:3.11-slim-bookworm as builder

WORKDIR /install

# TA-Lib ve sistem bağımlılıkları
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
    rm -rf ta-lib*

# FreqTrade bağımlılıklarını yükle
COPY requirements.txt .
RUN pip install --user --prefix=/install -r requirements.txt

# --- Stage 2: Runtime image ---
FROM python:3.11-slim-bookworm

WORKDIR /app

# Builder'dan gerekli dosyaları kopyala
COPY --from=builder /install /usr/local
COPY --from=builder /usr/lib/libta_lib.so.0 /usr/lib/
COPY --from=builder /usr/include/ta-lib/ /usr/include/ta-lib/

# Uygulama dosyalarını kopyala
COPY . .

# Environment variables (Render'da ayarlanacak)
ENV FT_APP_ENV="production"
ENV PYTHONUNBUFFERED=1

# Persistan veriler için volume
VOLUME /app/user_data

# FreqTrade'i çalıştır
CMD ["freqtrade", "trade", "--strategy", "MyStrategy", "--db-url", "sqlite:///trades.sqlite"]
