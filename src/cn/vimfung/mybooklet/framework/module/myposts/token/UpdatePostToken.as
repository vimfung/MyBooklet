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
	 * 更新文章返回 
	 */	
	[Event(name="updatePostResult", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 更新文章失败 
	 */	
	[Event(name="updatePostError", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 更新文章进度 
	 */	
	[Event(name="updatePostProgress", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 更新文章令牌 
	 * @author Administrator
	 * 
	 */	
	public class UpdatePostToken extends EventDispatcher
	{
		public function UpdatePostToken(postId:Number, title:String, content:String, tags:String, attachments:Array, files:Array)
		{
			super();
			
			_facade = GNFacade.getInstance();
			_id = postId;
			_title = title;
			_content = content;
			_tags = tags;
			_attachments = attachments;
			_dealAttachCount = 0;
			_files = files;
			
			if(_attachments != null)
			{
				_addAttachments = _attachments.filter(filterCallback);
				_delAttachments = _attachments.filter(filterDelFileCallback);
			}
			else
			{
				_addAttachments = null;
				_delAttachments = null;
			}
		}
		
		private var _facade:GNFacade;
		private var _id:Number;
		private var _attachments:Array = null;
		private var _files:Array = null;
		private var _addAttachments:Array = null;
		private var _delAttachments:Array = null;
		private var _title:String;
		private var _content:String;
		private var _tags:String;
		
		private var _token:SqliteDatabaseToken;
		private var _attachCount:int;
		private var _dealAttachCount:int;
		
		public function start():void
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
			}

			//写入内容更新到数据库
			var nowDT:Date = new Date();
			
			var params:Dictionary = new Dictionary();
			params[":title"] = _title;
			params[":content"] = _content;
			params[":tags"] = _tags;
			params[":modifyTime"] = new Date();
			params[":id"] = _id;
			
			_token = _facade.documentDatabase.createCommandToken("UPDATE notes SET title = :title, content = :content, tags = :tags, modifyTime = :modifyTime WHERE id = :id", params);
			_token.addEventListener(SqliteDatabaseEvent.RESULT, updatePostResultHandler);
			_token.addEventListener(SqliteDatabaseEvent.ERROR, updatePostErrorHandler);
			_token.start();
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
		 * 筛选待删除附件信息 
		 * @param item 附件信息
		 * @param index 位置索引
		 * @param array 数据对象
		 * @return true表示包含该元素，否则不包含。
		 * 
		 */		
		private function filterDelFileCallback(item:*, index:int, array:Array):Boolean
		{
			return (item as AttachmentInfo).isDelete
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
		 * 更新文章返回 
		 * @param event 事件
		 * 
		 */		
		private function updatePostResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, updatePostResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, updatePostErrorHandler);
			
			if((_addAttachments != null && _addAttachments.length > 0) || (_delAttachments != null && _delAttachments.length > 0))
			{
				_attachCount = _addAttachments.length + _delAttachments.length;
				
				var attachDir:File = Constant.AttachmentPath.resolvePath(_id.toString());
				if(!attachDir.exists)
				{
					attachDir.createDirectory();
				}
				
				var attachInfo:AttachmentInfo = null;
				for (var i:int = 0; i < _addAttachments.length; i++)
				{
					attachInfo = _addAttachments[i];
					this.saveUpdatePostAttachment(attachInfo, attachDir);
				}
				
				for (var j:int = 0; j < _delAttachments.length; j++)
				{
					attachInfo = _delAttachments[j];
					this.removeAttachment(attachInfo);
				} 
			}
			else
			{
				this.updateUsedTags();
				//派发成功事件
				var e:PostEvent = new PostEvent(PostEvent.UPDATE_POST_RESULT);
				this.dispatchEvent(e);
			}
		}
		
		/**
		 * 更新文章失败 
		 * @param event 事件
		 * 
		 */		
		private function updatePostErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, updatePostResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, updatePostErrorHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.UPDATE_POST_ERROR);
			e.error = event.error;
			this.dispatchEvent(e);
		}
		
		/**
		 * 保存更新文章的附件信息 
		 * @param attachInfo 附件信息
		 * @param attachDir 保存附件路径
		 * 
		 */		
		private function saveUpdatePostAttachment(attachInfo:AttachmentInfo, attachDir:File):void
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
				token.addEventListener(SqliteDatabaseEvent.RESULT, saveUpdatePostAttachmentResultHandler);
				token.addEventListener(SqliteDatabaseEvent.ERROR, saveUpdatePostAttachmentErrorHandler);
				token.start();
			});
			attachInfo.file.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):void
			{
				var e:PostEvent = new PostEvent(PostEvent.UPDATE_POST_ERROR);
				e.error = new Error(event.text, event.errorID);
				this.dispatchEvent(e);
			});
			attachInfo.file = newFile;
			attachInfo.status = 1;
		}
		
		/**
		 * 删除附件 
		 * @param attachInfo 附件信息
		 * 
		 */		
		private function removeAttachment(attachInfo:AttachmentInfo):void
		{
			var params:Dictionary = null;
			var token:SqliteDatabaseToken = null;
			
			if(attachInfo.file.exists)
			{
				try
				{
					attachInfo.file.deleteFileAsync();
					attachInfo.file.addEventListener(Event.COMPLETE, function (event:Event):void
					{
						params = new Dictionary();
						params[":id"] = attachInfo.id;
						
						token = _facade.documentDatabase.createCommandToken("DELETE FROM notes_attach WHERE id = :id", params);
						token.addEventListener(SqliteDatabaseEvent.RESULT, removeAttachmentResultHandler);
						token.addEventListener(SqliteDatabaseEvent.ERROR, removeAttachmentErrorHandler);
						token.start();
					});
					attachInfo.file.addEventListener(IOErrorEvent.IO_ERROR, function (event:IOErrorEvent):void
					{
						var e:PostEvent = new PostEvent(PostEvent.UPDATE_POST_ERROR);
						e.error = new Error(event.text, event.errorID);
						this.dispatchEvent(e);
					});
					
				}
				catch(err:SecurityError)
				{
					var e:PostEvent = new PostEvent(PostEvent.UPDATE_POST_ERROR);
					e.error = err;
					this.dispatchEvent(e);
				}
			}
			else
			{
				params = new Dictionary();
				params[":id"] = attachInfo.id;
				
				token = _facade.documentDatabase.createCommandToken("DELETE FROM notes_attach WHERE id = :id", params);
				token.addEventListener(SqliteDatabaseEvent.RESULT, removeAttachmentResultHandler);
				token.addEventListener(SqliteDatabaseEvent.ERROR, removeAttachmentErrorHandler);
				token.start();
			}
		}
		
		/**
		 * 保存更新文章附件返回 
		 * @param event 事件
		 * 
		 */		
		private function saveUpdatePostAttachmentResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, saveUpdatePostAttachmentResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, saveUpdatePostAttachmentErrorHandler);
			
			var e:PostEvent;
			_dealAttachCount ++;
			
			if(_dealAttachCount == _attachCount)
			{
				this.updateUsedTags();
				//处理附件完成
				e = new PostEvent(PostEvent.UPDATE_POST_RESULT);
				this.dispatchEvent(e);
			}
			else
			{
				//派发进度
				e = new PostEvent(PostEvent.UPDATE_POST_PROGRESS);
				e.progressInfo = new ProgressInfo();
				e.progressInfo.progress = 1 + _dealAttachCount;
				e.progressInfo.total = _attachCount + 1;
				this.dispatchEvent(e);
			}
		}
		
		/**
		 * 保存更新文件附件失败 
		 * @param event 事件
		 * 
		 */		
		private function saveUpdatePostAttachmentErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, saveUpdatePostAttachmentResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, saveUpdatePostAttachmentErrorHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.UPDATE_POST_ERROR);
			e.error = event.error;
			this.dispatchEvent(e);
		}
		
		/**
		 * 删除附件返回 
		 * @param event 事件
		 * 
		 */		
		private function removeAttachmentResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, removeAttachmentResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, removeAttachmentErrorHandler);
			
			var e:PostEvent;
			_dealAttachCount ++;
			
			if(_dealAttachCount == _attachCount)
			{
				this.updateUsedTags();
				//处理附件完成
				e = new PostEvent(PostEvent.UPDATE_POST_RESULT);
				this.dispatchEvent(e);
			}
			else
			{
				//派发进度
				e = new PostEvent(PostEvent.UPDATE_POST_PROGRESS);
				e.progressInfo = new ProgressInfo();
				e.progressInfo.progress = 1 + _dealAttachCount;
				e.progressInfo.total = _attachCount + 1;
				this.dispatchEvent(e);
			}
		}
		
		/**
		 * 删除附件错误
		 * @param event 事件
		 * 
		 */		
		private function removeAttachmentErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, removeAttachmentResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, removeAttachmentErrorHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.UPDATE_POST_ERROR);
			e.error = event.error;
			this.dispatchEvent(e);
		}
	}
}