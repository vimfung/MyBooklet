package cn.vimfung.mybooklet.framework.module.myposts
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.db.SqliteDatabaseToken;
	import cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent;
	import cn.vimfung.mybooklet.framework.model.ProgressInfo;
	import cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent;
	import cn.vimfung.mybooklet.framework.module.myposts.model.AttachmentInfo;
	import cn.vimfung.utils.Chinese2Spell;
	import cn.vimfung.utils.Encode;
	import cn.vimfung.utils.SpellOptions;
	
	import flash.data.SQLResult;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.Dictionary;
	
	import mx.utils.StringUtil;
	
	/**
	 * 获取文章返回 
	 */	
	[Event(name="getPostResult", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 获取文章失败 
	 */	
	[Event(name="getPostError", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 获取文章列表返回 
	 */	
	[Event(name="getPostsResult", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 获取文章列表失败 
	 */	
	[Event(name="getPostsError", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
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
	 * 删除文章返回 
	 */	
	[Event(name="removePostResult", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 删除文章错误 
	 */	
	[Event(name="removePostError", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 获取常用标签列表返回 
	 */	
	[Event(name="getUsedTagsResult", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 获取常用标签列表错误 
	 */	
	[Event(name="getUsedTagsError", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 导出文章返回 
	 */	
	[Event(name="exportResult", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 导出文章错误 
	 */	
	[Event(name="exportError", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 标记颜色返回 
	 */	
	[Event(name="maskColorResult", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 标记颜色错误 
	 */	
	[Event(name="maskColorError", type="cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent")]
	
	/**
	 * 文章令牌 
	 * @author Administrator
	 * 
	 */	
	public class PostToken extends EventDispatcher implements IEventDispatcher
	{
		public function PostToken()
		{
			super();
			
			_facade = GNFacade.getInstance();
		}
		
		private var _facade:GNFacade;
		private var _id:Number;
		private var _keyword:String;
		private var _getPostComplete:Boolean = false;
		private var _getAttachmentComplete:Boolean = false;
		private var _postInfo:Object = null;
		private var _attachments:Array = null;
		private var _postToken:SqliteDatabaseToken;
		private var _attachToken:SqliteDatabaseToken;
		
		private var _title:String;
		private var _content:String;
		private var _tags:String;
		private var _attachCount:int;
		private var _dealAttachCount:int;
		private var _createToken:SqliteDatabaseToken;
		
		private var _addAttachments:Array;
		private var _delAttachments:Array;
		private var _updateToken:SqliteDatabaseToken;
		
		private var _exportFilePath:String;
		private var _exportType:int;
		
		private var _color:uint;
		
		private var _pageNo:int;
		private var _pageSize:int;
		
		private var _tagInfo:Object = null;
		
		private var _dealFunc:Function;
		
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
		 * 创建获取最近文章列表令牌 
		 * @param lastPost 上一页最后一条文章记录，首页传入null
		 * @param pageSize 分页大小
		 * @param keyword 关键字
		 * @param color 过滤颜色
		 * 
		 */		
		public function initGetLatestPostsToken(lastPost:Object = null, pageSize:Number = 10, keyword:String = null, color:uint = 0xffffff):void
		{
			_postInfo = lastPost;
			_pageSize = pageSize;
			_keyword = keyword;
			_color = color;
			
			_dealFunc = dealGetLatestPosts;
		}
		
		/**
		 * 创建获取文章信息令牌 
		 * @param id 文章ID
		 * @param keyword 关键字
		 * 
		 */		
		public function initGetPostInfoToken(id:Number, keyword:String = null):void
		{
			_id = id;
			_keyword = keyword;
			_dealFunc = dealGetPostInfo;
		}
		
		/**
		 * 创建文章令牌
		 * @param title 标题
		 * @param content 内容
		 * @param tags 标签
		 * @param attachments 附件
		 * 
		 */
		public function initCreatePostToken(title:String, content:String, tags:String, attachments:Array):void
		{
			_title = title;
			_content = content;
			_tags = tags;
			_attachments = attachments;
			_dealAttachCount = 0;
			if(_attachments != null)
			{
				_attachCount = _attachments.filter(filterCallback).length;
			}
			else
			{
				_attachCount = 0;
			}
			_dealFunc = dealCreatePost;
		}
		
		/**
		 * 初始化更新文章令牌 
		 * @param postId
		 * @param title
		 * @param content
		 * @param tags
		 * @param attachments
		 * 
		 */		
		public function initUpdatePostToken(postId:Number, title:String, content:String, tags:String, attachments:Array):void
		{
			_id = postId;
			_title = title;
			_content = content;
			_tags = tags;
			_attachments = attachments;
			_dealAttachCount = 0;
			
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
			
			_dealFunc = dealUpdatePost;
		}
		
		/**
		 * 初始化删除文章令牌 
		 * @param post 文章信息
		 * 
		 */		
		public function initRemovePostToken(post:Object):void
		{
			_postInfo = post;
			_dealFunc = dealRemovePost;
		}
		
		/**
		 * 初始化常用标签令牌 
		 * 
		 */		
		public function initGetUsedTagsToken():void
		{
			_dealFunc = dealGetUsedTags;
		}
		
		/**
		 * 初始化获取标签列表令牌 
		 * @param pageNo 页码
		 * 
		 */		
		public function initGetTagsToken(pageNo:Number):void
		{
			_pageNo = pageNo;
			_dealFunc = dealGetTags;
		}
		
		/**
		 * 初始化根据标签获取文章列表令牌 
		 * 
		 * @param	tag			标签
		 * @param	lastPost	最后一条记录
		 * @param	pageSize	分页大小
		 * 
		 */		
		public function initGetPostsWithTagToken(tag:Object, lastPost:Object = null, pageSize:int = 30):void
		{
			_tagInfo = tag;
			_postInfo = lastPost;
			_pageSize = pageSize;
			_dealFunc = dealGetPostsWithTag;
		}
		
		/**
		 * 初始化导出文章令牌 
		 * @param id 文章ID
		 * @param path 导出路径
		 * @param type 导出类型
		 * 
		 */		
		public function initExportPostToken(id:Number, path:String, type:int):void
		{
			_id = id;
			_exportFilePath = path;
			_exportType = type;
			
			_dealFunc = dealExport;
		}
		
		/**
		 * 初始化设置文章标记颜色 
		 * @param id 文章ID
		 * @param color 文章颜色
		 * 
		 */		
		public function initMaskPostColor(id:Number, color:uint):void
		{
			_id = id;
			_color = color;
			
			_dealFunc = dealSetPostColor;
		}
		
		/**
		 * 开始请求 
		 * 
		 */		
		public function start():void
		{
			_dealFunc();
		}
		
		/**
		 * 处理获取最近文章列表信息 
		 * 
		 */		
		private function dealGetLatestPosts():void
		{
			var params:Dictionary = null;
			var conditionString:String = "";
			if(_keyword != null)
			{
				if(params == null)
				{
					params = new Dictionary();
				}
				params[":keyword"] = _keyword;
				conditionString = "AND (title like '%'||:keyword||'%' OR content like '%'||:keyword||'%' OR  ';'||tags||';' like '%;'||:keyword||';%')";
			}
			if(_color != 0xffffff && _color >= 0)
			{
				if(params == null)
				{
					params = new Dictionary();
				}
				params[":color"] = _color;
				conditionString += "AND color = :color";
			}
			if (_postInfo != null)
			{
				if(params == null)
				{
					params = new Dictionary();
				}
				params[":id"] = _postInfo.id;
				conditionString += "AND modifyTime < (SELECT modifyTime FROM notes WHERE id = :id)"
			}

			var token:SqliteDatabaseToken = _facade.documentDatabase.createCommandToken("SELECT id,title,modifyTime,color FROM notes WHERE state = 1 " + conditionString + " ORDER BY modifyTime DESC LIMIT 0," + _pageSize.toString(), params);
			token.addEventListener(SqliteDatabaseEvent.RESULT, getLatestPostsResultHandler);
			token.addEventListener(SqliteDatabaseEvent.ERROR, getLatestPostsErrorHandler);
			token.start();
		}
		
		/**
		 * 处理获取文章信息 
		 * 
		 */		
		private function dealGetPostInfo():void
		{
			var params:Dictionary = new Dictionary();
			params[":postId"] = _id;
			
			_getAttachmentComplete = false;
			_getPostComplete = false;
			_postInfo = null;
			_attachments = null;
			
			_postToken = _facade.documentDatabase.createCommandToken("SELECT id,title,createTime,content,tags,color FROM notes WHERE state = 1 AND id = :postId", params);
			_postToken.addEventListener(SqliteDatabaseEvent.RESULT, getPostInfoResultHandler);
			_postToken.addEventListener(SqliteDatabaseEvent.ERROR, getPostInfoErrorHandler);
			
			_attachToken = _facade.documentDatabase.createCommandToken("SELECT id,url,createTime FROM notes_attach WHERE noteId = :postId ORDER BY createTime DESC", params);
			_attachToken.addEventListener(SqliteDatabaseEvent.RESULT, getAttachmentResultHandler);
			_attachToken.addEventListener(SqliteDatabaseEvent.ERROR, getAttachmentErrorHandler);
			
			_postToken.start();
			_attachToken.start();
		}
		
		/**
		 * 处理创建文章 
		 * 
		 */		
		private function dealCreatePost():void
		{
			var date:Date = new Date();
			
			var params:Dictionary = new Dictionary();
			params[":title"] = _title;
			params[":content"] = _content;
			params[":createTime"] = date;
			params[":modifyTime"] = date;
			params[":tags"] = _tags;
			
			_createToken = _facade.documentDatabase.createCommandToken("INSERT INTO notes(title, content, createTime, modifyTime, state, tags) VALUES(:title, :content, :createTime, :modifyTime, 1, :tags)", params);
			_createToken.addEventListener(SqliteDatabaseEvent.RESULT, createPostResultHandler);
			_createToken.addEventListener(SqliteDatabaseEvent.ERROR, createPostErrorHandler);
			_createToken.start();
		}
		
		/**
		 * 处理更新文章 
		 * 
		 */		
		private function dealUpdatePost():void
		{
			var nowDT:Date = new Date();
			
			var params:Dictionary = new Dictionary();
			params[":title"] = _title;
			params[":content"] = _content;
			params[":tags"] = _tags;
			params[":modifyTime"] = new Date();
			params[":id"] = _id;
			
			_updateToken = _facade.documentDatabase.createCommandToken("UPDATE notes SET title = :title, content = :content, tags = :tags, modifyTime = :modifyTime WHERE id = :id", params);
			_updateToken.addEventListener(SqliteDatabaseEvent.RESULT, updatePostResultHandler);
			_updateToken.addEventListener(SqliteDatabaseEvent.ERROR, updatePostErrorHandler);
			_updateToken.start();
		}
		
		/**
		 * 处理删除文章 
		 * 
		 */		
		private function dealRemovePost():void
		{
			var params:Dictionary = new Dictionary();
			params[":postId"] = _postInfo.id;
			
			var token:SqliteDatabaseToken = _facade.documentDatabase.createCommandToken("UPDATE notes SET state = 0 WHERE id = :postId", params);
			token.addEventListener(SqliteDatabaseEvent.RESULT, removePostResultHandler);
			token.addEventListener(SqliteDatabaseEvent.ERROR, removePostErrorHandler);
			token.start();
		}
		
		/**
		 * 处理获取常用标签 
		 * 
		 */		
		private function dealGetUsedTags():void
		{
			var token:SqliteDatabaseToken = _facade.documentDatabase.createCommandToken("SELECT * FROM notes_tag ORDER BY useCount DESC, latestTime DESC LIMIT 0,10");
			token.addEventListener(SqliteDatabaseEvent.RESULT, getUsedTagsResultHandler);
			token.addEventListener(SqliteDatabaseEvent.ERROR, getUsedTagsErrorHandler);
			token.start();
		}
		
		/**
		 * 处理获取标签列表 
		 * 
		 */		
		private function dealGetTags():void
		{
			var offset:int = (_pageNo - 1) * 30;
			
			var token:SqliteDatabaseToken = _facade.documentDatabase.createCommandToken("SELECT * FROM notes_tag ORDER BY useCount DESC, latestTime DESC LIMIT " + offset + ",30");
			token.addEventListener(SqliteDatabaseEvent.RESULT, getTagsResultHandler);
			token.addEventListener(SqliteDatabaseEvent.ERROR, getTagsErrorHandler);
			token.start();
		}
		
		/**
		 * 处理根据标签获取文章列表 
		 * 
		 */		
		private function dealGetPostsWithTag():void
		{
			var condictionString:String = "";
			var params:Dictionary = new Dictionary();
			params[":keyword"] = _tagInfo.id == 0 ? "" : _tagInfo.name;
			if (_postInfo != null)
			{
				params[":id"] = _postInfo.id;
				condictionString += " AND modifyTime < (SELECT modifyTime FROM notes WHERE id=:id)";
			}
			
			var token:SqliteDatabaseToken = _facade.documentDatabase.createCommandToken("SELECT id,title,modifyTime,color FROM notes WHERE state = 1 AND ';'||tags||';' like '%;'||:keyword||';%'" + condictionString + " ORDER BY modifyTime DESC LIMIT 0," + _pageSize.toString(), params);
			token.addEventListener(SqliteDatabaseEvent.RESULT, getTagPostResultHandler);
			token.addEventListener(SqliteDatabaseEvent.ERROR, getTagPostFaultHandler);
			token.start();
		}
		
		/**
		 * 处理导出 
		 * 
		 */		
		private function dealExport():void
		{
			//获取文件内容
			var params:Dictionary = new Dictionary();
			params[":postId"] = _id;
			
			_postToken = _facade.documentDatabase.createCommandToken("SELECT id,title,createTime,content,tags,color FROM notes WHERE state = 1 AND id = :postId", params);
			_postToken.addEventListener(SqliteDatabaseEvent.RESULT, getExportPostInfoResultHandler);
			_postToken.addEventListener(SqliteDatabaseEvent.ERROR, getExportPostInfoErrorHandler);
			_postToken.start();
		}
		
		/**
		 * 处理设置文章颜色 
		 * 
		 */		
		private function dealSetPostColor():void
		{
			var params:Dictionary = new Dictionary();
			params[":color"] = _color;
			params[":postId"] = _id;
			
			_postToken = _facade.documentDatabase.createCommandToken("UPDATE notes SET color = :color WHERE id = :postId", params);
			_postToken.addEventListener(SqliteDatabaseEvent.RESULT, setPostColorResultHandler);
			_postToken.addEventListener(SqliteDatabaseEvent.ERROR, setPostColorErrorHandler);
			_postToken.start();
		}
		
		/**
		 * 设置文章标记颜色返回 
		 * @param event 事件
		 * 
		 */		
		private function setPostColorResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, setPostColorResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, setPostColorErrorHandler);
				
			var e:PostEvent = new PostEvent(PostEvent.MASK_COLOR_RESULT);
			this.dispatchEvent(e);
		}
		
		/**
		 * 设置文章标记颜色失败 
		 * @param event 事件
		 * 
		 */		
		private function setPostColorErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, setPostColorResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, setPostColorErrorHandler);
				
			var e:PostEvent = new PostEvent(PostEvent.MASK_COLOR_ERROR);
			e.error = event.error;
			this.dispatchEvent(e);
		}
		
		/**
		 * 导出HTML
		 * @param postInfo 文章信息
		 */		
		private function importHTML(postInfo:Object):void
		{
			var contentString:String = "";
			var tagString:String = "";
			
			if(postInfo.tags != null && postInfo.tags != "")
			{
				var tags:Array = postInfo.tags.split(";");
				for (var i:int = 0; i < tags.length; i++)
				{
					if(StringUtil.trim(tags[i]) != "")
					{
						tagString += "<span style='-moz-border-radius:2px;-webkit-border-radius:2px;border-radius:2px;display:block;float:left;padding:3px 5px 3px 5px;font-family:微软雅黑;background-color:#666666;color:white;font-size:11px;margin:0px 2px 10px 2px;' >" + tags[i] + "</span>";
					}
				}
				tagString = "<p>" + tagString + "</p>";
			}
			contentString = "<div style='margin:10px 10px 0px 10px;font-family:微软雅黑;font-size:14px;' >" + postInfo.title + "<div>" + tagString + "</div><hr style='clear:both;border:none;border-bottom:1px dashed #E1E1E1;' /></div><div style='margin:5px 10px 10px 10px;clear:both;font-family:Lantingqianhei;微软雅黑;'>" + postInfo.content + "</div>";
			
			var exportFile:File = new File(_exportFilePath);
			var fs:FileStream = new FileStream();
			fs.open(exportFile, FileMode.UPDATE);
			try
			{
				fs.writeMultiByte(contentString, Encode.UTF_8);
			}
			finally
			{
				fs.close();
			}
			
			var e:PostEvent = new PostEvent(PostEvent.EXPORT_RESULT);
			this.dispatchEvent(e);
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
		 * 获取导出文章信息返回 
		 * @param event 事件
		 * 
		 */		
		private function getExportPostInfoResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getExportPostInfoResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getExportPostInfoErrorHandler);
			
			var e:PostEvent = null;
			
			//导出信息
			switch(_exportType)
			{
				case 0:
					if(event.recordset != null && event.recordset.length > 0)
					{
						this.importHTML(event.recordset[0]);
					}
					else
					{
						e = new PostEvent(PostEvent.EXPORT_ERROR);
						e.error = new Error("导出文章不存在!");
						this.dispatchEvent(e);
					}
					break;
				default:
					e = new PostEvent(PostEvent.EXPORT_ERROR);
					e.error = new Error("无导出类型!");
					this.dispatchEvent(e);
					break;
			}
		}
		
		/**
		 * 获取导出文章信息错误 
		 * @param event 事件
		 * 
		 */		
		private function getExportPostInfoErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getExportPostInfoResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getExportPostInfoErrorHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.EXPORT_ERROR);
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
		 * 是否请求完成 
		 * @return 获取文章信息和附件信息都完成才返回true，否则返回false
		 * 
		 */		
		private function get isRequestComplete():Boolean
		{
			return _getPostComplete && _getAttachmentComplete;
		}
		
		/**
		 * 获取文章信息返回 
		 * @param event 事件
		 * 
		 */		
		private function getPostInfoResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getPostInfoResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getPostInfoErrorHandler);
			
			_getPostComplete = true;
			
			if(event.recordset != null)
			{
				_postInfo = event.recordset[0];
				if(_keyword != null  && StringUtil.trim(_keyword) != "")
				{
					var regexp:RegExp = new RegExp(_keyword,"gi");
					if(_postInfo.title != null)
					{
						_postInfo.title = (_postInfo.title as String).replace(regexp,"<span style='color:#ff0000;background-color:#ffff00;font-weight:bold;'>$&</span>");
					}
					if(_postInfo.content != null)
					{
						_postInfo.content = (_postInfo.content as String).replace(regexp,"<span style='color:#ff0000;background-color:#ffff00;font-weight:bold;'>$&</span>");
					}
					if(_postInfo.tags != null)
					{
						_postInfo.tags = (_postInfo.tags as String).replace(regexp,"<span style='background-color:#ffff00'><b style='color:#ff0000'>$&</b></span>");
					}
				}
			}
			
			if(this.isRequestComplete)
			{
				var e:PostEvent = new PostEvent(PostEvent.GET_POST_RESULT);
				e.postInfo = _postInfo;
				this.dispatchEvent(e);
			}
		}
		
		/**
		 * 获取文章信息失败 
		 * @param event 事件
		 * 
		 */		
		private function getPostInfoErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getPostInfoResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getPostInfoErrorHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.GET_POST_ERROR);
			e.error = event.error;
			this.dispatchEvent(e);
		}
		
		/**
		 * 获取文章附件返回 
		 * @param event 事件
		 * 
		 */		
		private function getAttachmentResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getAttachmentResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getAttachmentErrorHandler);
			
			_getAttachmentComplete = true;
			
			_attachments = event.recordset;
			
			if(this.isRequestComplete)
			{
				var e:PostEvent = new PostEvent(PostEvent.GET_POST_RESULT);
				e.postInfo = _postInfo;
				e.attachments = _attachments;
				this.dispatchEvent(e);
			}
		}
		
		/**
		 * 获取文章附件错误
		 * @param event 事件
		 * 
		 */		
		private function getAttachmentErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getAttachmentResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getAttachmentErrorHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.GET_POST_ERROR);
			e.error = event.error;
			this.dispatchEvent(e);
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
		
		/**
		 * 删除文章返回 
		 * @param event 事件
		 * 
		 */		
		private function removePostResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, removePostResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, removePostErrorHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.REMOVE_POST_RESULT);
			e.postInfo = _postInfo;
			this.dispatchEvent(e);
		}
		
		/**
		 * 删除文章错误 
		 * @param event 事件
		 * 
		 */		
		private function removePostErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, removePostResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, removePostErrorHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.REMOVE_POST_RESULT);
			e.error = event.error;
			this.dispatchEvent(e);
		}
		
		/**
		 * 获取常用标签列表成功 
		 * @param event 事件
		 * 
		 */		
		private function getUsedTagsResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getUsedTagsResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getUsedTagsErrorHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.GET_USED_TAGS_RESULT);
			e.tags = event.recordset;
			this.dispatchEvent(e);
		}
		
		/**
		 * 获取常用标签列表失败 
		 * @param event 事件
		 * 
		 */		
		private function getUsedTagsErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getUsedTagsResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getUsedTagsErrorHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.GET_USED_TAGS_ERROR);
			e.error = event.error;
			this.dispatchEvent(e);
		}
		
		/**
		 * 获取标签列表返回 
		 * @param event 事件
		 * 
		 */		
		private function getTagsResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getTagsResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getTagsErrorHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.GET_TAGS_RESULT);
			e.tags = event.recordset;
			e.pageNo = _pageNo;
			this.dispatchEvent(e);
		}
		
		/**
		 * 获取标签列表失败 
		 * @param event 事件
		 * 
		 */		
		private function getTagsErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getTagsResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getTagsErrorHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.GET_TAGS_ERROR);
			e.error = event.error;
			this.dispatchEvent(e);
		}
		
		/**
		 * 获取标签文章列表返回 
		 * @param event 事件
		 * 
		 */		
		private function getTagPostResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getTagPostResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getTagPostFaultHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.GET_POSTS_RESULT);
			e.posts = event.recordset;
			e.tag = _tagInfo;
			this.dispatchEvent(e);
		}
		
		/**
		 * 获取标签文章列表失败 
		 * @param event 事件
		 * 
		 */		
		private function getTagPostFaultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getTagPostResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getTagPostFaultHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.GET_POSTS_ERROR);
			e.error = event.error;
			this.dispatchEvent(e);
		}
		
		/**
		 * 获取最近列表返回事件 
		 * @param event 事件
		 * 
		 */		
		private function getLatestPostsResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getLatestPostsResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getLatestPostsErrorHandler);
			
			//处理关键字高亮
			if(_keyword != null && StringUtil.trim(_keyword) != "")
			{
				var posts:Array = event.recordset;
				if(posts != null)
				{
					var regexp:RegExp = new RegExp(_keyword,"gi");
					for(var i:int = 0; i < posts.length; i++)
					{
						var post:Object = posts[i];
						if(post.title != null)
						{
							post.originalTitle = post.title;	//保存原标题
							post.title = (post.title as String).replace(regexp,"<span color='#ff0000' backgroundColor='#ffff00'>$&</span>");
						}
					}
				}
			}
			
			var e:PostEvent = new PostEvent(PostEvent.GET_POSTS_RESULT);
			e.posts = event.recordset;
			this.dispatchEvent(e);
		}
		
		/**
		 * 获取最近列表失败事件 
		 * @param event 事件
		 * 
		 */		
		private function getLatestPostsErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getLatestPostsResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getLatestPostsErrorHandler);
			
			var e:PostEvent = new PostEvent(PostEvent.GET_POSTS_ERROR);
			e.error = event.error;
			this.dispatchEvent(e);
		}
	}
}