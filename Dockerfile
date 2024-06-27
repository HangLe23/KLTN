# Stage 1: Build the Flutter client
FROM cirrusci/flutter:latest as flutter_builder

# Set the working directory
WORKDIR /KLTN/client

# Copy the Flutter client source code
COPY client/ .

# Get Flutter dependencies
#RUN flutter pub get

# Build the Flutter web app
RUN flutter build web

# Stage 2: Set up the Node.js server
FROM node:14 as server_builder

# Set the working directory
WORKDIR /KLTN/server

# Copy the server source code
COPY server/package*.json ./

# Install server dependencies
RUN npm install

# Copy the rest of the server code
COPY server/ .

# Copy the Flutter build output to the server's public directory
COPY --from=flutter_builder /KLTN/client/build/web /KLTN/server/public-flutter

# Expose the port on which the server will run
EXPOSE 8000

# Define the command to run the server
CMD ["node", "index.js"]
