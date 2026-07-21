#!/bin/sh

APP_DIR=/app
SITE_CONTAINER=daimyspapen.com
NODE_IMAGE=node:24-alpine

git config --global --add safe.directory "$APP_DIR"

# Add origin if it doesn't exist, otherwise update it
git -C "$APP_DIR" remote add origin https://github.com/DaimySpapen/daimyspapen.com.git 2>/dev/null || \
git -C "$APP_DIR" remote set-url origin https://github.com/DaimySpapen/daimyspapen.com.git

reinstall_dependencies() {
  echo "$(date): Reinstalling npm packages..."
  docker run --rm \
    --volumes-from "$SITE_CONTAINER" \
    -w "$APP_DIR" \
    "$NODE_IMAGE" \
    npm ci --omit=dev
}

restart_site() {
  echo "$(date): Restarting site container..."
  docker restart "$SITE_CONTAINER"
}

deploy_revision() {
  target_head="$1"

  if [ "$target_head" = "none" ]; then
    echo "$(date): Failed to determine the latest remote revision."
    return 1
  fi

  echo "$(date): Change detected, updating to $target_head..."
  if ! git -C "$APP_DIR" reset --hard "$target_head"; then
    echo "$(date): Failed to update repository."
    return 1
  fi

  if ! reinstall_dependencies; then
    echo "$(date): Failed to reinstall npm packages."
    return 1
  fi

  if ! restart_site; then
    echo "$(date): Failed to restart site container."
    return 1
  fi

  echo "$(date): Done."
}

# Always sync to latest on startup
echo "$(date): Initial sync..."
git -C "$APP_DIR" fetch origin
CURRENT_HEAD=$(git -C "$APP_DIR" rev-parse HEAD 2>/dev/null || echo "none")
TARGET_HEAD=$(git -C "$APP_DIR" rev-parse origin/main 2>/dev/null || echo "none")
deploy_revision "$TARGET_HEAD"
echo "$(date): Initial sync done."

echo "Deploy watcher started. Checking every 5 minutes..."

while true; do
  CURRENT_HEAD=$(git -C "$APP_DIR" rev-parse HEAD 2>/dev/null || echo "none")
  echo "$(date): Fetching... (local: $CURRENT_HEAD)"

  git -C "$APP_DIR" fetch origin

  TARGET_HEAD=$(git -C "$APP_DIR" rev-parse origin/main 2>/dev/null || echo "none")
  echo "$(date): Remote head: $TARGET_HEAD"

  if [ "$CURRENT_HEAD" != "$TARGET_HEAD" ]; then
    deploy_revision "$TARGET_HEAD"
  else
    echo "$(date): No changes."
  fi

  sleep 300
done