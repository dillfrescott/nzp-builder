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

WORKDIR /quakec

RUN find . -type f -exec sed -i 's/i think he started the femboy transition process/he is here/g' {} +

WORKDIR /

RUN git clone https://github.com/nzp-team/fteqw

WORKDIR /fteqw

RUN find . -type f -exec sed -i 's/\bSatan\b/Paul/g' {} +

RUN find . -type f -exec sed -i "s/\bdevil\b\|devil's/weird/g" {} +

RUN find . -type f -exec sed -i 's/\bHell Magic\b/Weird Magic/g' {} +

RUN find . -type f -exec sed -i 's/Demon/Zombieman/g' {} +

RUN find . -type f -exec sed -i 's/demon/zombieman/g' {} +

RUN find . -type f -name '*Demon*' -exec bash -c 'mv "$0" "${0//Demon/Zombieman}"' {} \;

RUN find . -type f -name '*demon*' -exec bash -c 'mv "$0" "${0//demon/zombieman}"' {} \;



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



# Start Linux x64 Build

RUN cp -r /fteqw /fteqw-linux64

WORKDIR /fteqw-linux64/engine

RUN CC=x86_64-linux-gnu-gcc STRIP=x86_64-linux-gnu-strip make makelibs FTE_TARGET=SDL2 \
&& CC=x86_64-linux-gnu-gcc STRIP=x86_64-linux-gnu-strip make m-rel FTE_TARGET=SDL2 FTE_CONFIG=nzportable -j16 \
&& CC=x86_64-linux-gnu-gcc STRIP=x86_64-linux-gnu-strip mv release/nzportable-sdl2 release/nzportable64-sdl

RUN mkdir /linux-temp

RUN cp release/nzportable64-sdl /linux-temp/

RUN cp /assets/pc/default.fmf /linux-temp/

RUN cp -r /assets/pc/nzp /linux-temp/

WORKDIR /linux-temp

RUN tar -czvf /done/linux64.tgz *



# Start Windows x64 Build

RUN cp -r /fteqw /fteqw-win64

WORKDIR /fteqw-win64/engine

RUN make makelibs FTE_TARGET=win64_SDL2 \
&& (make m-rel FTE_TARGET=win64_SDL2 FTE_CONFIG=nzportable -j16 || true) \
&& make m-rel FTE_TARGET=win64_SDL2 FTE_CONFIG=nzportable -j16

RUN mkdir /win-temp

RUN cp release/nzportable-sdl64.exe /win-temp/

RUN cp /assets/pc/default.fmf /win-temp/

RUN cp -r /assets/pc/nzp /win-temp/

WORKDIR /win-temp

RUN tar -czvf /done/windows64.tgz *


# Entrypoint

ENTRYPOINT ["/bin/bash", "-c", "croc send /done"]
