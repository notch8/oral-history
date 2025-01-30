# Use Phusion Passenger Ruby 3.2.7 image
FROM phusion/passenger-ruby32:3.0.7 AS web

# Install system dependencies
RUN echo 'Downloading Packages' && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y  \
      build-essential \
      curl \
      default-jdk \
      ffmpeg \
      imagemagick \
      libjemalloc2 \
      libpq-dev \
      libsasl2-dev \
      libsndfile1-dev \
      libvips \
      postgresql-client \
      pv \
      python2 \
      tzdata \
      unzip \
      yarn \
      zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    yarn config set no-progress && \
    yarn config set silent && \
    echo 'Packages Downloaded'

# Install correct Node.js version
RUN echo 'Node version fix' && \
    apt-get remove -y nodejs && \
    curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    echo 'Node done'

# Install RubyGems 3.3.22 for compatibility
RUN gem install rubygems-update -v 3.3.22 && \
    gem update --system 3.3.22

# Grant app user permissions to RVM gems directory
RUN chown -R app:app /usr/local/rvm/gems

# Install whenever gem
RUN gem install whenever

# Remove default nginx config
RUN rm /etc/nginx/sites-enabled/default

# Set environment variables and working directory
ENV APP_HOME=/home/app/webapp
RUN mkdir $APP_HOME && chown -R app:app /home/app
WORKDIR $APP_HOME

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile \
    BUNDLE_JOBS=4

# Copy Gemfile and install bundle as app user
COPY --chown=app:app Gemfile* $APP_HOME/
RUN /sbin/setuser app bash -l -c "bundle check || bundle install"

# Set up nginx and application configuration
COPY ops/nginx.sh /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run
RUN rm -f /etc/service/nginx/down

COPY ops/webapp.conf /etc/nginx/sites-enabled/webapp.conf
COPY ops/env.conf /etc/nginx/main.d/env.conf

# Copy the application code
COPY --chown=app:app . $APP_HOME

# Precompile assets as app user
RUN /sbin/setuser app bash -l -c " \
    cd /home/app/webapp && \
    yarn install && \
    NODE_ENV=production DB_ADAPTER=nulldb bundle exec rake assets:precompile"

# Set default command
CMD ["/sbin/my_init"]