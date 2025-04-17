FROM debian:bookworm

RUN apt update && apt upgrade -y

RUN apt install -y sudo wget curl git zip ffmpeg python3 python3-pip

RUN dpkg --add-architecture i386 \
 && dpkg --add-architecture armhf \
 && dpkg --add-architecture arm64

RUN apt update

RUN apt install -y \
    emscripten \
    build-essential \
    crossbuild-essential-i386 \
    crossbuild-essential-armhf \
    crossbuild-essential-arm64 \
    gcc-mingw-w64-i686 \
    gcc-mingw-w64-x86-64 \
    mingw-w64-i686-dev \
    mingw-w64-x86-64-dev \
    mingw-w64-tools \
    libsdl2-dev \
    libsdl2-dev:i386 \
    libsdl2-dev:arm64 \
    libsdl2-dev:armhf \
    libgnutls28-dev \
    libgnutls28-dev:i386 \
    libgnutls28-dev:arm64 \
    libgnutls28-dev:armhf

RUN curl https://getcroc.schollz.com | bash


# Prepare

RUN git clone https://github.com/nzp-team/assets /assets

RUN pip install colorama==0.4.6 fastcrc==0.3.0 pandas==2.1.4 --break-system-packages

RUN git clone https://github.com/nzp-team/quakec /quakec

RUN git clone https://github.com/nzp-team/fteqw /fteqw


# Start Web Build

RUN cp -r /fteqw /fteqw-web

WORKDIR /fteqw-web/engine

RUN make makelibs FTE_TARGET=linux64

RUN make web-rel FTE_CONFIG=nzportable -j16

WORKDIR /

RUN git clone https://github.com/dillfrescott/play.dill.moe

WORKDIR /play.dill.moe

RUN rm -f ftewebgl.js ftewebgl.wasm default.fmf nzp/game.pk3

RUN cp /fteqw-web/engine/release/ftewebgl.js .

RUN cp /fteqw-web/engine/release/ftewebgl.wasm .

RUN cp /assets/pc/default.fmf .

RUN cp -r /quakec /quakec-web

WORKDIR /quakec-web

WORKDIR /quakec-web/tools

RUN ./qc-compiler-gnu.sh

RUN cp -r /quakec-web/build/fte/* /assets/pc/nzp/

WORKDIR /assets/pc/nzp/tracks

RUN find . -name '*.ogg' -exec bash -c 'ffmpeg -i $1 -acodec pcm_u8 -ar 16000 ${1%.*}.wav' -- {} \;

RUN rm -f *.ogg

WORKDIR /assets/pc/nzp

RUN cp -r /assets/common/* .

RUN zip -r /play.dill.moe/nzp/game.pk3 *

RUN mkdir /done

RUN tar -czvf /done/play.dill.moe.tgz /play.dill.moe


# Entrypoint

ENTRYPOINT ["/bin/bash", "-c", "croc send /done"]
