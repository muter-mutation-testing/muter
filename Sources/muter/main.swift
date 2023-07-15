import enum muterCore.Muter

Task {
    await Muter.start()
    exit(0)
}

RunLoop.current.run()
