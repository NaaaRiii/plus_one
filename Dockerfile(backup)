# Use the official Ruby image as the base image
FROM ruby:3.2.2

# Install dependencies
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

# Set working directory
WORKDIR /app

# Copy the Gemfile and Gemfile.lock
COPY Gemfile* ./

# Install the gems
RUN bundle install

# Copy the rest of the application files
COPY . .

# Precompile the assets
RUN bundle exec rake assets:precompile

# Expose the port the app runs on
EXPOSE 3000

# Start the application
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]
