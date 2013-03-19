package cn.vimfung.mybooklet.framework.module.myposts.command
{
	import cn.vimfung.common.net.Url;
	import cn.vimfung.common.utils.StringUtil;
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.model.ProgressInfo;
	import cn.vimfung.mybooklet.framework.module.myposts.FileDownloader;
	import cn.vimfung.mybooklet.framework.module.myposts.notification.PostNotification;
	import cn.vimfung.utils.Encode;
	
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.html.HTMLLoader;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import mx.controls.HTML;
	import mx.managers.BrowserManager;
	import mx.utils.URLUtil;
	
	import org.puremvc.as3.interfaces.ICommand;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.command.SimpleCommand;
	
	/**
	 * 导入文章命令 
	 * @author Administrator
	 * 
	 */	
	public class ImportPostCommand extends SimpleCommand implements ICommand
	{
		public function ImportPostCommand()
		{
			super();
		}
		
		private var _url:String;
		private var _charset:String = Encode.UTF_8;
		private var _facade:GNFacade = GNFacade.getInstance();
		
		private var _resourceDict:Dictionary;
		private var _downloadQueue:Array;
		private var _fileCount:int;
		private var _downloadFileCount:int;
		private var _content:String;
		
		/**
		 * @inheritDoc
		 * 
		 */		
		public override function execute(notification:INotification):void
		{
			_url = notification.getBody() as String;
			
			var request:URLRequest = new URLRequest(_url);
			var loader:URLLoader = new URLLoader(request);
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, loadRequestCompleteHandler);
			loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, httpResponseStatusHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, loadRequestErrorHandler);
		}
		
		/**
		 * 回复请求状态
		 * @param event 事件
		 * */
		private function httpResponseStatusHandler(event:HTTPStatusEvent):void
		{
			for(var i:int = 0; i < event.responseHeaders.length; i++)
			{
				var header:URLRequestHeader = event.responseHeaders[i];
				if(header.name == "Content-Type")
				{
					//取得编码类型
					var regexp:RegExp = new RegExp("charset=(\\w+);?$");
					var matches:Array = header.value.match(regexp);
					if(matches != null && matches.length >=2 )
					{
						_charset = matches[1];
					}
					break;
				}
			}
		}
		
		/**
		 * 加载请求失败
		 * @param event 事件
		 * */
		private function loadRequestErrorHandler(event:IOErrorEvent):void
		{
			event.target.removeEventListener(Event.COMPLETE, loadRequestCompleteHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, loadRequestErrorHandler);
			event.target.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, httpResponseStatusHandler);
			
			var error:IOError = new IOError(event.text, event.errorID);
			var notif:PostNotification = new PostNotification(PostNotification.IMPORT_URL_POST_LOAD_ERROR, error);
			_facade.postNotification(notif);
		}
		
		/**
		 * 加载请求完成
		 * @param event 事件
		 * */
		private function loadRequestCompleteHandler(event:Event):void
		{
			event.target.removeEventListener(Event.COMPLETE, loadRequestCompleteHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, loadRequestErrorHandler);
			event.target.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, httpResponseStatusHandler);
			
			var baseUrl:Url = Url.create(_url);
			
			var buf:ByteArray = event.target.data as ByteArray;
			_content = buf.readMultiByte(buf.length, _charset);
			
			var notif:PostNotification = null;
			var tmpDir:File = File.createTempDirectory();
			var tmpFile:File = null;
			_fileCount = 0;
			_resourceDict = new Dictionary();
			_downloadQueue = new Array();

			//查找所有图片和样式表路径，如果不是绝对路径则进行替换
			var regexp:RegExp = new RegExp("\\s*(href\\s*=\\s*([\\'\\\"\\s]([^\\\"\\']*)[\\'\\\"]))","\g\i");
			_content = _content.replace(regexp, function():String {
				var urlString:String = arguments[3];
				var url:Url = Url.create(urlString, baseUrl);
				var targetString:String = "href=\"" + url.absoluteString + "\"";
				
				//判断是否为css或js脚本
				if (StringUtil.hasSuffix(url.path, "[\\.](css|js)"))
				{
					tmpFile = tmpDir.resolvePath(StringUtil.lastPathComponent(url.path));
					_resourceDict[targetString] = {source:targetString, format:"href=\"{0}\"", file:tmpFile}; 
				}
				
				return arguments[0].replace(arguments[1], targetString);
			});
			
			regexp = new RegExp("\\s*(src\\s*=\\s*([\\'\\\"\\s]([^\\\"\\']*)[\\'\\\"]))", "\g\i");
			_content = _content.replace(regexp, function():String {
				var urlString:String = arguments[3];
				var url:Url = Url.create(urlString, baseUrl);
				var targetString:String = "src=\"" + url.absoluteString + "\"";
				
				//判断是否为css或js脚本
				if (StringUtil.hasSuffix(url.path, "[\\.](css|js|jpg|jpeg|png|bmp|gif)"))
				{
					tmpFile = tmpDir.resolvePath(StringUtil.lastPathComponent(url.path));
					_resourceDict[targetString] = {source:targetString, format:"src=\"{0}\"", file:tmpFile};
				}

				return arguments[0].replace(arguments[1], targetString);
			});
			
			for (var i:String in _resourceDict)
			{
				_downloadQueue.push(i);
			}
			
			if (_downloadQueue.length > 0)
			{
				//下载资源文件
				_fileCount = _downloadQueue.length;
				
				var progressInfo:ProgressInfo = new ProgressInfo();
				progressInfo.progress = 1;
				progressInfo.total = 1 + _fileCount;
				
				notif = new PostNotification(PostNotification.IMPORT_URL_POST_LOAD_PROGRESS, progressInfo);
				_facade.postNotification(notif);
				
				this.downloadNextFile();
			}
			else
			{
				//派发完成事件
				notif = new PostNotification(PostNotification.IMPORT_URL_POST_LOAD_SUCCESS, {"content" : _content});
				_facade.postNotification(notif);
			}
		}
		
		/**
		 * 下载完成 
		 * @param event 事件
		 * 
		 */		
		private function downloadCompleteHandler(event:Event):void
		{
			event.target.removeEventListener(Event.COMPLETE, downloadCompleteHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, downloadErrorHandler);
			
			//派发进度事件
			var progressInfo:ProgressInfo = new ProgressInfo();
			progressInfo.progress = 1 + _fileCount - _downloadQueue.length;
			progressInfo.total = 1 + _fileCount;
			
			var notif:PostNotification = new PostNotification(PostNotification.IMPORT_URL_POST_LOAD_PROGRESS, progressInfo);
			_facade.postNotification(notif);
			
			this.downloadNextFile();
		}
		
		/**
		 * 下载失败 
		 * @param event 事件
		 * 
		 */		
		private function downloadErrorHandler(event:IOErrorEvent):void
		{
			event.target.removeEventListener(Event.COMPLETE, downloadCompleteHandler);
			event.target.removeEventListener(IOErrorEvent.IO_ERROR, downloadErrorHandler);
			
			//派发进度事件
			var progressInfo:ProgressInfo = new ProgressInfo();
			progressInfo.progress = 1 + _fileCount - _downloadQueue.length;
			progressInfo.total = 1 + _fileCount;
			
			var notif:PostNotification = new PostNotification(PostNotification.IMPORT_URL_POST_LOAD_PROGRESS, progressInfo);
			_facade.postNotification(notif);
			
			this.downloadNextFile();
		}
		
		/**
		 * 下载下一个文件 
		 * 
		 */		
		private function downloadNextFile():void
		{
			if (_downloadQueue.length > 0)
			{
				var key:String = _downloadQueue.shift();
				var downloader:FileDownloader = new FileDownloader(key, _resourceDict[key].file);
				downloader.addEventListener(Event.COMPLETE, downloadCompleteHandler);
				downloader.addEventListener(IOErrorEvent.IO_ERROR, downloadErrorHandler);
				downloader.start();
			}
			else
			{
				//派发完成事件
				var notif:PostNotification = new PostNotification(PostNotification.IMPORT_URL_POST_LOAD_SUCCESS, {"content" : _content, "files": _resourceDict});
				_facade.postNotification(notif);
			}
		}
	}
}