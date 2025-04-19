/*
class A {
	private var _b as B;
	
	function initialize() {
		// some complicated logic
		_b = new B();
		// some complicated logic
	}
	
	function neededInBackground() as Void {
		_b.neededInBackground();
	}

	function notNeededInBackground() as Void {
		_b.notNeededInBackground();
	}
}

class B {
	function neededInBackground() as Void {}
	function notNeededInBackground() as Void {}
}
*/
/*

class Instantiator {
    static function instantiateB() as B_BG {
        if( EvccApp.isBackground ) {
            return new B_BG();
        } else {
            return new B_FG();
        }
    }
}

class A_FG extends A_BG {
	function initialize() {
        A_BG.initialize();
	}

    function getB_FG() as B_FG {
        return _b as B_FG;
    }
	
	function notNeededInBackground() as Void {
		getB_FG().notNeededInBackground();
	}
}

class A_BG {
	protected var _b as B_BG;
	
	function initialize() {
		// some complicated logic
		_b = Instantiator.instantiateB();
		// some complicated logic
	}
	
	function neededInBackground() as Void {
		_b.neededInBackground();
	}
}


class B_FG extends B_BG {
	function initialize() {
        B_BG.initialize();
	}
	function notNeededInBackground() as Void {}
}

class B_BG {
	function neededInBackground() as Void {}
}
*/