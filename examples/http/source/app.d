

import collie.channel;
import collie.handler.base;
import collie.booststrap.server;
import collie.codec.http;

import core.thread;
import core.runtime;
import core.memory;

import std.conv;
import std.container.array;
import std.stdio;
import std.parallelism;

//import std.experimental.allocator.mallocator ;
//import std.experimental.allocator.building_blocks.free_list ;

debug { 
	extern(C) __gshared string[] rt_options = [ "gcopt=profile:1"];// maxPoolSize:50" ];
}
/*
static this()
{
	threadColliedAllocator = allocatorObject(FreeList!(AlignedMallocator,1024)());
}
*/
void httphandler(HTTPRequest req ,HTTPResponse rep)
{
	rep.header.setHeaderValue("content-type","text/html;charset=UTF-8");

	rep.HTTPBody.write(cast(ubyte[])"hello wrold!");
	rep.sent();
}

void main(string[] args)
{
	globalLogLevel(LogLevel.error);

	writeln("current cpus = ",totalCPUs,"\n");
	writeln("args : port threads threadMode");
	writeln("like : http://localhost:8080\n");
	//string[] args = Runtime.args;
	ushort port = 8080;
	uint threads = 4;
	if(args.length == 3) {
		writeln(args);
		port = to!ushort(args[1]);
		threads = to!uint(args[2]);
		if(port == 0  || threads ==0 ){
			writeln("Args Erro!");
			return;
		}
	}
	HTTPConfig.instance.doHttpHandle = toDelegate(&httphandler);
	HTTPConfig.instance.doWebSocket = toDelegate(&EchoWebSocket.newEcho);
	HTTPConfig.instance.HeaderStectionSize = 256;
	HTTPConfig.instance.ResponseBodyStectionSize = 1024;
	HTTPConfig.instance.RequestBodyStectionSize = 1024;
	HTTPConfig.instance.httpTimeOut = 20.seconds;
	auto loop = new EventLoop();
	version (SSL) {
		auto server = new SSLServerBoostStarp(loop);
		writeln("start ! The Port is ",port, "  Threads is ",threads);
		server.setPrivateKeyFile("server.pem");
		server.setCertificateFile("server.pem");
	} else {
		auto server = new ServerBoostStarp(loop);
		writeln("start ! The Port is ",port, "  Threads is ",threads);
	}
	debug {
		Timer tm = new Timer(loop);
		tm.TimeOut = dur!"seconds"(30);
		tm.once = true;
		tm.setCallBack(delegate(){writeln("close time out : ");tm.kill();server.stop();});
		tm.start();
	}
	server.setPipelineFactory(toDelegate(&HTTPConfig.createPipline)).setThreadSize(threads)
		.bind(Address("0.0.0.0",port)).run();
}




class EchoWebSocket : WebSocket
{
	override void onClose()
	{
		writeln("websocket closed");
	}

	override void onTextFrame(Frame frame)
	{
		writeln("get a text frame, is finna : ", frame.isFinalFrame, "  data is :", cast(string)frame.data);
		sendText("456789");
	//	sendBinary(cast(ubyte[])"456123");
	//	ping(cast(ubyte[])"123");
	}

	override void onPongFrame(Frame frame)
	{
		writeln("get a text frame, is finna : ", frame.isFinalFrame, "  data is :", cast(string)frame.data);
	}

	override void onBinaryFrame(Frame frame)
	{
		writeln("get a text frame, is finna : ", frame.isFinalFrame, "  data is :", cast(string)frame.data);
	}

	static WebSocket newEcho(const HTTPHeader header)
	{
		trace("new EchoWebSocket ");
		return new EchoWebSocket;
	}
}
