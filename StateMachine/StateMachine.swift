/// Source:
/// https://github.com/narfdotpl/SwiftyStateMachine
/// http://macoscope.com/blog/swifty-state-machine/
/// https://www.youtube.com/watch?v=GKMrJe3mfwU
/// https://www.youtube.com/watch?v=kBjqenUQvlU

/// A type representing schema that can be reused by `StateMachine`
/// instances.
///
/// The schema incorporates three generic types: `State` and `Event`,
/// which should be `enum`s, and `Interacotor`, which represents an object
/// associated with a state machine.  If you don't want to associate any
/// object, use `Void` as `Interacotor` type.
///
/// The schema indicates the initial state and describes the transition
/// logic, i.e. how states are connected via events and what code is
/// executed during state transitions.  You specify transition logic
/// as a block that accepts two arguments: the current state and the
/// event being handled.  It returns an optional tuple of a new state
/// and an optional transition block.  When the tuple is `nil`, it
/// indicates that there is no transition for a given state-event pair,
/// i.e. a given event should be ignored in a given state.  When the
/// tuple is non-`nil`, it specifies the new state that the machine
/// should transition to and a block that should be called after the
/// transition.  The transition block is optional and it gets passed
/// the `Interactor` object as an argument.

public enum StateMachineTransitionDirection {
    case forward
    case back
    case idle
}

public protocol IDirectionDeterminable {
    func determineDirection(previousState: Self) -> StateMachineTransitionDirection
}

public protocol IStateMachineSchema {
    associatedtype State: IDirectionDeterminable
    associatedtype Event
    associatedtype Interactor

    var initialState: State { get }
    var transitionLogic: (_ currentState: State, _ event: Event) -> ((_ transitionToNextState: Interactor) -> (State))? { get }

    init(
        initialState: State,
        transitionLogic: @escaping (_ currentState: State, _ event: Event) -> ((_ transitionToNextState: Interactor) -> (State))? )
}

/// A state machine schema conforming to the `IStateMachineSchema`
/// protocol.  See protocol documentation for more information.
public struct StateMachineSchema<A: IDirectionDeterminable, B, C>: IStateMachineSchema {
    public typealias State = A
    public typealias Event = B
    public typealias Interactor = C

    public let initialState: State
    public let transitionLogic: (_ currentState: State, _ event: Event) -> ((_ transitionToNextState: Interactor) -> (State))?

    public init(
        initialState: State,
        transitionLogic: @escaping (_ currentState: State, _ event: Event) -> ((_ transitionToNextState: Interactor) -> (State))? ) {
        self.initialState = initialState
        self.transitionLogic = transitionLogic
    }
}

/// A state machine for a given schema, associated with a given interactor.  See
/// `IStateMachineSchema` documentation for more information about schemas
/// and interactors.
///
/// References to class-based interactors are weak.  This helps to remove
/// interactor-machine reference cycles, but it also means you have to keep a
/// strong reference to a interactor somewhere else.  When interactor references
/// become `nil`, transitions are no longer performed.
///
/// The state machine provides the `state` property for inspecting the current
/// state and the `handleEvent` method for triggering state transitions
/// defined in the schema.
///
/// To get notified about state changes, provide a `didTransitionCallback`
/// block.  It is called after a transition with three arguments:
/// -the state before the transition,
/// -the event causing the transition,
/// -and the state after the transition.
public final class StateMachine<Schema: IStateMachineSchema> {
    /// states of the machine.
    public private(set) var currentState: Schema.State
    public private(set) var previousState: Schema.State
    
    /// The transition direction of the machine.
    public private(set) var transitionDirection: StateMachineTransitionDirection

    /// An optional block called after a transition with three arguments:
    /// -the state before the transition,
    /// -the event causing the transition,
    /// -and the state after the transition.
    public var didTransitionCallback: ((_ previousState: Schema.State, _ event: Schema.Event, _ currentState: Schema.State, _ transitionDirecion: StateMachineTransitionDirection) -> ())?

    /// The schema of the state machine.  See `IStateMachineSchema`
    /// documentation for more information.
    private let schema: Schema

    /// Object associated with the state machine.  Can be accessed in
    /// transition blocks.  Closure used to allow for weak references.
    private let interactor: () -> Schema.Interactor?

    private init(
        schema: Schema,
        interactor: @escaping () -> Schema.Interactor?,
        didTransitionCallback: ((_ previousState: Schema.State, _ event: Schema.Event, _ currentState: Schema.State, _ transitionDirecion: StateMachineTransitionDirection) -> ())? = nil) {
        self.currentState = schema.initialState
        self.previousState = schema.initialState
        self.transitionDirection = .forward
        self.schema = schema
        self.interactor = interactor
        self.didTransitionCallback = didTransitionCallback
    }

    /// A method for triggering transitions and changing the state of the
    /// machine.  Transitions are not performed when a weak reference to the interactor
    /// becomes `nil`.  If the transition logic of the schema defines a transition
    /// for current state and given event, the state is changed, the optional
    /// transition block is executed, and `didTransitionCallback` is called.
    public func handleEvent(event: Schema.Event) {
        guard
            let interactor = interactor(),
            let transitionToNextState = schema.transitionLogic(currentState, event)
        else {
            return
        }

        previousState = currentState
        currentState = transitionToNextState(interactor)
        transitionDirection = currentState.determineDirection(previousState: previousState)

        didTransitionCallback?(previousState, event, currentState, transitionDirection)
    }
}

public extension StateMachine where Schema.Interactor: AnyObject {
    /// Creates a state machine with a weak reference to a interactor.  This helps
    /// to remove interactor-machine reference cycles, but it also means you have
    /// to keep a strong reference to a interactor somewhere else.  When interactor
    /// reference becomes `nil`, transitions are no longer performed.
    public convenience init(
        schema: Schema,
        interactor: Schema.Interactor,
        didTransitionCallback: ((_ previousState: Schema.State, _ event: Schema.Event, _ currentState: Schema.State, _ transitionDirecion: StateMachineTransitionDirection) -> ())? = nil) {
        self.init(
            schema: schema,
            interactor: { [weak interactor] in interactor },
            didTransitionCallback: didTransitionCallback)
    }
}

public extension StateMachine {
    public convenience init(
        schema: Schema,
        interactor: Schema.Interactor,
        didTransitionCallback: ((_ previousState: Schema.State, _ event: Schema.Event, _ currentState: Schema.State, _ transitionDirecion: StateMachineTransitionDirection) -> ())? = nil) {
        self.init(
            schema: schema,
            interactor: { interactor },
            didTransitionCallback: didTransitionCallback)
    }
}
