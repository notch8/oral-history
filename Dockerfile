FROM registry.gitlab.com/notch8/oral_history/base:latest
ARG BRANCH

ADD http://timejson.herokuapp.com build-time
ADD ops/webapp.conf /etc/nginx/sites-enabled/webapp.conf
ADD ops/env.conf /etc/nginx/main.d/env.conf

RUN echo $BRANCH
RUN cd /home/app/webapp && \
    /sbin/setuser app git fetch -ap && \
    /sbin/setuser app git checkout -f $BRANCH && \
    /sbin/setuser app git pull origin $BRANCH && \
    /sbin/setuser app git clean -fd && \
    chown -R app $APP_HOME && \
    (/sbin/setuser app bundle check || /sbin/setuser app bundle install) && \
    /sbin/setuser app bundle exec rake db:seed rake assets:precompile DB_ADAPTER=nulldb NODE_ENV=production && \
    chown -R app $APP_HOME && \
    rm -f /etc/service/nginx/down

CMD ["/sbin/my_init"]