import cpp.Native;
import cpp.Callable;
import cpp.ConstCharStar;
import cpp.ConstStar;
import cpp.Pointer;
import cpp.SizeT;
import cpp.Star;

@:buildXml('
<files id="haxe">
	<compilerflag value="-fno-omit-frame-pointer" />
	<compilerflag value="-fsanitize=address" />
</files>
<linker id="dll">
	<flag value="-fno-omit-frame-pointer" />
	<flag value="-fsanitize=address" />
</linker>
')
class Main {

	static var s: Int;

	static function main() {
		trace('main()');
		pack.ExampleClass;

		var i = 0;
		function loop() {
			trace('loop ${i++} ${s++}');
			haxe.Timer.delay(loop, 1000);
		}
		loop();
	}

}

typedef CustomStarX = haxe.Timer;
typedef CustomStar<T> = cpp.Star<T>;
typedef CppVoidX = AliasA;
typedef AliasA = cpp.Void;
typedef FunctionAlias = (ptr: CustomStar<Int>) -> String;

enum abstract IntEnumAbstract(Int) {
	var A;
	var B;
	function shouldNotAppearInC() {}
	static var ThisShouldNotAppearInC: String;
}

enum abstract IndirectlyReferencedEnum(Int) {
	var AAA = 9;
	var BBB;
	var CCC = 8;
}

typedef EnumAlias = IntEnumAbstract;

enum abstract StringEnumAbstract(String) {
	var A = "AAA";
	var B = "BBB";
}

enum RegularEnum {
	A;
	B;
}

@:build(HaxeEmbed.build(''))
@:native('test.HxPublicApi')
class PublicCApi {

	/**
		Some doc
		@param a some integer
		@param b some string
		@returns void
	**/
	static public function voidRtn(a: Int, b: String): Void {}

	static public function noArgsNoReturn(): Void { }

	/** when called externally from C this function will be executed synchronously on the main thread **/
	static public function callInMainThread(f64: cpp.Float64): Bool {
		return HaxeEmbed.isMainThread();
	}

	/**
		When called externally from C this function will be executed on the calling thread.
		Beware: you cannot interact with the rest of your code without first synchronizing with the main thread (or risk crashes)
	**/
	@externalThread
	static public function callInExternalThread(f64: cpp.Float64): Bool {
		return !HaxeEmbed.isMainThread();
	}

	static public function add(a: Int, b: Int): Int return a + b;

	static public function starPointers(
		starVoid: Star<cpp.Void>, 
		starVoid2: Star<CppVoidX>,
		customStar: CustomStar<CppVoidX>,
		customStar2: CustomStar<CustomStar<Int>>,
		constStarVoid: ConstStar<cpp.Void>,
		starInt: Star<Int>,
		constCharStar: ConstCharStar
	): Star<Int> {
		var str: String = constCharStar;
		Native.set(starInt, str.length);
		return starInt;
	}

	static public function rawPointers(
		rawPointer: cpp.RawPointer<cpp.Void>,
		rawInt64Pointer: cpp.RawPointer<cpp.Int64>,
		rawConstPointer: cpp.RawConstPointer<cpp.Void>
	): cpp.RawPointer<cpp.Void> {
		return rawPointer;
	}

	static public function hxcppPointers(
		assert: Callable<Bool -> Void>,
		pointer: cpp.Pointer<cpp.Void>,
		int64Array: cpp.Pointer<cpp.Int64>,
		int64ArrayLength: Int,
		constPointer: cpp.ConstPointer<cpp.Void>
	): cpp.Pointer<cpp.Int64> {
		var array = int64Array.toUnmanagedArray(int64ArrayLength);
		assert(array.join(',') == '1,2,3');
		return int64Array;
	}

	static public function hxcppCallbacks(
		assert: Callable<Bool -> Void>,
		voidVoid: Callable<() -> Void>,
		voidInt: Callable<() -> Int>,
		intString: Callable<(a: Int) -> String>,
		stringInt: Callable<(String) -> Int>,
		pointers: Callable<(Pointer<Int>) -> Pointer<Int>>,
		fnAlias: Callable<FunctionAlias>
	): Callable<(a: Int) -> String> {
		var hi = intString(42);
		assert(hi == "hi");
		var i = 42;
		var ip = Pointer.fromStar(Native.addressOf(i));
		var result = pointers(ip);
		assert(result == ip);
		assert(i == 21);
		return intString;
	}

	static public function externStruct(v: MessagePayload): MessagePayload {
		v.someFloat *= 2;
		return v;
	}

	// optional not supported; all args are required when calling from C
	static public function optional(?single: Single): Void { }
	static public function badOptional(?opt: Single, notOpt: Single): Void { }

	static public function enumTypes(e: IntEnumAbstract, s: StringEnumAbstract, a: EnumAlias, i: Star<IndirectlyReferencedEnum>, ii: Star<Star<IndirectlyReferencedEnum>>): Void { }
	static public function cppCoreTypes(sizet: SizeT, char: cpp.Char, constCharStar: cpp.ConstCharStar): Void { }

	/** single-line doc **/
	static public function somePublicMethod(i: Int, f: Float, s: Single, i8: cpp.Int8, i16: cpp.Int16, i32: cpp.Int32, i64: cpp.Int64, ui64: cpp.UInt64, str: String): Int {
		trace('somePublicMethod()');
		return -1;
	}

	static public function throwException(): Void {
		throw 'example exception';
	}

	// the following should be disallowed at compile-time
	// static public function haxeCallbacks(voidVoid: () -> Void, intString: (a: Int) -> String): Void { }
	// static public function reference(ref: cpp.Reference<Int>): Void { }
	// static public function anon(a: {f1: Star<cpp.Void>, ?optF2: Float}): Void { }
	// static public function array(arrayInt: Array<Int>): Void { }
	// static public function nullable(f: Null<Float>): Void {}
	// static public function dyn(dyn: Dynamic): Void {}

}