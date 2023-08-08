FROM ruby:3.2.2
WORKDIR /doughjo

COPY Gemfile* ./

RUN gem install bundler && bundle config set without 'development test' && bundle install

COPY . ./

ARG PORT
EXPOSE $PORT

CMD ["rails", "server", "-b", "0.0.0.0", "-e", "production"]
