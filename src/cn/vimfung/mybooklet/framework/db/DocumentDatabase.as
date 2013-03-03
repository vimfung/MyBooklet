package cn.vimfung.mybooklet.framework.db
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent;
	import cn.vimfung.mybooklet.framework.module.myposts.Constant;
	
	import flash.data.SQLColumnSchema;
	import flash.data.SQLTableSchema;
	import flash.filesystem.File;
	
	/**
	 * 初始化数据库完成 
	 */	
	[Event(name="initialize", type="cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent")]
	
	/**
	 * 文档数据库 
	 * @author Administrator
	 * 
	 */	
	public class DocumentDatabase extends SqliteDatabase
	{
		public function DocumentDatabase()
		{
			super(Constant.DatabaseFile);
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
				文章信息表(notes)
				id	文章id
				title	文章标题
				content	文章内容
				createTime	创建时间
				modifyTime	修改时间
				state	状态:1 有效 0 无效
				tags	标签列表
				color	标记颜色
			*/
			this.execute("CREATE TABLE IF NOT EXISTS notes(id INTEGER PRIMARY KEY, title TEXT, content TEXT, createTime DATETIME, modifyTime DATETIME, state INTEGER, tags TEXT, color INTEGER DEFAULT -1)", null, true);
			
			/*
				文章附件信息表(notes_attach)
				id	附件id
				url	附件的本地路径
				noteId	文章ID
				createTime	创建时间
			*/
			this.execute("CREATE TABLE IF NOT EXISTS notes_attach(id INTEGER PRIMARY KEY, url TEXT, noteId INTEGER, createTime DATETIME)", null, true);
			
			
			/*
				文章标签信息表(notes_tag)
				id	标签ID
				name	标签名称
				createTime	创建时间
				latestTime	最近一次使用时间
				useCount	使用次数
				pinyin		标签全拼
				fpinyin		标签拼音首字母
			*/
			this.execute("CREATE TABLE IF NOT EXISTS notes_tag(id INTEGER PRIMARY KEY, name TEXT, createTime DATETIME, latestTime DATETIME, useCount INTEGER, pinyin TEXT, fpinyin TEXT)", null, true);
			
			//获取标签数据表架构信息，来判断数据表版本
			this.addEventListener(SqliteDatabaseEvent.SCHEMA, tagTableSchemaResultHandler);
			this.addEventListener(SqliteDatabaseEvent.ERROR, tagTableSchemaErrorHandler);
			this.getTableSchema(null);
		}
		
		public override function connect():void
		{
			super.connect();
			
			initializeDatabase();
		}
		
		/**
		 * 更新标签数据表 
		 * @param table 表结构
		 * 
		 */		
		private function updateTagTable(table:SQLTableSchema):void
		{
			var exists:Boolean = false;
			var existsFPinyin:Boolean = false;
			for(var i:int = 0; i < table.columns.length; i++)
			{
				var column:SQLColumnSchema = table.columns[i];
				if (column.name == "pinyin")
				{
					exists = true;
				}
				else if (column.name == "fpinyin")
				{
					existsFPinyin = true;
				}
			}
			
			if (!exists)
			{
				this.execute("ALTER TABLE notes_tag ADD COLUMN pinyin TEXT", null, true);
			}
			
			if (!existsFPinyin)
			{
				this.execute("ALTER TABLE notes_tag ADD COLUMN fpinyin TEXT", null, true);
			}
		}
		
		/**
		 * 更新文章数据 
		 * @param table
		 * 
		 */		
		private function updateNoteTable(table:SQLTableSchema):void
		{
			var exists:Boolean = false;
			for(var i:int = 0; i < table.columns.length; i++)
			{
				var column:SQLColumnSchema = table.columns[i];
				if (column.name == "color")
				{
					exists = true;
				}
			}
			
			if (!exists)
			{
				this.execute("ALTER TABLE notes ADD COLUMN color INTEGER DEFAULT -1", null, true);
			}
		}
		
		/**
		 * 标签数据表架构返回 
		 * @param event 事件
		 * 
		 */		
		private function tagTableSchemaResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.SCHEMA, tagTableSchemaResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, tagTableSchemaErrorHandler);

			if(event.schema.tables.length > 0)
			{
				for(var i:int = 0; i < event.schema.tables.length; i++)
				{
					var table:SQLTableSchema  = event.schema.tables[i];
					switch(table.name)
					{
						case "notes_tag":
							this.updateTagTable(table);
							break;
						case "notes":
							this.updateNoteTable(table);
							break;
					}
				}
				
			}
			
			_initialized = true;
			
			var e:SqliteDatabaseEvent = new SqliteDatabaseEvent(SqliteDatabaseEvent.INITIALIZE);
			this.dispatchEvent(e);
		}
		
		/**
		 * 标签数据表架构失败 
		 * @param event 事件
		 * 
		 */		
		private function tagTableSchemaErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.SCHEMA, tagTableSchemaResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, tagTableSchemaErrorHandler);
			
			GNFacade.getInstance().alert("初始化失败!" + event.error.message);
		}
	}
}