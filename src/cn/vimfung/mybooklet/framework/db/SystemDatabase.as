package cn.vimfung.mybooklet.framework.db
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent;
	
	import flash.filesystem.File;
	
	/**
	 * 初始化数据库完成 
	 */	
	[Event(name="initialize", type="cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent")]
	
	/**
	 * 系统数据 
	 * @author Administrator
	 * 
	 */	
	public class SystemDatabase extends SqliteDatabase
	{
		public function SystemDatabase()
		{
			super(File.applicationStorageDirectory.resolvePath("sys.db"));
		}
		
		private var _initialized:Boolean = false;
		
		/**
		 * 获取数据库初始化状态 
		 * @return 初始化状态
		 * 
		 */		
		public function get initialized():Boolean
		{
			return _initialized;
		}
		
		/**
		 * 设置数据库初始化状态 
		 * @param value 初始化状态
		 * 
		 */		
		public function set initialized(value:Boolean):void
		{
			_initialized = value;
		}
		
		/**
		 * 初始化数据库 
		 * 
		 */		
		private function initializeDatabase():void
		{		
			/*
				文章备份信息表（notes_backup）
				id	备份ID
				url	备份文件的物理路径
				createTime	备份创建时间
			*/
			this.execute("CREATE TABLE IF NOT EXISTS notes_backup(id INTEGER PRIMARY KEY, url TEXT, createTime DATETIME)", null, true);
			
			/*
				模块信息表(sys_module)
				id	模块ID
				title	模块名称
				url	模块的物理路径
				createTime	创建时间
				type	类型：1 主导航模块
				sortIndex	排序
				useCount	使用次数
			*/
			this.execute("CREATE TABLE IF NOT EXISTS sys_module(id TEXT PRIMARY KEY, title TEXT, url TEXT, createTime DATETIME, type INTEGER, sortIndex INTEGER, useCount INTEGER)", null, true);
			
			/*
				系统补丁信息表(sys_patch)
				name	补丁名称
				patchTime	补丁时间
			*/
			this.execute("CREATE TABLE IF NOT EXISTS sys_patch(name TEXT PRIMARY KEY, patchTime DATETIME)", null, true);
			
			_initialized = true;
			
			//派发初始化完成事件
			var e:SqliteDatabaseEvent = new SqliteDatabaseEvent(SqliteDatabaseEvent.INITIALIZE);
			this.dispatchEvent(e);
		}
		
		/**
		 * @inheritDoc 
		 * 
		 */		
		public override function connect():void
		{
			super.connect();
			
			this.initializeDatabase();
		}
	}
}