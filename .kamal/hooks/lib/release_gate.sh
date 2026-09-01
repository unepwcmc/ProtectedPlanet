#!/usr/bin/env bash
# Shared portal-release deploy gate, sourced by pre-build and pre-deploy.
#
# Not a hook itself — Kamal only executes files it knows by name, so this lives
# in a subdirectory to keep that unambiguous.
#
# A release is a single long-lived rake process (lib/tasks/portal_release.rake).
# Whether it was started with `kamal app exec --reuse` or `docker exec` into the
# live web container, `kamal deploy` stops every container carrying the app's
# service/destination/role labels, so boot kills it mid-phase. The process is
# SIGKILLed, so the rescue/ensure in PortalRelease::Service#run! never runs: the
# release row is stranded in a non-terminal state and no Slack error is sent.
#
# There is deliberately NO override and no soft path. A deploy during a release is
# never the right call: wait for it, or abort the release first. Anyone who
# reintroduces an opt-out should expect it to be used reflexively, which is the
# same as not having this gate.
#
# FAIL CLOSED, IN BOTH STAGES. If the check cannot run at all — container down,
# task missing from the image, a kamal without --reuse — that blocks the deploy
# too, because "cannot tell" and "a release is running" are indistinguishable
# from here and only one of them is safe to guess. The escape hatch is
# `kamal deploy --skip-hooks` (which also skips db:migrate and the cache flush),
# not a branch in this file.

# check_portal_release <kamal app exec target flags...>
#
# The arguments exist for one reason: the two call sites must exec DIFFERENT
# containers. They do not vary the behaviour — both block on any failure.
#
#   pre-build   --reuse                     the new image does not exist yet, so
#                                           this runs the OLD code in the live
#                                           container. Fine: the gate only reads a
#                                           fixed advisory-lock number
#                                           (PortalRelease::LOCK_KEY).
#   pre-deploy  --version "$KAMAL_VERSION"  a one-off container from the image
#                                           about to go live. Also the only call
#                                           that catches a release started
#                                           mid-build.
check_portal_release() {
  local output status stage
  stage=$(basename "$0")

  [[ $# -gt 0 ]] || { echo "check_portal_release: no target flags given" >&2; return 1; }

  echo "==> Checking whether a portal release is running (${stage})"

  set +e
  output=$(kamal app exec \
    ${KAMAL_DESTINATION:+--destination "$KAMAL_DESTINATION"} \
    --primary \
    --roles web \
    "$@" \
    "bundle exec rake pp:portal:deploy_gate" 2>&1)
  status=$?
  set -e

  echo "$output"

  if [[ $status -eq 0 ]]; then
    echo "==> No release running"
    return 0
  fi

  if grep -q "A portal release is currently running" <<<"$output"; then
    echo "!!! DEPLOY BLOCKED — a portal release is currently running."
    echo "!!!"
    echo "!!! Deploying would replace the app containers and kill the release mid-phase,"
    echo "!!! leaving it stranded with no failure notification."
  else
    echo "!!! DEPLOY BLOCKED — the release gate could not run (exit ${status}, ${stage})."
    echo "!!!"
    echo "!!! This is not a pass. The gate output is above; until it can answer, a release"
    echo "!!! could be running and a deploy would kill it mid-phase."
  fi

  echo "!!!"
  echo "!!! Check or abort the release:"
  echo "!!!   check:    kamal app exec -d ${KAMAL_DESTINATION:-staging} --primary --roles web \"bundle exec rake pp:portal:status\""
  echo "!!!   abort it: kamal app exec -d ${KAMAL_DESTINATION:-staging} --primary --roles web \"bundle exec rake pp:portal:abort\""
  return 1
}
