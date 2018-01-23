FROM phusion/passenger-ruby23:0.9.20

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    add-apt-repository -y ppa:webupd8team/java && \
    apt-get update -qq && \
    apt-get install -y build-essential nodejs yarn pv libsasl2-dev libpq-dev postgresql-client oracle-java8-installer && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

RUN rm /etc/nginx/sites-enabled/default
COPY ops/webapp.conf /etc/nginx/sites-enabled/webapp.conf
COPY ops/env.conf /etc/nginx/main.d/env.conf

ENV APP_HOME /home/app/webapp
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile \
  BUNDLE_JOBS=4

ADD Gemfile* $APP_HOME/
RUN bundle check || bundle install
RUN yarn install

RUN touch /var/log/worker.log && chmod 666 /var/log/worker.log
RUN mkdir /etc/service/worker
ADD ops/worker.sh /etc/service/worker/run
RUN chmod +x /etc/service/worker/run


COPY . $APP_HOME
RUN chown -R app $APP_HOME

# Asset complie and migrate if prod, otherwise just start nginx
ADD ops/nginx.sh /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run
RUN rm -f /etc/service/nginx/down

CMD ["/sbin/my_init"]
