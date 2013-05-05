package cn.vimfung.mybooklet.framework.model
{
	import org.puremvc.as3.core.Model;

	/**
	 * 模块信息 
	 * @author Administrator
	 * 
	 */	
	public class Module extends Object
	{
		public function Module()
		{
			super();
		}
		
		private var _id:String;
		private var _title:String;
		private var _url:String;
		private var _useCount:int;

		/**
		 * 获取我的文章模块信息 
		 * @return 我的文章模块信息
		 * 
		 */		
		public static function getMyPostsModule():Module
		{
			var module:Module = new Module();
			module.id = "cn.vimfung.mybooklet.myposts";
			module.title = "我的文章";
			module.url = "cn/vimfung/mybooklet/framework/module/myposts/MyPosts.swf";
			
			return module;
		}
		
		/**
		 * 获取系统设置模块信息 
		 * @return 系统设置模块信息
		 * 
		 */		
		public static function getSettingModule():Module
		{
			var module:Module = new Module();
			module.id = "cn.vimfung.mybooklet.setting";
			module.title = "设置";
			module.url = "cn/vimfung/mybooklet/framework/module/setting/Setting.swf";
			
			return module;
		}
		
		public static function getSubscriptModule():Module
		{
			var module:Module = new Module();
			module.id = "cn.vimfung.mybooklet.subscript";
			module.title = "我的订阅";
			
			module.url = "cn/vimfung/mybooklet/framework/module/subscript/Subscript.swf";
			
			return module;
		}
		
		/**
		 * 创建模块信息 
		 * @param object 数据对象
		 * @return 模块信息
		 * 
		 */		
		public static function createModule(object:Object):Module
		{
			var module:Module = new Module();
			module.id = object.id;
			module.title = object.title;
			module.url = object.url;
			module.useCount = object.useCount;
			
			return module;
		}

		/**
		 * 获取模块路径 
		 * @return 路径
		 * 
		 */		
		public function get url():String
		{
			return _url;
		}
		
		/**
		 * 设置模块路径 
		 * @param value 路径
		 * 
		 */		
		public function set url(value:String):void
		{
			_url = value;
		}

		/**
		 * 获取模块标题 
		 * @return 标题
		 * 
		 */		
		public function get title():String
		{
			return _title;
		}

		/**
		 * 设置模块标题 
		 * @param value 标题
		 * 
		 */		
		public function set title(value:String):void
		{
			_title = value;
		}

		/**
		 * 获取模块标识 
		 * @return 标识
		 * 
		 */		
		public function get id():String
		{
			return _id;
		}

		/**
		 * 设置模块标识 
		 * @param value 标识
		 * 
		 */		
		public function set id(value:String):void
		{
			_id = value;
		}

		/**
		 * 获取使用次数 
		 * @return 使用次数
		 * 
		 */		
		public function get useCount():int
		{
			return _useCount;
		}
		
		/**
		 * 设置使用次数 
		 * @param value 使用次数
		 * 
		 */		
		public function set useCount(value:int):void
		{
			_useCount = value;
		}
	}
}