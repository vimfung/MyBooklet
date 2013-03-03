package cn.vimfung.mybooklet.framework.db
{
	import cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent;
	
	import flash.data.SQLConnection;
	import flash.data.SQLIndexSchema;
	import flash.data.SQLStatement;
	import flash.data.SQLTableSchema;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import org.osmf.events.TimeEvent;
	
	/**
	 * 关闭数据库连接 
	 */	
	[Event(name="close", type="cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent")]
	
	/**
	 * 架构信息 
	 */	
	[Event(name="schema", type="cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent")]
	
	/**
	 * 异常 
	 */	
	[Event(name="error", type="cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent")]
	
	/**
	 * Sqlite数据库 
	 * @author Administrator
	 * 
	 */	
	public class SqliteDatabase extends EventDispatcher
	{
		public function SqliteDatabase(path:File)
		{
			super();
			
			_path = path;
			_conn = new SQLConnection();
			
			this.connect();
		}
		
		private var _path:File;
		private var _conn:SQLConnection;
		
		/**
		 * 获取最后插入行ID 
		 * @return 最好插入行ID
		 * 
		 */		
		public function get lastInsertRowID():Number
		{
			return _conn.lastInsertRowID;
		}
		
		/**
		 * 启动事务 
		 * 
		 */		
		public function beginTrans():void
		{
			_conn.begin();
		}
		
		/**
		 * 回滚事务 
		 * 
		 */		
		public function rollbackTrans():void
		{
			_conn.rollback();
		}
		
		/**
		 * 提交事务 
		 * 
		 */		
		public function commitTrans():void
		{
			_conn.commit();
		}
		
		/**
		 * 断开数据库连接 
		 * 
		 */		
		public function disconnect():void
		{
			if(_conn.connected)
			{
				_conn.addEventListener(SQLEvent.CLOSE, connectionCloseHandler);
				_conn.addEventListener(SQLErrorEvent.ERROR, connectionCloseErrorHandler);
				_conn.close();
			}
		}
		
		/**
		 * 连接数据库 
		 * 
		 */		
		public function connect():void
		{
			if(!_conn.connected)
			{
				_conn.open(_path);
			}
		}
		
		public function getTableSchema(tableName:String = null):void
		{
			_conn.addEventListener(SQLEvent.SCHEMA, getSchemaResultHandler);
			_conn.addEventListener(SQLErrorEvent.ERROR, getSchemaErrorHandler);
			return _conn.loadSchema(SQLTableSchema, tableName);
		}
		
		/**
		 * 创建命令令牌 
		 * @param command 命令文本
		 * @param paramters 参数
		 * @return 令牌对象
		 * 
		 */		
		public function createCommandToken(command:String, paramters:Dictionary = null):SqliteDatabaseToken
		{
			var statement:SQLStatement = new SQLStatement();
			statement.sqlConnection = _conn;
			statement.text = command;
			if(paramters != null)
			{
				for(var i:String in paramters)
				{
					statement.parameters[i] = paramters[i];
				}
			}
			
			return new SqliteDatabaseToken(statement);
		}
		
		/**
		 * 执行SQL命令 
		 * @param command 	命令
		 * @param paramters 	参数
		 * @param immediately	立即模式，不对操作进行延时操作，可能在返回Token前已触发事件。
		 * @return 数据库操作令牌
		 * 
		 */		
		public function execute(command:String, paramters:Dictionary = null, immediately:Boolean = false):SqliteDatabaseToken
		{
			var token:SqliteDatabaseToken = this.createCommandToken(command, paramters);
			
			if(immediately)
			{
				token.startSync();
			}
			else
			{
				//延时调用
				var timerHandler:Function = function(event:TimerEvent):void
				{
					event.target.removeEventListener(TimerEvent.TIMER, timerHandler);
					token.start();
				};
				var timer:Timer = new Timer(100);
				timer.addEventListener(TimerEvent.TIMER, timerHandler);
				timer.start();
			}
			
			return token;
		}
		
		/**
		 * 连接关闭 
		 * @param event 事件
		 * 
		 */		
		private function connectionCloseHandler(event:SQLEvent):void
		{
			event.target.removeEventListener(SQLEvent.CLOSE, connectionCloseHandler);
			event.target.removeEventListener(SQLErrorEvent.ERROR, connectionCloseErrorHandler);
			
			var e:SqliteDatabaseEvent = new SqliteDatabaseEvent(SqliteDatabaseEvent.CLOSE);
			this.dispatchEvent(e);
		}
		
		/**
		 * 连接关闭失败 
		 * @param event 事件
		 * 
		 */		
		private function connectionCloseErrorHandler(event:SQLErrorEvent):void
		{
			event.target.removeEventListener(SQLEvent.CLOSE, connectionCloseHandler);
			event.target.removeEventListener(SQLErrorEvent.ERROR, connectionCloseErrorHandler);
			
			var e:SqliteDatabaseEvent = new SqliteDatabaseEvent(SqliteDatabaseEvent.ERROR);
			e.error = event.error;
			this.dispatchEvent(e);
		}
		
		/**
		 * 获取架构信息返回 
		 * @param event	事件
		 * 
		 */		
		private function getSchemaResultHandler(event:SQLEvent):void
		{
			event.target.removeEventListener(SQLEvent.SCHEMA, getSchemaResultHandler);
			event.target.removeEventListener(SQLErrorEvent.ERROR, getSchemaErrorHandler);
			
			var e:SqliteDatabaseEvent = new SqliteDatabaseEvent(SqliteDatabaseEvent.SCHEMA);
			e.schema = _conn.getSchemaResult();
			this.dispatchEvent(e);
		}
		
		/**
		 * 获取架构信息错误 
		 * @param event 事件
		 * 
		 */		
		private function getSchemaErrorHandler(event:SQLErrorEvent):void
		{
			event.target.removeEventListener(SQLEvent.SCHEMA, getSchemaResultHandler);
			event.target.removeEventListener(SQLErrorEvent.ERROR, getSchemaErrorHandler);
			
			var e:SqliteDatabaseEvent = new SqliteDatabaseEvent(SqliteDatabaseEvent.ERROR);
			e.error = event.error;
			this.dispatchEvent(e);
		}
	}
}