package cn.vimfung.mybooklet.framework.events
{
	import flash.data.SQLSchemaResult;
	import flash.events.Event;
	
	/**
	 * Sqlite数据库事件 
	 * @author Administrator
	 * 
	 */	
	public class SqliteDatabaseEvent extends Event
	{
		public function SqliteDatabaseEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		/**
		 * 初始化数据库 
		 */		
		public static const INITIALIZE:String = "initialize";
		
		/**
		 * 关闭数据库 
		 */		
		public static const CLOSE:String = "close";
		
		/**
		 * 数据返回 
		 */		
		public static const RESULT:String = "result";
		
		/**
		 * 架构信息 
		 */		
		public static const SCHEMA:String = "schema";
		
		/**
		 * 异常 
		 */		
		public static const ERROR:String = "error";
		
		
		private var _error:Error;
		private var _recordset:Array;
		private var _schema:SQLSchemaResult;

		/**
		 * 获取架构信息
		 * @return 架构信息
		 * 
		 */		
		public function get schema():SQLSchemaResult
		{
			return _schema;
		}

		/**
		 * 设置架构信息 
		 * @param value 架构信息
		 * 
		 */		
		public function set schema(value:SQLSchemaResult):void
		{
			_schema = value;
		}

		/**
		 * 获取数据集 
		 * @return 数据集
		 * 
		 */		
		public function get recordset():Array
		{
			return _recordset;
		}
		
		/**
		 * 设置数据集 
		 * @param value 数据集
		 * 
		 */		
		public function set recordset(value:Array):void
		{
			_recordset = value;
		}

		/**
		 * 获取异常信息 
		 * @return 异常信息
		 * 
		 */		
		public function get error():Error
		{
			return _error;
		}

		/**
		 * 设置异常信息 
		 * @param value 异常信息
		 * 
		 */		
		public function set error(value:Error):void
		{
			_error = value;
		}

	}
}