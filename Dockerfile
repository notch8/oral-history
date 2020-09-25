FROM phusion/passenger-ruby25:1.0.11

RUN echo 'Downloading Packages' && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get update -qq && \
    apt-get install -y  \
      build-essential \
      default-jdk \
      ffmpeg \
      imagemagick \
      libpq-dev \
      libsasl2-dev \
      libsndfile1-dev \
      nodejs \
      postgresql-client \
      pv \
      tzdata \
      unzip \
      yarn \
      zip \
      && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    yarn config set no-progress && \
    yarn config set silent && \
    echo 'Packages Downloaded'

ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

RUN gem install whenever
RUN rm /etc/nginx/sites-enabled/default

ENV APP_HOME /home/app/webapp
RUN mkdir $APP_HOME && chown -R app:app /home/app
WORKDIR $APP_HOME

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile \
  BUNDLE_JOBS=4

COPY --chown=app:app Gemfile* $APP_HOME/
RUN /sbin/setuser app bash -l -c "bundle check || bundle install"

RUN touch /var/log/worker.log && chmod 666 /var/log/worker.log
RUN mkdir /etc/service/worker
COPY ops/worker.sh /etc/service/worker/run
RUN chmod +x /etc/service/worker/run
COPY ops/nginx.sh /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run
RUN rm -f /etc/service/nginx/down

COPY ops/webapp.conf /etc/nginx/sites-enabled/webapp.conf
COPY ops/env.conf /etc/nginx/main.d/env.conf

COPY --chown=app:app . $APP_HOME
RUN /sbin/setuser app bash -l -c " \
    cd /home/app/webapp && \
    yarn install && \
    NODE_ENV=production DB_ADAPTER=nulldb bundle exec rake assets:precompile"

CMD ["/sbin/my_init"]
