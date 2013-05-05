package cn.vimfung.mybooklet.framework.db
{
	import cn.vimfung.common.db.SqliteDatabase;
	import cn.vimfung.common.db.SqliteDatabaseToken;
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.events.DBEvent;
	
	import flash.data.SQLResult;
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	
	/**
	 * 初始化数据库完成 
	 */	
	[Event(name="initialize", type="cn.vimfung.mybooklet.framework.events.DBEvent")]
	
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
			
			/*
				系统设置信息表(sys_setting)
				name	设置项名称
				value	设置项数值
			*/
			this.execute("CREATE TABLE IF NOT EXISTS sys_setting(name TEXT PRIMARY KEY, value TEXT)", null, true);
			
			_initialized = true;
			
			//派发初始化完成事件
			var e:DBEvent = new DBEvent(DBEvent.INITIALIZE);
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
		
		/**
		 * 设置配置项 
		 * @param name	名称
		 * @param value	值
		 * 
		 */		
		public function setSetting(name:String, value:String):void
		{
			var facade:GNFacade = GNFacade.getInstance();
			
			//保存设置
			var params:Dictionary = new Dictionary();
			params[":name"] = name;
			
			var token:SqliteDatabaseToken = facade.systemDatabase.createCommandToken("SELECT * FROM sys_setting WHERE name = :name", params);
			var result:SQLResult = token.startSync();
			
			params[":value"] = value;
			if (result.data == null || result.data.length == 0)
			{
				//添加配置项
				token = facade.systemDatabase.createCommandToken("INSERT INTO sys_setting VALUES(:name, :value)", params);
				token.startSync();
			}
			else
			{
				token = facade.systemDatabase.createCommandToken("UPDATE sys_setting SET value = :value WHERE name = :name", params);
				token.startSync();
			}
		}
	}
}