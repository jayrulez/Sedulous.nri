namespace nri.sampleTriangle;

class Program
{
	struct MyStruct{
		public int x = 0;
		public int y = 0;
	}

	private static MyStruct myS;

	public static void Test(MyStruct s){
		myS = s;

		myS.x = 1;
		myS.y = 2;
	}

	public static void Main(){

		MyStruct s = .();

		Test(s);


		var app = scope TriangleApplication("Triangle", 1280, 720);

		app.Run();
	}
}