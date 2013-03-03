package cn.vimfung.mybooklet.framework.db
{
	import cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent;
	
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	
	import mx.controls.Alert;
	
	/**
	 * 操作返回 
	 */	
	[Event(name="result", type="cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent")]
	
	/**
	 * 操作失败 
	 */	
	[Event(name="error", type="cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent")]
	
	/**
	 * 数据库令牌 
	 * @author Administrator
	 * 
	 */	
	public class SqliteDatabaseToken extends EventDispatcher
	{
		public function SqliteDatabaseToken(statement:SQLStatement)
		{
			super();
			
			_statement = statement;
		}
		
		private var _statement:SQLStatement;
		private var _userData:*;
		
		/**
		 * 获取附加数据 
		 * @return 附加数据
		 * 
		 */		
		public function get userData():*
		{
			return _userData;
		}

		/**
		 * 设置附加数据 
		 * @param value 附加数据
		 * 
		 */		
		public function set userData(value:*):void
		{
			_userData = value;
		}

		/**
		 * 获取返回数据 
		 * @return 返回数据
		 * 
		 */		
		public function get result():SQLResult
		{
			return _statement.getResult();
		}
		
		/**
		 * 开始请求 
		 * 
		 */		
		public function start():void
		{
			_statement.addEventListener(SQLEvent.RESULT, resultHandler);
			_statement.addEventListener(SQLErrorEvent.ERROR, errorHandler);
			_statement.execute();
		}
		
		/**
		 * 开始同步请求 
		 * @return 返回结果
		 * 
		 */		
		public function startSync():SQLResult
		{
			_statement.execute();
			return this.result;
		}
		
		/**
		 * 操作返回 
		 * @param event 事件
		 * 
		 */		
		private function resultHandler(event:SQLEvent):void
		{
			var e:SqliteDatabaseEvent = new SqliteDatabaseEvent(SqliteDatabaseEvent.RESULT);
			e.recordset = this.result.data;
			this.dispatchEvent(e);
		}
		
		/**
		 * 操作失败 
		 * @param event 事件
		 * 
		 */		
		private function errorHandler(event:SQLErrorEvent):void
		{
			var e:SqliteDatabaseEvent = new SqliteDatabaseEvent(SqliteDatabaseEvent.ERROR);
			e.error = event.error;
			this.dispatchEvent(e);
		}
	}
}