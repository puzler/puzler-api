FROM ruby:3.2.2
WORKDIR /doughjo

COPY Gemfile* ./

RUN gem install bundler && bundle config set without 'development test' && bundle install

COPY . ./
ARG RAILS_MASTER_KEY
RUN RAILS_ENV=production bundle exec rake assets:precompile

ARG PORT
EXPOSE $PORT

CMD ["rails", "server", "-b", "0.0.0.0", "-e", "production"]
