package cn.vimfung.mybooklet.framework.module.myposts.command
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.model.ProgressInfo;
	import cn.vimfung.mybooklet.framework.module.myposts.notification.PostNotification;
	import cn.vimfung.utils.Encode;
	
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.utils.ByteArray;
	
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
			loader.addEventListener(ProgressEvent.PROGRESS, loadRequestProgressHandler);
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
			event.target.removeEventListener(ProgressEvent.PROGRESS, loadRequestProgressHandler);
			event.target.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, httpResponseStatusHandler);
			
			var error:IOError = new IOError(event.text, event.errorID);
			var notif:PostNotification = new PostNotification(PostNotification.IMPORT_URL_POST_LOAD_ERROR, error);
			_facade.postNotification(notif);
		}
		
		/**
		 * 加载请求进度
		 * @param event 事件
		 * */
		private function loadRequestProgressHandler(event:ProgressEvent):void
		{
			var progressInfo:ProgressInfo = new ProgressInfo();
			progressInfo.progress = event.bytesLoaded;
			progressInfo.total = event.bytesTotal;
			
			var notif:PostNotification = new PostNotification(PostNotification.IMPORT_URL_POST_LOAD_PROGRESS, progressInfo);
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
			event.target.removeEventListener(ProgressEvent.PROGRESS, loadRequestProgressHandler);
			event.target.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, httpResponseStatusHandler);
			
			var host:String = null;
			var schemaIndex:int = _url.indexOf("://") + "://".length;
			var hostIndex:int = _url.indexOf("/",schemaIndex);
			if(hostIndex == -1)
			{
				host = _url + "/";
			}
			else
			{
				host = _url.substr(0, _url.indexOf("/",schemaIndex) + 1);
			}
			
			var path:String = null;
			var queryIndex:int = _url.lastIndexOf("?");
			if(queryIndex != -1)
			{
				var url:String = _url.substr(0, queryIndex);
				var extIndex:int = url.lastIndexOf(".");
				if(extIndex == -1)
				{
					if(url.charAt(url.length - 1) == "/")
					{
						path = url;
					}
					else
					{
						path += "/";
					}
				}
				else
				{
					path = url.substr(0, url.lastIndexOf("/") + 1);
				}
			}
			
			var buf:ByteArray = event.target.data as ByteArray;
			
			var content:String = buf.readMultiByte(buf.length, _charset);
			//查找所有图片和样式表路径，如果不是绝对路径则进行替换
			var regexp:RegExp = new RegExp("(\\s*href\\s*=\\s*([\\'\\\"\\s]([^\\\"\\']*)[\\'\\\"]))","\g\i");
			content = content.replace(regexp, function():String {
				var url:String = arguments[3];
				if(url.indexOf("://") == -1)
				{
					if(url.charAt() == "/")
					{
						url = host + url.substr(1);
					}
					else
					{
						url = path + url;
					}
					return "href=\"" + url + "\""; 
				}
				else
				{
					return arguments[0];
				}
			});
			
			regexp = new RegExp("(\\s*src\\s*=\\s*([\\'\\\"\\s]([^\\\"\\']*)[\\'\\\"]))", "\g\i");
			content = content.replace(regexp, function():String {
				var url:String = arguments[3];
				if(url.indexOf("://") == -1)
				{
					if(url.charAt() == "/")
					{
						url = host + url.substr(1);
					}
					else
					{
						url = path + url;
					}
					return "src=\"" + url + "\""; 
				}
				else
				{
					return arguments[0];
				}
			});
			
			var notif:PostNotification = new PostNotification(PostNotification.IMPORT_URL_POST_LOAD_SUCCESS, content);
			_facade.postNotification(notif);
		}
	}
}