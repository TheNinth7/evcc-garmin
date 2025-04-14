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
    
    // Stores any exception that may have occured during task execution
    private var _exception as Exception? = null;

    // Starts the timer for executing tasks
    private function startTimer() as Void {
        _timer.start( method( :executeTask ), 50, false );
    }

    // Determines if the task list ist empty
    public function isEmpty() as Boolean { return _tasks.size() == 0; }

    // Add a task
    // If a previous task resulted in an exception, new
    // tasks will be ignored
    public function add( task as EvccTask ) as Void {
        if( _exception == null ) {
            _tasks.add( task );
            // If there were no tasks in the queue, start the timer
            if( _tasks.size() == 1 ) {
                // EvccHelperBase.debug( "TaskQueue: Starting timer" );
                startTimer();
            }
            // EvccHelperBase.debug( "TaskQueue: add " + _tasks.size() );
        }
    }

    // Add a task to the front of the queue, for cases where a task
    // should skip the line and be executed at the next opportunity
    // If a previous task resulted in an exception, new
    // tasks will be ignored
    public function addToFront( task as EvccTask ) as Void {
        if( _exception == null ) {
            var tasks = new Array<EvccTask>[0];
            tasks.add( task );
            if( _tasks.size() > 0 ) {
                tasks.addAll( _tasks );
            } else {
                // EvccHelperBase.debug( "TaskQueue: Starting timer" );
                startTimer();
            }
            _tasks = tasks;
            // EvccHelperBase.debug( "TaskQueue: addToFront 1/" + _tasks.size() );
        }
    }

    // Executes the task next in the queue and then
    // if there are remaining tasks, start the timer again
    public function executeTask() as Void {
        try {
            // EvccHelperBase.debug( "TaskQueue: Executing task 1/" + _tasks.size() + " ..." );
            if( _exception != null ) {
                var task = _tasks[0];
                task.invoke();
                _tasks.remove( task );
                if( _tasks.size() > 0 ) {
                    // EvccHelperBase.debug( "TaskQueue: Starting timer" );
                    startTimer();
                }
            }
            // EvccHelperBase.debug( "TaskQueue: ... done" );
        } catch ( ex ) {
            registerException( ex );
        }
    }

    public function registerException( ex as Exception ) as Void {
        _exception = ex;
        EvccHelperBase.debugException( ex );
        _timer.stop();
    }

    // Check if an exception has occured, and if yes, throw it
    public function checkForException() as Void {
        if( _exception != null ) {
            throw _exception;
        }
    }
}
