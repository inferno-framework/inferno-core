FROM ruby:2.7.3

RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get update
RUN apt-get install -y nodejs npm

ENV INSTALL_PATH=/opt/inferno/
ENV APP_ENV=production
ENV NODE_ENV=production
RUN mkdir -p $INSTALL_PATH

WORKDIR $INSTALL_PATH

ADD package.json $INSTALL_PATH
ADD package-lock.json $INSTALL_PATH

RUN npm install --also=dev

ADD Gemfile* $INSTALL_PATH
RUN gem install bundler
RUN bundle install --deployment 

ADD . $INSTALL_PATH

RUN npm run build

EXPOSE 4567
CMD ["bundle", "exec", "puma"]
