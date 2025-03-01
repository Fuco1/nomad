schema = "1"

project "nomad" {
  team = "nomad"
  slack {
    // #feed-nomad-releases
    notification_channel = "C03B5EWFW01"
    // #proj-nomad-releases
    // notification_channel = "CUYKT2A73"
  }
  github {
    organization = "hashicorp"
    repository   = "nomad"
    release_branches = [
      "main",
      "release/1.0.x",
      "release/1.1.x",
      "release/1.2.x",
      "release/1.3.x",
    ]
  }
}

event "merge" {
  // "entrypoint" to use if build is not run automatically
  // i.e. send "merge" complete signal to orchestrator to trigger build
}

event "build" {
  depends = ["merge"]
  action "build" {
    organization = "hashicorp"
    repository   = "nomad"
    workflow     = "build"
  }
}

event "upload-dev" {
  depends = ["build"]
  action "upload-dev" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "upload-dev"
  }

  notification {
    on = "fail"
  }
}

event "security-scan-binaries" {
  depends = ["upload-dev"]
  action "security-scan-binaries" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "security-scan-binaries"
    config       = "security-scan.hcl"
  }

  notification {
    on = "fail"
  }
}

event "notarize-darwin-amd64" {
  depends = ["security-scan-binaries"]
  action "notarize-darwin-amd64" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "notarize-darwin-amd64"
  }

  notification {
    on = "fail"
  }
}

event "notarize-darwin-arm64" {
  depends = ["notarize-darwin-amd64"]
  action "notarize-darwin-arm64" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "notarize-darwin-arm64"
  }

  notification {
    on = "fail"
  }
}

event "notarize-windows-386" {
  depends = ["notarize-darwin-arm64"]
  action "notarize-windows-386" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "notarize-windows-386"
  }

  notification {
    on = "fail"
  }
}

event "notarize-windows-amd64" {
  depends = ["notarize-windows-386"]
  action "notarize-windows-amd64" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "notarize-windows-amd64"
  }

  notification {
    on = "fail"
  }
}

event "sign" {
  depends = ["notarize-windows-amd64"]
  action "sign" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "sign"
  }

  notification {
    on = "fail"
  }
}

event "sign-linux-rpms" {
  depends = ["sign"]
  action "sign-linux-rpms" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "sign-linux-rpms"
  }

  notification {
    on = "fail"
  }
}

event "verify" {
  depends = ["sign-linux-rpms"]
  action "verify" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "verify"
  }

  notification {
    on = "always"
  }
}

## These are promotion and post-publish events
## they should be added to the end of the file after the verify event stanza.

event "trigger-staging" {
  // This event is dispatched by the bob trigger-promotion command
  // and is required - do not delete.
}

event "promote-staging" {
  depends = ["trigger-staging"]
  action "promote-staging" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "promote-staging"
  }

  notification {
    on = "always"
  }
}

event "trigger-production" {
  // This event is dispatched by the bob trigger-promotion command
  // and is required - do not delete.
}

event "promote-production" {
  depends = ["trigger-production"]
  action "promote-production" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "promote-production"
  }

  notification {
    on = "always"
  }
}

event "promote-production-packaging" {
  depends = ["promote-production"]
  action "promote-production-packaging" {
    organization = "hashicorp"
    repository   = "crt-workflows-common"
    workflow     = "promote-production-packaging"
  }

  notification {
    on = "always"
  }
}
