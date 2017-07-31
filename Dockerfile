FROM openjdk:8-jdk-slim as builder

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y curl gnupg2 upx

RUN echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list \
 && curl https://bazel.build/bazel-release.pub.gpg -o bazel.key \
 && apt-key add bazel.key \
 && apt-get update \
 && apt-get install -y bazel

RUN apt-get install -y git


RUN mkdir /output

# guetzli
RUN git clone https://github.com/google/guetzli.git \
  && cd guetzli \
  && git pull \
  && git checkout git tag | tail -n1 \
  && bazel --output_base=/output build -c opt //:guetzli \
  && ln /output/execroot/guetzli/bazel-out/local-opt/bin/guetzli /output

# butteraugli
RUN git clone https://github.com/google/butteraugli.git \
  && cd butteraugli \
  && git pull \
  && bazel --output_base=/output build -c opt //:butteraugli \
  && ln /output/execroot/butteraugli/bazel-out/local-opt/bin/butteraugli /output

WORKDIR /output
RUN    ldd guetzli     | sed -e 's#.*=> ##; s#\t*##; s# .*##'| grep ^/ > libs.txt \
    && ldd butteraugli | sed -e 's#.*=> ##; s#\t*##; s# .*##'| grep ^/ >> libs.txt \
    && cat libs.txt | sort -u | xargs dirname | xargs -I{} mkdir -p libs{} \
    && cat libs.txt | sort -u | awk {'print "cp -v "$1" libs"$1'} > copy.sh \
    && bash < copy.sh

# compress the libs
RUN cat libs.txt \
    && cd libs/lib/x86_64-linux-gnu \
    && ls -aslh \
    && chmod +x * \
    && xargs upx -v --ultra-brute libstdc++.so.6 \
    && chmod -x *

RUN chmod +w * \
 && upx -v --ultra-brute \
            butteraugli \
            guetzli \
 && chmod -w *


FROM scratch

COPY --from=builder /output/libs        /
COPY --from=builder /output/guetzli     guetzli
COPY --from=builder /output/butteraugli butteraugli
