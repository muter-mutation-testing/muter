func betaLane() {
    desc("Submit a new Beta Build to Apple TestFlight. This will also make sure the profile is up to date")

    syncCodeSigning(gitUrl: "URL/for/your/git/repo", appIdentifier: [appIdentifier], username: appleID)
    // Build your app - more options available
    buildIosApp(scheme: "SchemeName")
    uploadToTestflight(username: appleID)
    // You can also use other beta testing services here (run `fastlane actions`)
}
