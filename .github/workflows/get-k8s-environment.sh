#!/bin/sh

case "$GITHUB_REF" in
    test | test-* | */test | */test-* | *-test/* | *-test)
      echo test ;;
    main)
      echo prod ;;
    *)
      echo stage ;;
esac
