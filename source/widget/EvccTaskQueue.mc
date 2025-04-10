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
(:exclForViewPreRenderingDisabled)
public class EvccTaskQueue {

    // The event queue is a Singleton
    private static var _instance as EvccTaskQueue?;
    public static function getInstance() as EvccTaskQueue {
        if( _instance == null ) { _instance = new EvccTaskQueue(); }
        return _instance as EvccTaskQueue;
    }

    // Tasks are added as Method objects
    private var _methods as Array<Method> = new Array<Method>[0];
    
    // The timer that controls the task execution
    private var _timer as Timer.Timer = new Timer.Timer();
    
    // Starts the timmer for executing tasks
    private function startTimer() as Void {
        _timer.start( method( :executeMethod ), 100, false );
    }

    // Add a task
    public function add( method as Method ) as Void {
        _methods.add( method );
        // If there were no tasks in the queue, start the timer
        if( _methods.size() == 1 ) {
            startTimer();
        }
    }

    // Add a task to the front of the queue, for cases where a task
    // should skip the line and be executed at the next opportunity
    public function addToFront( method as Method ) as Void {
        var methods = new Array<Method>[0];
        methods.add( method );
        if( _methods.size() > 0 ) {
            methods.addAll( _methods );
        } else {
            startTimer();
        }
        _methods = methods;
    }

    // Executes the task next in the queue and then
    // if there are remaining tasks, start the timer again
    public function executeMethod() as Void {
        var method = _methods[0];
        method.invoke();
        _methods.remove( method );
        if( _methods.size() > 0 ) {
            startTimer();
        }
    }
}
