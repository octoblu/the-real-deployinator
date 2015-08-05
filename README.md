# Deployinator
Deployinator for deployinate

# Install
```
npm install -g deployinator
```

# Environment

DEPLOYINATOR_UUID='...'
DEPLOYINATOR_TOKEN='...'
DEPLOYINATOR_HOST='...'
DEPLOYINATOR_DOCKER_PASS='...'

# Usage

## Deploy

Deploy an app.

```
deployinator deploy triggers-service -t v1.0.0
```

## Check the status

Check the status of an app.

```
deployinator status triggers-service -t v1.0.0
```
