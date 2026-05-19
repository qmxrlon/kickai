FROM ruby:3.3-slim

# System dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      nodejs \
      curl \
      git && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js 20 (for asset pipeline / Tailwind CLI)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock* ./
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

COPY . .

# Precompile assets in production
RUN if [ "${RAILS_ENV:-production}" = "production" ]; then \
      SECRET_KEY_BASE=precompile bundle exec rails assets:precompile; \
    fi

# Entrypoint removes a potentially pre-existing server.pid
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
