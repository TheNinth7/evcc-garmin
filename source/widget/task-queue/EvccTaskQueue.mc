import Toybox.Lang;
import Toybox.Timer;

// CIQ apps are single-threaded and implement a kind of event queue,
// in which events such as user input, timers or web responses are processed.
// During the processing of an event others are blocked, which is especially
// noticable with processing of user input being delayed.
// Larger tasks should therefore be split into smaller ones and be processed
// separately, with room inbetween to execute user inputs.
// This task queue supports that. Tasks can be added to the queue and between 
// each task and the next, there will be a timer, which basically ends
// the current event processing and allows other events in the CIQ queue to
// be processed

// A task can be a Toybox.lang.Method, or any other class that has
// in invoke function
typedef EvccTask as interface {
    function invoke() as Void;
};

(:exclForViewPreRenderingDisabled)
class EvccTaskQueue {

    // The event queue is a Singleton
    private static var _instance as EvccTaskQueue?;
    public static function getInstance() as EvccTaskQueue {
        if( _instance == null ) { _instance = new EvccTaskQueue(); }
        return _instance as EvccTaskQueue;
    }
    // Constructor is needed only to declare it private, to ensure
    // it can not be instantiated from the outside
    private function initialize() {}

    // Tasks are added as EvccTask objects
    private var _tasks as Array<EvccTask> = new Array<EvccTask>[0];
    
    // The timer that controls the task execution
    private var _timer as Timer.Timer = new Timer.Timer();
    
    // Starts the timmer for executing tasks
    private function startTimer() as Void {
        _timer.start( method( :executeTask ), 100, false );
    }

    // Add a task
    public function add( task as EvccTask ) as Void {
        _tasks.add( task );
        // If there were no tasks in the queue, start the timer
        if( _tasks.size() == 1 ) {
            startTimer();
        }
    }

    // Add a task to the front of the queue, for cases where a task
    // should skip the line and be executed at the next opportunity
    public function addToFront( task as EvccTask ) as Void {
        var tasks = new Array<EvccTask>[0];
        tasks.add( task );
        if( _tasks.size() > 0 ) {
            tasks.addAll( _tasks );
        } else {
            startTimer();
        }
        _tasks = tasks;
    }

    // Executes the task next in the queue and then
    // if there are remaining tasks, start the timer again
    public function executeTask() as Void {
        var task = _tasks[0];
        task.invoke();
        _tasks.remove( task );
        if( _tasks.size() > 0 ) {
            startTimer();
        }
    }
}

/*
class EvccTask {
    private var _method as Method;
    private var _args as Array<Object>;

    public function initialize( method as Method, args as Array<Object>? ) {
        _method = method;
        _args = args == null ? new Array<Object>[0] : args;
    }

    public function invoke() as Void {
        if( _args == null || _args.size() == 0 ) {
            _method.invoke();
        } else if (_args.size() == 1 ) {
            _method.invoke( _args[0] );
        } else if (_args.size() == 2 ) {
            _method.invoke( _args[0], _args[1] );
        } else if (_args.size() == 3 ) {
            _method.invoke( _args[0], _args[1], _args[2] );
        } else {
            throw new OperationNotAllowedException( "EvccTask: too many arguments!" );
        }
    }
}
*/