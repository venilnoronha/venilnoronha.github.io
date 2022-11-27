FROM node:11.15

SHELL ["/bin/bash", "--login", "-c"]

COPY Gemfile .
COPY Rakefile .
COPY gulpfile.js .
COPY package.json .

RUN npm install
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import -
RUN curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
RUN curl -L get.rvm.io | bash -s stable
RUN /usr/local/rvm/bin/rvm install 2.4
RUN rvm --default use 2.4
RUN bundle install

EXPOSE 4000
WORKDIR /site/
ENTRYPOINT ["/bin/bash", "--login", "-c"]
