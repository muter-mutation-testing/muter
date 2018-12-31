struct Table: CustomStringConvertible, Equatable {
	static let empty = Table(padding: 0, columns: [])

	let padding: Int
	let columns: [Column]
	
	var description: String {
		return columns.enumerated().accumulate(into: "") {
			let columnIndex = $1.offset
			let column = $1.element
			let previousColumn = columns[max(0, columnIndex - 1)]
			
			var alreadyRenderedTableSplitByLine = $0.split(separator: "\n")
			
			let previousColumnRows = previousColumn.description.split(separator: "\n")
			let columnRows = column.description.split(separator: "\n")
			
			return zip(previousColumnRows, columnRows).accumulate(into: "") { workingValue, currentRows in
				let previousRowWidth = currentRows.0.count
				let newRow = currentRows.1
				
				let nextLineThatsBeenRendered = alreadyRenderedTableSplitByLine.first ?? ""
				alreadyRenderedTableSplitByLine = Array(alreadyRenderedTableSplitByLine.dropFirst())
				
				let padding = paddingForColumn(at: columnIndex,
											   previousColumnWidth: previousColumn.width,
											   previousRowWidth: previousRowWidth)
				
				return workingValue + "\(nextLineThatsBeenRendered)" + padding + newRow + "\n"
			}
		}
	}
	
	private func paddingForColumn(at index: Int, previousColumnWidth: Int, previousRowWidth: Int) -> String {
		let lengthOfPadding = previousColumnWidth - previousRowWidth
		return index == 0 ? "" : " ".repeated(lengthOfPadding + self.padding)
	}
}

extension Table {
	
	struct Column: CustomStringConvertible, Equatable {
		let title: String
		let rows: [Row]
		var width: Int {
			let stringLengths = rows.map { $0.value.count } + [title.count]
			return stringLengths.reduce(0, max)
		}
		
		var description: String {
			
			guard rows.count >= 1 else {
				return ""
			}
			
			let content = rows.accumulate(into: "") { $0 + "\($1.value)\n" }
			
			let numberOfDashes = title.count
			let dashes = "-".repeated(numberOfDashes)
			
			return """
			\(title)
			\(dashes)
			\(content)
			"""
		}
	}
	
	struct Row: Equatable {
		let value: String
	}
}
