package cn.vimfung.mybooklet.framework.module.myposts
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	[Event(name="ioError", type="flash.events.IOErrorEvent")]
	
	[Event(name="complete", type="flash.events.Event")]
	
	/**
	 * 文件下载器 
	 * @author Administrator
	 * 
	 */	
	public class FileDownloader extends EventDispatcher
	{
		public function FileDownloader(url:String, file:File)
		{
			super();
			
			_url = url;
			_file = file;
		}
		
		private var _url:String;
		private var _file:File;
		private var _request:URLRequest;
		private var _loader:URLLoader;

		/**
		 * 获取下载目标文件
		 * @return 下载文件
		 * 
		 */		
		public function get file():File
		{
			return _file;
		}

		/**
		 * 获取下载URL 
		 * @return 下载URL
		 * 
		 */		
		public function get url():String
		{
			return _url;
		}
		
		/**
		 * 开始下载 
		 * 
		 */		
		public function start():void
		{
			_request = new URLRequest(_url);
			_loader = new URLLoader(_request);
			_loader.dataFormat = URLLoaderDataFormat.BINARY;
			_loader.addEventListener(Event.COMPLETE, completeHandler);
			_loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			_loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, statusHandler);
			_loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, statusHandler);
			
		}
		
		/**
		 * 下载完成 
		 * @param event 事件
		 * 
		 */		
		private function completeHandler(event:Event):void
		{
			event.target.removeEventListener(Event.COMPLETE, completeHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			var bytes:ByteArray = event.target.data;
			var fs:FileStream = new FileStream();
			fs.open(_file, FileMode.WRITE);
			try
			{
				fs.writeBytes(bytes);
			}
			finally
			{
				fs.close();
			}
			
			this.dispatchEvent(event.clone());
		}
		
		/**
		 * 下载错误 
		 * @param event 事件
		 * 
		 */		
		private function errorHandler(event:IOErrorEvent):void
		{
			event.target.removeEventListener(Event.COMPLETE, completeHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			this.dispatchEvent(event.clone());
		}
		
		private function securityErrorHandler(event:SecurityErrorEvent):void
		{
			trace("#####");
		}
		
		private function statusHandler(event:HTTPStatusEvent):void
		{
			trace:("status",event.status);
		}
	}
}