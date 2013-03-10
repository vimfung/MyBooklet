package cn.vimfung.mybooklet.framework.module.myposts.token
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.db.SqliteDatabaseToken;
	import cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent;
	import cn.vimfung.mybooklet.framework.model.ProgressInfo;
	import cn.vimfung.mybooklet.framework.module.myposts.Constant;
	import cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent;
	import cn.vimfung.mybooklet.framework.module.myposts.model.AttachmentInfo;
	import cn.vimfung.utils.Chinese2Spell;
	import cn.vimfung.utils.SpellOptions;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	
	import mx.utils.StringUtil;
	
	/**
	 * 创建文章返回 
	 */	
	[Event(name="createPostResult", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 创建文章失败 
	 */	
	[Event(name="createPostError", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 创建文章进度 
	 */	
	[Event(name="createPostProgress", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 创建文章令牌 
	 * @author Administrator
	 * 
	 */	
	public class CreatePostToken extends EventDispatcher
	{
		public function CreatePostToken(title:String, content:String, tags:String, attachments:Array, files:Array)
		{
			super();
			
			_facade = GNFacade.getInstance();
			_title = title;
			_content = content;
			_tags = tags;
			_attachments = attachments;
			_dealAttachCount = 0;
			_files = files;
			if(_attachments != null)
			{
				_attachCount = _attachments.filter(filterCallback).length;
			}
			else
			{
				_attachCount = 0;
			}
		}
		
		private var _facade:GNFacade;
		private var _id:Number;
		private var _title:String;
		private var _content:String;
		private var _tags:String;
		private var _attachCount:int;
		private var _dealAttachCount:int;
		private var _attachments:Array = null;
		private var _files:Array = null;
		private var _token:SqliteDatabaseToken;
		
		/**
		 * 处理创建文章 
		 * 
		 */		
		public function start():void
		{
			var date:Date = new Date();
			
			var params:Dictionary = new Dictionary();
			params[":title"] = _title;
			params[":content"] = _content;
			params[":createTime"] = date;
			params[":modifyTime"] = date;
			params[":tags"] = _tags;
			
			_token = _facade.documentDatabase.createCommandToken("INSERT INTO notes(title, content, createTime, modifyTime, state, tags) VALUES(:title, :content, :createTime, :modifyTime, 1, :tags)", params);
			_token.addEventListener(SqliteDatabaseEvent.RESULT, createPostResultHandler);
			_token.addEventListener(SqliteDatabaseEvent.ERROR, createPostErrorHandler);
			_token.start();
		}
		
		/**
		 * 更新常用标签 
		 * 
		 */		
		private function updateUsedTags():void
		{
			//更新标签库
			if(_tags != null && StringUtil.trim(_tags) != "")
			{
				var tagArray:Array = _tags.split(";");
				for(var i:int = 0; i < tagArray.length; i++)
				{
					//查询是否存在标签
					var params:Dictionary = new Dictionary();
					params[":name"] = tagArray[i];
					
					var token:SqliteDatabaseToken = _facade.documentDatabase.createCommandToken("SELECT * FROM notes_tag WHERE name = :name", params);
					token.userData = tagArray[i];
					token.addEventListener(SqliteDatabaseEvent.RESULT, existsTagResultHandler);
					token.addEventListener(SqliteDatabaseEvent.ERROR, existsTagErrorHandler);
					token.start();
				}
			}
		}
		
		/**
		 * 检测标签是否存在返回 
		 * @param event 事件
		 * 
		 */		
		private function existsTagResultHandler(event:SqliteDatabaseEvent):void
		{
			var token:SqliteDatabaseToken = event.target as SqliteDatabaseToken;
			token.addEventListener(SqliteDatabaseEvent.RESULT, existsTagResultHandler);
			token.addEventListener(SqliteDatabaseEvent.ERROR, existsTagErrorHandler);
			
			var params:Dictionary = null;
			var data:Array = event.recordset;
			if(data != null && data.length > 0)
			{
				//标签已存在
				params = new Dictionary();
				params[":latestTime"] = new Date();
				params[":id"] = data[0].id;
				
				token = _facade.documentDatabase.createCommandToken("UPDATE notes_tag SET useCount = useCount + 1, latestTime = :latestTime WHERE id = :id", params);
				token.start();
			}
			else
			{
				//标签不存在
				params = new Dictionary();
				params[":name"] = token.userData;
				params[":createTime"] = new Date();
				params[":latestTime"] =params[":createTime"];
				params[":pinyin"] = Chinese2Spell.makeSpellCode(token.userData, 0);
				params[":fpinyin"] = Chinese2Spell.makeSpellCode(token.userData, SpellOptions.FirstLetterOnly);
				
				token = _facade.documentDatabase.createCommandToken("INSERT INTO notes_tag(name, createTime, latestTime, useCount, pinyin, fpinyin) VALUES(:name, :createTime, :latestTime, 1, :pinyin, :fpinyin)", params);
				token.start();
			}
		}
		
		/**
		 * 检测标签是否存在失败 
		 * @param event 事件
		 * 
		 */		
		private function existsTagErrorHandler(event:SqliteDatabaseEvent):void
		{
			var token:SqliteDatabaseToken = event.target as SqliteDatabaseToken;
			token.addEventListener(SqliteDatabaseEvent.RESULT, existsTagResultHandler);
			token.addEventListener(SqliteDatabaseEvent.ERROR, existsTagErrorHandler);
		}
		
		/**
		 * 筛选需要添加的附件信息 
		 * @param item 附件信息
		 * @param index 位置索引
		 * @param array 数据对象
		 * @return true表示包含该元素，否则不包含。
		 * 
		 */		
		private function filterCallback(item:*, index:int, array:Array):Boolean
		{
			return !(item as AttachmentInfo).isDelete && (item as AttachmentInfo).status == 0;
		}
		
		/**
		 * 创建文章返回 
		 * @param event 事件
		 * 
		 */		
		private function createPostResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, createPostResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, createPostErrorHandler);
			
			var e:PostEvent;
			_id = _facade.documentDatabase.lastInsertRowID;
			
			if(_attachCount > 0)
			{
				var attachDir:File = Constant.AttachmentPath.resolvePath(_id.toString());
				if(!attachDir.exists)
				{
					attachDir.createDirectory();
				}
				
				for (var i:int = 0; i < _attachments.length; i++)
				{
					var attachInfo:AttachmentInfo = _attachments[i];
					if(!attachInfo.isDelete && attachInfo.status == 0)
					{
						this.saveAttachment(attachInfo, attachDir);
					}
				}
				
				e = new PostEvent(PostEvent.CREATE_POST_PROGRESS);
				e.progressInfo = new ProgressInfo();
				e.progressInfo.progress = 1;
				e.progressInfo.total = _attachCount + 1;
				
				this.dispatchEvent(e);
			}
			else
			{
				this.updateUsedTags();
				this.dealFiles();
				
				var post:Object = new Object();
				post.id = _id;
				post.title = _title;
				post.modifyTime = new Date();
				post.tags = _tags;
				
				//派发完成事件
				e = new PostEvent(PostEvent.CREATE_POST_RESULT);
				e.postInfo = post;
				this.dispatchEvent(e);
			}
		}
		
		/**
		 * 创建文章失败 
		 * @param event 事件
		 * 
		 */		
		private function createPostErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, createPostResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, createPostErrorHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.CREATE_POST_ERROR);
			e.error = event.error;
			this.dispatchEvent(e);
		}
		
		/**
		 * 保存附件信息 
		 * @param attachInfo 附件信息
		 * @param attachDir 保存附件路径
		 * 
		 */		
		private function saveAttachment(attachInfo:AttachmentInfo, attachDir:File):void
		{
			var newFile:File = attachDir.resolvePath(attachInfo.title);
			attachInfo.file.copyToAsync(newFile, true);
			attachInfo.file.addEventListener(Event.COMPLETE, function(event:Event):void
			{
				//写入数据
				var params:Dictionary = new Dictionary();
				params[":url"] = attachInfo.file.nativePath;
				params[":noteId"] = _id;
				params[":createTime"] = new Date();
				
				var token:SqliteDatabaseToken = _facade.documentDatabase.createCommandToken("INSERT INTO notes_attach(url, noteId, createTime) VALUES(:url, :noteId, :createTime)", params);
				token.addEventListener(SqliteDatabaseEvent.RESULT, saveAttachmentResultHandler);
				token.addEventListener(SqliteDatabaseEvent.ERROR, saveAttachmentErrorHandler);
				token.start();
			});
			attachInfo.file.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):void
			{
				var e:PostEvent = new PostEvent(PostEvent.CREATE_POST_ERROR);
				e.error = new Error(event.text, event.errorID);
				this.dispatchEvent(e);
			});
			attachInfo.file = newFile;
			attachInfo.status = 1;
		}
		
		
		/**
		 * 保存附件返回 
		 * @param event 事件
		 * 
		 */		
		private function saveAttachmentResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, saveAttachmentResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, saveAttachmentErrorHandler);
			
			var e:PostEvent;
			_dealAttachCount ++;
			if(_dealAttachCount == _attachCount)
			{
				this.updateUsedTags();
				this.dealFiles();
				
				var post:Object = new Object();
				post.id = _id;
				post.title = _title;
				post.modifyTime = new Date();
				post.tags = _tags;
				
				//处理附件完成
				e = new PostEvent(PostEvent.CREATE_POST_RESULT);
				e.postInfo = post;
				this.dispatchEvent(e);
			}
			else
			{
				//派发进度
				e = new PostEvent(PostEvent.CREATE_POST_PROGRESS);
				e.progressInfo = new ProgressInfo();
				e.progressInfo.progress = 1 + _dealAttachCount;
				e.progressInfo.total = _attachCount + 1;
				this.dispatchEvent(e);
			}
		}
		
		/**
		 * 保存附件失败 
		 * @param event 事件
		 * 
		 */		
		private function saveAttachmentErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, saveAttachmentResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, saveAttachmentErrorHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.CREATE_POST_ERROR);
			e.error = event.error;
			this.dispatchEvent(e);
		}
		
		/**
		 * 处理内容引用文件 
		 * 
		 */		
		private function dealFiles():void
		{
			if (_files != null && _files.length > 0)
			{
				//拷贝文件以及替换内容中引用文件路径
				var filesPath:File = Constant.FilesPath.resolvePath(_id.toString());
				if (!filesPath.exists)
				{
					filesPath.createDirectory();
				}
				
				for (var i:int = 0; i < _files.length; i++)
				{
					var url:String = _files[i].source;
					var format:String = _files[i].format;
					var file:File = _files[i].file;
					
					var newFile:File = filesPath.resolvePath(file.name);
					file.copyTo(newFile, true);
					
					var newUrl:String = format.replace("{0}", newFile.url);
					_content = _content.replace(url, newUrl);
				}
				
				trace(_content);
				
				//更新文件内容
				var params:Dictionary = new Dictionary();
				params[":content"] = _content;
				params[":id"] = _id;
				
				var token:SqliteDatabaseToken = _facade.documentDatabase.createCommandToken("UPDATE notes SET content=:content WHERE id=:id",params);
				token.startSync();
				
			}
		}
	}
}