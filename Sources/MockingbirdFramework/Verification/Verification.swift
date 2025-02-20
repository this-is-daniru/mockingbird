import Foundation
import XCTest

/// Verify that a declaration was called.
///
/// Verification lets you assert that a mock received a particular invocation during its lifetime.
///
/// ```swift
/// verify(bird.doMethod()).wasCalled()
/// verify(bird.getProperty()).wasCalled()
/// verify(bird.setProperty(any())).wasCalled()
/// ```
///
/// You can match exact or wildcard argument values when verifying.
///
/// ```swift
/// verify(bird.canChirp(volume: any())).wasCalled()     // Called with any volume
/// verify(bird.canChirp(volume: notNil())).wasCalled()  // Called with any non-nil volume
/// verify(bird.canChirp(volume: 10)).wasCalled()        // Called with volume = 10
/// ```
///
/// - Parameters:
///   - mock: A mocked declaration to verify.
public func verify<DeclarationType: Declaration, InvocationType, ReturnType>(
  _ declaration: Mockable<DeclarationType, InvocationType, ReturnType>,
  file: StaticString = #file, line: UInt = #line
) -> VerificationManager<InvocationType, ReturnType> {
  return VerificationManager(with: declaration, at: SourceLocation(file, line))
}

/// Verify that an Objective-C mock or property declaration was called.
///
/// Verification lets you assert that a mock received a particular invocation during its lifetime.
///
/// ```swift
/// verify(bird.doMethod()).wasCalled()
/// verify(bird.getProperty()).wasCalled()
/// verify(bird.setProperty(any())).wasCalled()
/// ```
///
/// You can match exact or wildcard argument values when verifying.
///
/// ```swift
/// verify(bird.canChirp(volume: any())).wasCalled()     // Called with any volume
/// verify(bird.canChirp(volume: notNil())).wasCalled()  // Called with any non-nil volume
/// verify(bird.canChirp(volume: 10)).wasCalled()        // Called with volume = 10
/// ```
///
/// - Parameters:
///   - mock: A mocked declaration to verify.
public func verify<ReturnType>(
  _ declaration: @autoclosure () throws -> ReturnType,
  file: StaticString = #file, line: UInt = #line
) -> VerificationManager<Any?, ReturnType> {
  let recorder = InvocationRecorder(mode: .verifying).startRecording(block: {
    /// `EXC_BAD_ACCESS` usually happens when mocking a Swift type that inherits from `NSObject`.
    ///   - Make sure that the Swift type has a generated mock, e.g. `SomeTypeMock` exists.
    ///   - If you actually do want to use Obj-C dynamic mocking with a Swift type, the method must
    ///     be annotated with both `@objc` and `dynamic`, e.g. `@objc dynamic func someMethod()`.
    ///   - If this is happening on a pure Obj-C type, please file a bug report with the stack
    ///     trace: https://github.com/birdrides/mockingbird/issues/new/choose
    _ = try? declaration()
  })
  switch recorder.result {
  case .value(let record):
    return VerificationManager(from: record, at: SourceLocation(file, line))
  case .error(let error):
    preconditionFailure(FailTest("\(error)", isFatal: true, file: file, line: line))
  case .none:
    preconditionFailure(
      FailTest("\(TestFailure.unmockableExpression)", isFatal: true, file: file, line: line))
  }
}

/// An intermediate object used for verifying declarations returned by `verify`.
public class VerificationManager<InvocationType, ReturnType> {
    let context: Context
    let invocation: Invocation
    let sourceLocation: SourceLocation

    init<DeclarationType>(with declaration: Mockable<DeclarationType, InvocationType, ReturnType>,
                          at sourceLocation: SourceLocation) {
        self.context = declaration.context
        self.invocation = declaration.invocation
        self.sourceLocation = sourceLocation
  }

    init(from record: InvocationRecord, at sourceLocation: SourceLocation) {
        self.context = record.context
        self.invocation = record.invocation
        self.sourceLocation = sourceLocation
    }

    /// Verify the number of times that the mock received the invocation.
    ///
    /// - Parameter countMatcher: A count matcher defining the number of invocations to verify.
    public func callCount() -> Int {
        return invocationCount(context.mocking, handled: invocation)
    }

    /// Verify that the mock received the invocation some number of times.
    ///
    /// - Parameter times: An optional number to verify against actual call count. Default value: 1
    public func wasCalled(times: Int = 1) -> Bool {
        return callCount() == times
    }

    /// - Parameter type: The return type of the declaration to verify.
    public func returning(_ type: ReturnType.Type = ReturnType.self) -> Self {
        return self
    }
}

/// Filters recorded invocations by upper and lower invocation bounds.
func findInvocations(in mockingContext: MockingContext,
                     with selectorName: String,
                     before nextInvocation: Invocation?,
                     after baseInvocation: Invocation?) -> [Invocation] {
  return mockingContext
    .invocations(with: selectorName)
    .filter({ invocation in
      var isBeforeNextInvocation: Bool {
        guard let nextInvocation = nextInvocation else { return true }
        return invocation.uid < nextInvocation.uid
      }
      var isAfterBaseInvocation: Bool {
        guard let baseInvocation = baseInvocation else { return true }
        return invocation.uid > baseInvocation.uid
      }
      return isBeforeNextInvocation && isAfterBaseInvocation
    })
}

@discardableResult
func invocationCount(_ mockingContext: MockingContext,
            handled invocation: Invocation,
            before nextInvocation: Invocation? = nil,
            after baseInvocation: Invocation? = nil) -> Int {
  let allInvocations = findInvocations(in: mockingContext,
                                       with: invocation.selectorName,
                                       before: nextInvocation,
                                       after: baseInvocation)
  let allMatchingInvocations = allInvocations.filter({ $0.isEqual(to: invocation) })

  let actualCallCount = allMatchingInvocations.count
    return actualCallCount
}
