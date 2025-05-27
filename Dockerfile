# --- Stage 1: Builder ---
FROM --platform=linux/amd64 python:3.11.12-slim-bookworm as builder

# 1. Sistem bağımlılıkları
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    wget \
    && rm -rf /var/lib/apt/lists/*

# 2. TA-Lib KURULUMU (Kritik adım)
RUN wget https://netix.dl.sourceforge.net/project/ta-lib/ta-lib/0.4.0/ta-lib-0.4.0-src.tar.gz && \
    tar -xzf ta-lib-0.4.0-src.tar.gz && \
    cd ta-lib && \
    ./configure --prefix=/usr && \
    make -j$(nproc) && \
    make install && \
    rm -rf ../ta-lib*

# 3. Header dosyalarını kontrol
RUN ls -la /usr/include/ta-lib/ && \
    ls -la /usr/lib/libta_lib*

# --- Stage 2: Runtime ---
FROM python:3.11.12-slim-bookworm

# 4. TA-Lib dosyalarını kopyala
COPY --from=builder /usr/include/ta-lib /usr/include/ta-lib
COPY --from=builder /usr/lib/libta_lib* /usr/lib/

# 5. Python bağımlılıkları
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 6. Son kontrol
RUN python -c "import talib; print('TA-Lib loaded:', talib.__version__)"

COPY . .
CMD ["freqtrade", "trade", "--strategy", "MyStrategy"]
