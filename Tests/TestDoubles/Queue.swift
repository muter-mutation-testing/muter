import Foundation

public class Queue<A> {
    private var head: Node<A>?
    private var tail: Node<A>?

    public var isEmpty: Bool { head == nil }
    public private(set) var count = 0

    public func enqueue(_ value: A) {
        if isEmpty {
            head = Node(value)
            tail = head
        } else {
            let node = Node(value)
            tail?.next = node
            tail = tail?.next
        }

        count += 1
    }

    @discardableResult public func dequeue() -> A? {
        guard !isEmpty else {
            return nil
        }

        let node = head

        head = head?.next

        count -= 1

        return node?.value
    }
}

extension Queue {
    private class Node<B> {
        var value: B
        var next: Node<B>?

        init(_ value: B) {
            self.value = value
        }
    }
}
