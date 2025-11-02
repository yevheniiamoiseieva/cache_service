FROM ruby:3.2.0-slim

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  nodejs \
  --no-install-recommends && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile /app/
COPY Gemfile.lock /app/

RUN bundle install --jobs 4 --retry 3

COPY . /app

EXPOSE 9292

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]