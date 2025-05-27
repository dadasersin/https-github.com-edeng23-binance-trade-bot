# --- Stage 1: Builder with TA-Lib ---
FROM --platform=linux/amd64 python:3.11.12-slim-bookworm as builder

WORKDIR /install

# 1. Gerekli sistem bağımlılıkları
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    wget \
    && rm -rf /var/lib/apt/lists/*

# 2. TA-Lib KURULUMU (Kritik adımlar)
RUN wget https://downloads.sourceforge.net/project/ta-lib/ta-lib/0.4.0/ta-lib-0.4.0-src.tar.gz && \
    tar -xzf ta-lib-0.4.0-src.tar.gz && \
    cd ta-lib && \
    ./configure --prefix=/usr && \
    make -j$(nproc) && \
    make install && \
    # Header dosyalarını kontrol et
    ls -la /usr/include/ta-lib/ && \
    # Kütüphaneleri kontrol et
    ls -la /usr/lib/libta_lib* && \
    rm -rf ../ta-lib* && \
    ldconfig

# 3. Python bağımlılıkları
COPY requirements.txt .
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

# --- Stage 2: Runtime ---
FROM python:3.11.12-slim-bookworm

WORKDIR /app

# 4. TA-Lib dosyalarını KESİNLİKLE kopyala
COPY --from=builder /usr/lib/libta_lib.so* /usr/lib/
COPY --from=builder /usr/include/ta-lib /usr/include/ta-lib
COPY --from=builder /install /usr/local

# 5. Runtime kontrol komutları
RUN echo "TA-Lib kontrolü:" && \
    ls -la /usr/include/ta-lib/ && \
    ls -la /usr/lib/libta_lib* && \
    python -c "import talib; print('TA-Lib versiyon:', talib.__version__)"

COPY . .
CMD ["freqtrade", "trade", "--strategy", "MyStrategy"]
