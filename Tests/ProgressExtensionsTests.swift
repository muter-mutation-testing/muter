import Quick
import Nimble
import Progress
@testable import muterCore

// class ProgressExtensionsSpec: QuickSpec {
//    override func spec() {
//        describe("SimpleTimeEstimate") {
//            it("estimates the time to completion based on an initial estimate and time per item") {
//                let subject = SimpleTimeEstimate(initialEstimate: 300, timePerItem: 10)
//                var progressBar = ProgressBar(count: 30)
//                
//                expect(subject.value(progressBar)) == "ETC: 5 minute(s)"
//                
//                progressBar.next()
//               
//                expect(subject.value(progressBar)) == "ETC: 5 minute(s)"
//                
//                for _ in (1...15) {
//                    progressBar.next()
//                    
//                }
//                
//                expect(subject.value(progressBar)) == "ETC: 3 minute(s)"
//                
//                for _ in (1...10) {
//                    progressBar.next()
//                    
//                }
//                
//                expect(subject.value(progressBar)) == "ETC: 1 minute(s)"
//            }
//            
//            context("when the estimate is a fraction of a minute") {
//                it("rounds up to the nearest minute") {
//                    let subject = SimpleTimeEstimate(initialEstimate: 325, timePerItem: 10)
//                    var progressBar = ProgressBar(count: 32)
//                    
//                    expect(subject.value(progressBar)) == "ETC: 6 minute(s)"
//                    
//                    progressBar.next()
//                    
//                    expect(subject.value(progressBar)) == "ETC: 6 minute(s)"
//                }
//            }
//            context("when the actual estimate differs from the initial estimate") {
//                it("estimates based on the new information") {
//                    let subject = SimpleTimeEstimate(initialEstimate: 3, timePerItem: 10)
//                    var progressBar = ProgressBar(count: 30)
//                    expect(subject.value(progressBar)) == "ETC: 1 minute(s)"
//                    
//                    progressBar.next()
//                    
//                    expect(subject.value(progressBar)) == "ETC: 5 minute(s)"
//                }
//            }
//        }
//    }
// }
//
