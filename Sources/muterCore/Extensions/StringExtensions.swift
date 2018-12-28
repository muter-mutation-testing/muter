extension String {
	func repeated(_ times: Int) -> String {
		return (0 ..< times).reduce("") { current, _ in current + "\(self)"}
	}
}
