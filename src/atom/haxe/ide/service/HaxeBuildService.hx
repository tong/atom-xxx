package atom.haxe.ide.service;

typedef HaxeBuildService = {

    /**
        args
        onMessage
        onError
        onSuccess
    */
    var build :
        Array<String>
        ->(String->Void)
        ->(String->Void)
        ->(Void->Void)
        ->Void;
}
