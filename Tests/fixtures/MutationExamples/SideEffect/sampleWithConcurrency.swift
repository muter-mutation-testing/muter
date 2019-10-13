struct Async {
    private let semaphore = DispatchSemaphore(value: 1)
    private let conditionLock = NSConditionLock(condition: 0)
    private let lock = NSRecursiveLock()
    private let condition = NSCondition()
    
    private func semaphoreLock(block: () -> Void) {
        defer{ semaphore.signal() }
        semaphore.wait()
        block()
    }
    
    private func recursiveLock(block: () -> Void) {
        defer { lock.unlock() }
        lock.lock()
        block()
    }
    
    private func nsCondition(block: () -> Void) {
        defer { condition.signal() }
        condition.wait()
        block()
    }
    
    private func nsConditionLock(block: () -> Void) {
        defer { conditionLock.unlock(withCondition: 1) }
        conditionLock.lock(whenCondition: 1)
        block()
    }

    private func sync(block: () -> Int) -> Int {
    	let semaphore = DispatchSemaphore(value: 2)
    	semaphore.wait()
    	let value = block()
    	semaphore.signal()

    	return value
    }
}