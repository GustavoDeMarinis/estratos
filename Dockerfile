FROM elixir:1.18-otp-27

# Install Node.js 20 and inotify-tools (for live reload)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs inotify-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install hex and rebar
RUN mix local.hex --force && mix local.rebar --force

WORKDIR /app

# Copy dependency files first for layer caching
COPY mix.exs mix.lock ./

RUN mix deps.get

# Copy the rest of the app
COPY . .

EXPOSE 4000

CMD ["mix", "phx.server"]
