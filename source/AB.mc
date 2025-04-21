// Test code for developing design pattern for separating background scope
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

(:background) class A_BG {
	protected var _b as B_BG;
	
	function initialize() {
		// some complicated logic
		_b = B_BG.newInstance();
		// some complicated logic
	}
	
	function neededInBackground() as Void {
		_b.neededInBackground();
	}
}


class B_FG extends B_BG {
	public function initialize() {
        B_BG.initialize();
	}
	function notNeededInBackground() as Void {}
}

(:background) class B_BG {

	(:typecheck(disableBackgroundCheck))
    public static function newInstance() as B_BG {
        if( EvccApp.isBackground ) {
            return new B_BG();
        } else {
            return new B_FG();
        }
    }

	public function initialize() {
	}

	function neededInBackground() as Void {}
}


class B_X {
    public static function getInstance() as B_X {
        return new B_X();
    }
    private function initialize() {}
}
*/