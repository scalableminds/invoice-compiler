FROM node:12

RUN  apt-get update \
     && apt-get install -y wget gnupg ca-certificates \
     && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
     && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
     && apt-get update \
     # We install Chrome to get all the OS level dependencies, but Chrome itself
     # is not actually used as it's packaged in the node puppeteer library.
     # Alternatively, we could could include the entire dep list ourselves
     # (https://github.com/puppeteer/puppeteer/blob/master/docs/troubleshooting.md#chrome-headless-doesnt-launch-on-unix)
     # but that seems too easy to get out of date.
     && apt-get install -y google-chrome-stable ttf-freefont fonts-ipafont-gothic \
     && rm -rf /var/lib/apt/lists/* \
     && wget --quiet https://github.com/JulietaUla/Montserrat/archive/v7.210.zip -O Montserrat.zip \
     && unzip -j Montserrat.zip "Montserrat-7.210/fonts/otf/*" -d /usr/share/fonts/montserrat \
     && chmod -R +xr /usr/share/fonts \
     && fc-cache -fv


COPY . /app
WORKDIR /app

RUN chown -R 2000:2000 /app
USER 2000:2000

RUN yarn install --frozen-lockfile

ENV TMPDIR=/var/tmp/

CMD node server
