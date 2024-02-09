FROM maven:3.8.4-jdk-8-slim

# Update dependencies
RUN apt-get update

# Copy the source code
ADD . /

# Build the executable
RUN ["mvn", "clean", "package"]

# Run the java application on start
CMD ["java -jar ./target/login-0.1.0.jar"]


# Use this as the entrypoint
ENTRYPOINT ["/bin/bash", "-c"]
