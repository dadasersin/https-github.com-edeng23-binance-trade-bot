# --- Stage 1: Builder ---
FROM --platform=linux/amd64 python:3.11.12-slim-bookworm as builder

# 1. Gerekli sistem kütüphaneleri
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    wget \
    && rm -rf /var/lib/apt/lists/*

# 2. TA-Lib KURULUMU (Kaynaktan derleme)
RUN wget https://downloads.sourceforge.net/project/ta-lib/ta-lib/0.4.0/ta-lib-0.4.0-src.tar.gz && \
    tar -xzf ta-lib-0.4.0-src.tar.gz && \
    cd ta-lib && \
    ./configure --prefix=/usr && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    # Kurulumu doğrula
    ls -la /usr/include/ta-lib/ta_defs.h && \
    ls -la /usr/lib/libta_lib.so*

# --- Stage 2: Runtime ---
FROM python:3.11.12-slim-bookworm

# 3. TA-Lib dosyalarını kopyala
COPY --from=builder /usr/include/ta-lib /usr/include/ta-lib
COPY --from=builder /usr/lib/libta_lib* /usr/lib/

# 4. Python ortamını ayarla
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. TA-Lib kontrolü
RUN python -c "import talib; print('TA-Lib versiyon:', talib.__version__)" || \
    (echo "TA-Lib yükleme hatası!" && exit 1)

COPY . .
CMD ["freqtrade", "trade", "--strategy", "MyStrategy"]
